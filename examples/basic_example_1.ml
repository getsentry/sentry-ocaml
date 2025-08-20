open Lwt.Syntax

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in

  match client_result with
  | Ok _client -> (
      (* Set user information *)
      let* () =
        Sentry.set_user
          {
            id = Some "user123";
            username = Some "john_doe";
            email = Some "john@example.com";
            ip_address = None;
          }
      in

      (* Capture an exception *)
      try raise (Failure "Something went wrong!")
      with exn -> (
        let* result = Sentry.capture_exception exn in
        match result with
        | Ok () -> Lwt.return_unit
        | Error _msg -> Lwt.return_unit))
  | Error _err -> Lwt.return_unit
;;

let () = Lwt_main.run (main ())
