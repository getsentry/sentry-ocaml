open Lwt.Syntax

(** Demo example *)

let open_door () : unit Lwt.t =
  try
    if true then
      failwith "uh oh i forgot my keycard. stuck in the stairwell"
    else
      Printf.printf "This should never print\n";
    Lwt.return_unit
  with exn -> (
    let* capture_result = Sentry.capture_exception exn in
    match capture_result with
    | Ok _ -> Lwt.return_unit
    | Error msg ->
        Printf.printf "Failed to capture exception: %s\n" msg;
        Lwt.return_unit)
;;

let run_upstairs () = open_door ()

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in

  match client_result with
  | Ok _client -> (
      (* Set user information *)
      let* () =
        Sentry.set_user
          {
            id = Some "user456";
            username = Some "jane_smith";
            email = Some "jane@example.com";
            ip_address = Some "192.168.1.100";
          }
      in

      (* Set some tags for categorizing events *)
      let* () = Sentry.set_tag "component" "api_gateway" in
      let* () = Sentry.set_tag "service" "user_service" in

      (* Set some extra data for additional context *)
      let* () = Sentry.set_extra "deployment" "us-east-1" in
      let* () = Sentry.set_extra "version" "2.1.0" in

      (* Set environment and release *)
      let* () = Sentry.set_environment "development" in
      let* () = Sentry.set_release "v1.0.0" in

      (* Set request context for the API operation we're about to perform *)
      let* () =
        Sentry.set_request_context
          ~headers:[ ("content-type", "application/json"); ("authorization", "Bearer token123") ]
          ~query_string:"?validate=true&notify=email&page=1"
          ~data:[ ("username", "jane_smith"); ("email", "jane@example.com"); ("role", "user") ]
          ~cookies:"session_id=abc123; csrf_token=xyz789; theme=dark"
          ~env:
            [
              ("REMOTE_ADDR", "192.168.1.100");
              ("HTTP_HOST", "api.example.com");
              ("SERVER_PORT", "443");
            ]
          ~body_size:2048 ~user_agent:"MyApp/1.0" "POST" "/api/users"
      in

      let* _ = Sentry.capture_message "lunch is almost over! running upstairs now" in
      let* () = run_upstairs () in
      Lwt.return_unit)
  | Error msg ->
      Printf.printf "Sentry client initialization failed: %s\n" msg;
      Lwt.return_unit
;;

let () = Lwt_main.run (main ())
