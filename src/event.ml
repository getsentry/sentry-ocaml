module Event = struct
  type t = {
    event_id : string;
    timestamp : float;
    level : string;
    message : string option;
    exception_ : exn option;
    platform : string;
    sdk : string;
  }

  (* Create a new event *)
  let create ?message ?exception_ level =
    {
      event_id = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string;
      timestamp = Unix.time ();
      level;
      message;
      exception_;
      platform = "ocaml";
      sdk = "sentry-ocaml";
    }

  (* Serialize event to JSON *)
  let to_json event =
    let fields = [
      ("event_id", `String event.event_id);
      ("timestamp", `Float event.timestamp);
      ("level", `String event.level);
      ("platform", `String event.platform);
      ("sdk", `Assoc [("name", `String event.sdk); ("version", `String "0.1.0")]);
    ] in
    
    let fields = match event.message with
      | Some msg -> ("message", `String msg) :: fields
      | None -> fields
    in
    
    let fields = match event.exception_ with
      | Some exn -> 
          let exn_str = Printexc.to_string exn in
          ("exception", `Assoc [
            ("values", `List [
              `Assoc [
                ("type", `String (Printexc.exn_slot_name exn));
                ("value", `String exn_str);
              ]
            ])
          ]) :: fields
      | None -> fields
    in
    
    `Assoc fields
end
