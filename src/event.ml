module Event = struct
  module Context = Context.Context
  module Performance = Performance.Performance

  type stack_frame = {
    filename : string option;
    function_name : string option;
    line_number : int option;
    column_number : int option;
  }

  type t = {
    event_id : string;
    timestamp : string;
    level : string;
    message : string option;
    exception_ : exn option;
    stack_trace : stack_frame list option;
    platform : string;
    sdk : string;
    context : Context.t option;
    transaction : Performance.transaction option;
  }

  (** Parse a single stack frame line *)
  let parse_stack_frame line =
    (* OCaml backtrace format: "Raised at function_name in file \"filename.ml\", line line_num, characters start-end" *)
    let re =
      Str.regexp
        "Raised at \\([^ ]*\\) in file \"\\([^\"]*\\)\", line \\([0-9]*\\), characters \
         \\([0-9]*\\)-\\([0-9]*\\)"
    in
    if Str.string_match re line 0 then
      let func_name = Str.matched_group 1 line in
      let filename = Str.matched_group 2 line in
      let line_num = int_of_string (Str.matched_group 3 line) in
      let start_char = int_of_string (Str.matched_group 4 line) in
      Some
        {
          filename = Some filename;
          function_name = Some func_name;
          line_number = Some line_num;
          column_number = Some start_char;
        }
    else
      (* Alternative format: "Called from function_name in file \"filename.ml\", line line_num, characters start-end" *)
      let re2 =
        Str.regexp
          "Called from \\([^ ]*\\) in file \"\\([^\"]*\\)\", line \\([0-9]*\\), characters \
           \\([0-9]*\\)-\\([0-9]*\\)"
      in
      if Str.string_match re2 line 0 then
        let func_name = Str.matched_group 1 line in
        let filename = Str.matched_group 2 line in
        let line_num = int_of_string (Str.matched_group 3 line) in
        let start_char = int_of_string (Str.matched_group 4 line) in
        Some
          {
            filename = Some filename;
            function_name = Some func_name;
            line_number = Some line_num;
            column_number = Some start_char;
          }
      else
        (* Fallback: try to extract any file and line information we can find *)
        let re3 = Str.regexp "file \"\\([^\"]*\\)\", line \\([0-9]*\\)" in
        if Str.string_match re3 line 0 then
          let filename = Str.matched_group 1 line in
          let line_num = int_of_string (Str.matched_group 2 line) in
          (* Try to extract function name if present *)
          let func_re = Str.regexp "\\([A-Za-z_][A-Za-z0-9_.]*\\)" in
          let func_name =
            if Str.string_match func_re line 0 then
              Some (Str.matched_group 1 line)
            else
              None
          in
          Some
            {
              filename = Some filename;
              function_name = func_name;
              line_number = Some line_num;
              column_number = None;
            }
        else
          None
  ;;

  (** Parse OCaml backtrace into stack frames *)
  let parse_backtrace backtrace =
    let lines = String.split_on_char '\n' backtrace in
    let rec parse_lines acc = function
      | [] -> List.rev acc
      | line :: rest -> (
          match parse_stack_frame line with
          | Some frame -> parse_lines (frame :: acc) rest
          | None -> parse_lines acc rest)
    in
    parse_lines [] lines
  ;;

  (* Create a new event *)
  let create ?message ?exception_ ?context ?transaction level =
    (* Extract stack trace if exception is provided *)
    let stack_trace =
      if Option.is_some exception_ then
        try
          let backtrace = Printexc.get_backtrace () in
          if backtrace <> "" then
            Some (parse_backtrace backtrace)
          else
            None
        with _ -> None
      else
        None
    in

    {
      event_id = Utils.generate_uuid ();
      timestamp = Utils.current_timestamp_iso8601 ();
      level;
      message;
      exception_;
      stack_trace;
      platform = "ocaml";
      sdk = "sentry-ocaml";
      context;
      transaction;
    }
  ;;

  (* Serialize event to JSON *)
  let to_json event =
    let fields =
      [
        ("event_id", `String event.event_id);
        ("level", `String event.level);
        ("platform", `String event.platform);
        ("sdk", `Assoc [ ("name", `String event.sdk); ("version", `String "0.1.0") ]);
      ]
    in

    (* Only add timestamp if no transaction is present *)
    let fields =
      match event.transaction with
      | None -> ("timestamp", `String event.timestamp) :: fields
      | Some _ -> fields
    in

    let fields =
      match event.message with
      | Some msg -> ("message", `String msg) :: fields
      | None -> fields
    in

    let fields =
      match event.exception_ with
      | Some exn ->
          let exn_str = Printexc.to_string exn in
          let exception_data =
            [ ("type", `String (Printexc.exn_slot_name exn)); ("value", `String exn_str) ]
          in

          (* Add stack trace if available *)
          let exception_data =
            match event.stack_trace with
            | Some frames ->
                let frame_json =
                  List.map
                    (fun frame ->
                      let frame_fields = [] in
                      let frame_fields =
                        match frame.filename with
                        | Some f -> ("filename", `String f) :: frame_fields
                        | None -> frame_fields
                      in
                      let frame_fields =
                        match frame.function_name with
                        | Some f -> ("function", `String f) :: frame_fields
                        | None -> frame_fields
                      in
                      let frame_fields =
                        match frame.line_number with
                        | Some l -> ("lineno", `Int l) :: frame_fields
                        | None -> frame_fields
                      in
                      let frame_fields =
                        match frame.column_number with
                        | Some c -> ("colno", `Int c) :: frame_fields
                        | None -> frame_fields
                      in
                      `Assoc frame_fields)
                    frames
                in
                ("stacktrace", `Assoc [ ("frames", `List frame_json) ]) :: exception_data
            | None -> exception_data
          in

          ("exception", `Assoc [ ("values", `List [ `Assoc exception_data ]) ]) :: fields
      | None -> fields
    in

    (* Add context data if available *)
    let fields =
      match event.context with
      | Some context ->
          let context_fields = Context.to_json context in
          context_fields @ fields
      | None -> fields
    in

    (* Add transaction data if available *)
    let fields =
      match event.transaction with
      | Some transaction ->
          let transaction_fields = Performance.to_json_transaction transaction in
          transaction_fields @ fields
      | None -> fields
    in

    `Assoc fields
  ;;
end
