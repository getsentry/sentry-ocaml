open Lwt.Syntax

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in

  match client_result with
  | Ok _client -> (
      (* Simulate an error *)
      let* result = Sentry.capture_exception (Invalid_argument "Invalid input provided") in

      match result with
      | Ok () -> Lwt.return_unit
      | Error _msg -> Lwt.return_unit)
  | Error _err -> Lwt.return_unit
;;

let () = Lwt_main.run (main ())
