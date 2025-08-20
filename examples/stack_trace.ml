open Lwt.Syntax

let level4_func () : unit Lwt.t =
  try
    if true then
      failwith "This exception should show multiple stack frames"
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

let level3_func () = level4_func ()
let level2_func () = level3_func ()
let level1_func () = level2_func ()

let main () =
  Printexc.record_backtrace true;

  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in

  match client_result with
  | Ok _ ->
      let* () = level1_func () in
      Lwt.return_unit
  | Error msg ->
      Printf.printf "Sentry client initialization failed: %s\n" msg;
      Lwt.return_unit
;;

let () = Lwt_main.run (main ())
