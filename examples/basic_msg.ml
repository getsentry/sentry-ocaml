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

      (* Set some tags for categorizing events *)
      let* () = Sentry.set_tag "component" "user_management" in
      let* () = Sentry.set_tag "feature" "file_upload" in

      (* Set some extra data for additional context *)
      let* () = Sentry.set_extra "session_duration" "45m" in
      let* () = Sentry.set_extra "file_size" "2.3MB" in

      (* Set environment and release *)
      let* () = Sentry.set_environment "development" in
      let* () = Sentry.set_release "v1.0.0" in

      (* Capture a message *)
      let* result = Sentry.capture_message "This is a test message" in
      match result with
      | Ok () -> Lwt.return_unit
      | Error _msg -> Lwt.return_unit)
  | Error msg ->
      Printf.printf "Sentry client initialization failed: %s\n" msg;
      Lwt.return_unit
;;

let () = Lwt_main.run (main ())
