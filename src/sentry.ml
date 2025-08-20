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
  match Utils.parse_dsn dsn with
  | Some dsn_info ->
      let context = Context.default in
      let transport = Transport.create dsn_info in
      let client = { context; transport } in
      global_client := Some client;
      Lwt.return (Ok client)
  | None ->
      Lwt.return (Error "Invalid DSN format")

(** Capture an exception using the global client *)
let capture_exception exn =
  match !global_client with
  | Some client ->
      let event = Event.create ~exception_:exn "error" in
      Transport.send_event client.transport event
  | None ->
      Lwt.return (Error "Call init to initialize the Sentry client first")

(** Capture a message using the global client *)
let capture_message message =
  match !global_client with
  | Some client ->
      let event = Event.create ~message "error" in
      Transport.send_event client.transport event
  | None ->
      Lwt.return (Error "Call init to initialize the Sentry client first")

(** Global client context management *)
let set_user user =
  match !global_client with
  | Some client ->
      let context = Context.set_user client.context user in
      let updated_client = { client with context } in
      global_client := Some updated_client;
      Lwt.return_unit
  | None ->
      Lwt.return_unit
