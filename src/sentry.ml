(** Sentry OCaml SDK - Main library interface *)

module Context = Context.Context
module Transport = Transport.Transport
module Event = Event.Event
module Request = Request.Request
module Performance = Performance.Performance

type client = {
  context : Context.t;
  transport : Transport.t;
}

let global_client = ref None

(** Initialization of global client *)
let init dsn =
  (* Enable OCaml backtraces for stack trace capture *)
  Printexc.record_backtrace true;

  match Utils.parse_dsn dsn with
  | Some dsn_info ->
      let context = Context.default in
      let transport = Transport.create dsn_info in
      let client = { context; transport } in
      global_client := Some client;
      Lwt.return (Ok client)
  | None -> Lwt.return (Error "Invalid DSN format")
;;

(** Capture an exception using the global client *)
let capture_exception ?level exn =
  let level = Option.value level ~default:"error" in
  match !global_client with
  | Some client ->
      let event = Event.create ~exception_:exn ~context:client.context level in
      Transport.send_event client.transport event "event"
  | None -> Lwt.return (Error "Call init to initialize the Sentry client first")
;;

(** Capture a message using the global client *)
let capture_message ?level message =
  let level = Option.value level ~default:"info" in
  match !global_client with
  | Some client ->
      let event = Event.create ~message ~context:client.context level in
      Transport.send_event client.transport event "event"
  | None -> Lwt.return (Error "Call init to initialize the Sentry client first")
;;

(** Performance monitoring *)

(** Start a new child span within a transaction *)
let start_child (transaction : Performance.transaction) ~name ~operation =
  Performance.create_span ~parent_id:transaction.id ~name ~operation
;;

(** Finish a span *)
let finish_span span = Performance.finish_span span

(** Start a new transaction *)
let start_transaction ~name ~operation = Performance.create_transaction ~name ~operation

(** Send a finished transaction to Sentry *)
let send_transaction (transaction : Performance.transaction) =
  match !global_client with
  | Some client ->
      let event = Event.create ~context:client.context ~transaction "info" in
      Transport.send_event client.transport event "transaction"
  | None -> Lwt.return (Error "Call init to initialize the Sentry client first")
;;

(** Finish a transaction and send it to Sentry *)
let finish_transaction (txn : Performance.transaction) =
  let open Lwt.Syntax in
  let finished_txn = Performance.finish_transaction txn in
  let* _ = send_transaction finished_txn in
  Lwt.return finished_txn
;;

(** Context management *)

let set_user user =
  match !global_client with
  | Some client ->
      let context = Context.set_user client.context user in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

let set_tag key value =
  match !global_client with
  | Some client ->
      let context = Context.set_tag client.context key value in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

let set_extra key value =
  match !global_client with
  | Some client ->
      let context = Context.set_extra client.context key value in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

let set_environment env =
  match !global_client with
  | Some client ->
      let context = Context.set_environment client.context env in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

let set_release release =
  match !global_client with
  | Some client ->
      let context = Context.set_release client.context release in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

let set_request_context
    ?headers
    ?query_string
    ?data
    ?cookies
    ?env
    ?body_size
    ?user_agent
    method_
    url =
  let request =
    Request.create method_ url
      (Option.value ~default:[] headers)
      query_string data cookies env body_size user_agent
  in
  match !global_client with
  | Some client ->
      let context = Context.set_request client.context request in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;
