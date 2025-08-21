type dsn_info = {
  full_dsn : string;
  base_uri : string;
  public_key : string;
  project_id : string;
}

(* Parse Sentry DSN according to format: '{PROTOCOL}://{PUBLIC_KEY}@{HOST}{PATH}/{PROJECT_ID}' *)
let parse_dsn dsn =
  try
    (* Split on "://" to separate protocol from the rest *)
    let parts = Str.split (Str.regexp_string "://") dsn in
    if List.length parts = 2 then
      let protocol = List.hd parts in
      let rest = List.hd (List.tl parts) in

      (* Split on '@' to separate public key from the rest *)
      let parts = String.split_on_char '@' rest in
      if List.length parts = 2 then
        let public_key = List.hd parts in
        let host_path_project = List.hd (List.tl parts) in

        (* Split on '/' to get the host, path, and project id *)
        let path_parts = String.split_on_char '/' host_path_project in
        let project_id = List.hd (List.rev path_parts) in
        let host_path = List.rev (List.tl (List.rev path_parts)) in
        let endpoint = String.concat "/" host_path in

        Some { full_dsn = dsn; base_uri = protocol ^ "://" ^ endpoint; public_key; project_id }
      else
        None
    else
      None
  with _ -> None
;;

(* Get the current timestamp as a string in ISO 8601 format *)
let current_timestamp_iso8601 () =
  let current_time_float = Unix.time () in
  let tm = Unix.gmtime current_time_float in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ" (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1)
    tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec
;;

(* Generate a UUID v4 *)
let generate_uuid () = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string
