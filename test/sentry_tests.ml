(** Tests for the Sentry OCaml SDK *)

open Alcotest

let test_suite = [
  "Sentry", [
    test_case "placeholder test" `Quick (fun () ->
      check bool "true is true" true true
    );
  ];
]

let () = run "Sentry Tests" test_suite
