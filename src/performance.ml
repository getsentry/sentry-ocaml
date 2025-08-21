module Performance = struct
  type span = {
    id : string;
    parent_id : string;
    name : string;
    operation : string;
    start_time : string;
    end_time : string option;
  }

  type transaction = {
    id : string;
    name : string;
    operation : string;
    start_time : string;
    end_time : string option;
    spans : span list;
  }

  (* Global registry to track active transactions *)
  let active_transactions = ref []

  (** Create a new span *)
  let create_span ~parent_id ~name ~operation =
    {
      id = Utils.generate_uuid ();
      parent_id;
      name;
      operation;
      start_time = Utils.current_timestamp_iso8601 ();
      end_time = None;
    }
  ;;

  (** Finish a span: set its end time and add it to parent transaction *)
  let finish_span (span : span) =
    let finished_span = { span with end_time = Some (Utils.current_timestamp_iso8601 ()) } in
    active_transactions :=
      List.map
        (fun (txn : transaction) ->
          if txn.id = span.parent_id then
            { txn with spans = txn.spans @ [ finished_span ] }
          else
            txn)
        !active_transactions;
    finished_span
  ;;

  (** Create a new transaction *)
  let create_transaction ~name ~operation =
    let transaction =
      {
        id = Utils.generate_uuid ();
        name;
        operation;
        start_time = Utils.current_timestamp_iso8601 ();
        end_time = None;
        spans = [];
      }
    in
    active_transactions := transaction :: !active_transactions;
    transaction
  ;;

  (** Finish a transaction: set its end time and update the registry *)
  let finish_transaction transaction =
    let finished_transaction =
      { transaction with end_time = Some (Utils.current_timestamp_iso8601 ()) }
    in
    active_transactions :=
      List.map
        (fun txn ->
          if txn.id = transaction.id then
            finished_transaction
          else
            txn)
        !active_transactions;
    finished_transaction
  ;;

  let to_json_transaction txn =
    (* Debug output *)
    Printf.printf "DEBUG: Transaction data:\n";
    Printf.printf "  id: %s\n" txn.id;
    Printf.printf "  name: %s\n" txn.name;
    Printf.printf "  operation: %s\n" txn.operation;
    Printf.printf "  start_time: %s\n" txn.start_time;
    Printf.printf "  end_time: %s\n"
      (match txn.end_time with
      | Some t -> t
      | None -> "None");
    Printf.printf "  spans count: %d\n" (List.length txn.spans);

    let fields = [] in

    let fields = ("transaction_id", `String txn.id) :: fields in
    let fields = ("transaction", `String txn.name) :: fields in
    let fields = ("op", `String txn.operation) :: fields in
    let fields = ("start_timestamp", `String txn.start_time) :: fields in
    let fields =
      match txn.end_time with
      | Some end_time -> ("timestamp", `String end_time) :: fields
      | None -> fields
    in
    let fields = ("trace_id", `String txn.id) :: fields in

    let spans_json =
      List.map
        (fun (s : span) ->
          let span_fields = [] in
          let span_fields = ("span_id", `String s.id) :: span_fields in
          let span_fields = ("op", `String s.operation) :: span_fields in
          let span_fields = ("description", `String s.name) :: span_fields in
          let span_fields = ("start_timestamp", `String s.start_time) :: span_fields in
          let span_fields =
            match s.end_time with
            | Some end_time -> ("timestamp", `String end_time) :: span_fields
            | None -> span_fields
          in
          let span_fields = ("parent_span_id", `String s.parent_id) :: span_fields in
          `Assoc span_fields)
        txn.spans
    in
    let fields = ("spans", `List spans_json) :: fields in

    fields
  ;;
end
