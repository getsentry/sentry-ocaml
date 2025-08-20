(** Sentry OCaml SDK - Main library interface *)

module Context = Context.Context
module Transport = Transport.Transport
module Event = Event.Event

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
let capture_exception exn =
  match !global_client with
  | Some client ->
      let event = Event.create ~exception_:exn ~context:client.context "error" in
      Transport.send_event client.transport event
  | None -> Lwt.return (Error "Call init to initialize the Sentry client first")
;;

(** Capture a message using the global client *)
let capture_message message =
  match !global_client with
  | Some client ->
      let event = Event.create ~message ~context:client.context "error" in
      Transport.send_event client.transport event
  | None -> Lwt.return (Error "Call init to initialize the Sentry client first")
;;

(** Global client context management *)
let set_user user =
  match !global_client with
  | Some client ->
      let context = Context.set_user client.context user in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

(** Set a tag for the global client *)
let set_tag key value =
  match !global_client with
  | Some client ->
      let context = Context.set_tag client.context key value in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

(** Set extra data for the global client *)
let set_extra key value =
  match !global_client with
  | Some client ->
      let context = Context.set_extra client.context key value in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

(** Set environment for the global client *)
let set_environment env =
  match !global_client with
  | Some client ->
      let context = Context.set_environment client.context env in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;

(** Set release version for the global client *)
let set_release release =
  match !global_client with
  | Some client ->
      let context = Context.set_release client.context release in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None -> Lwt.return_unit
;;
