open Lwt.Syntax

(* Simulate some long processes *)
let validate_shopping_cart () = Unix.sleepf 0.25
let process_shopping_cart () = Unix.sleepf 0.5

(* This method is called when a user clicks on the checkout button *)
let perform_checkout () =
  let transaction = Sentry.start_transaction ~name:"checkout" ~operation:"perform-checkout" in

  (* Validate the cart *)
  let validation_span =
    Sentry.start_child transaction ~name:"validation" ~operation:"validating shopping cart"
  in
  validate_shopping_cart ();
  let _ = Sentry.finish_span validation_span in

  (* Process the order *)
  let process_span =
    Sentry.start_child transaction ~name:"process" ~operation:"processing shopping cart"
  in
  process_shopping_cart ();
  let _ = Sentry.finish_span process_span in

  let _ = Sentry.finish_transaction transaction in

  Lwt.return_unit
;;

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in

  match client_result with
  | Ok _client ->
      let* () = perform_checkout () in
      Lwt.return_unit
  | Error msg ->
      Printf.printf "Sentry client initialization failed: %s\n" msg;
      Lwt.return_unit
;;

let () = Lwt_main.run (main ())
