open Utils
open Event

module Transport = struct
  type t = {
    endpoint : string;
    dsn_info : dsn_info;
  }

  (* Create a new transport instance *)
  let create dsn_info =
    let endpoint = Printf.sprintf "%s/api/%s/envelope/" 
      dsn_info.base_uri dsn_info.project_id in
    { endpoint; dsn_info }

  (* Build Sentry authentication header *)
  let build_auth_header dsn_info =
    let auth_header_fields = [
      ("sentry_version", "7");
      ("sentry_client", "sentry-ocaml/0.1.0");
      ("sentry_key", dsn_info.public_key);
    ] in
    "Sentry " ^ String.concat ", " (List.map (fun (k, v) -> k ^ "=" ^ v) auth_header_fields)

  (* Build envelope header *)
  let build_envelope_header (event : Event.t) =
    let sent_at = current_timestamp_iso8601 () in
    let header_fields = [
      ("event_id", `String event.event_id);
      ("sent_at", `String sent_at);
    ] in
    `Assoc header_fields

  (* Build item header for the envelope *)
  let build_item_header payload_length =
    `Assoc [
      ("type", `String "event");
      ("length", `Int payload_length);
    ]

  (* Create Sentry envelope *)
  let create_envelope (event : Event.t) =
    let event_json = Event.to_json event in
    let header = build_envelope_header event in
    let item_header = build_item_header (String.length (Yojson.Basic.to_string event_json)) in
    
    let header_str = Yojson.Basic.to_string header in
    let item_header_str = Yojson.Basic.to_string item_header in
    let event_str = Yojson.Basic.to_string event_json in
    
    let envelope = Printf.sprintf "%s\n%s\n%s" header_str item_header_str event_str in
    envelope

  (* Build HTTP headers for the request *)
  let build_http_headers auth_header =
    Cohttp.Header.of_list [
      ("Content-Type", "application/x-sentry-envelope");
      ("X-Sentry-Auth", auth_header);
      ("User-Agent", "sentry-ocaml/0.1.0");
    ]

  (* Handle HTTP response *)
  let handle_response response response_body_string =
    match Cohttp.Code.code_of_status (Cohttp.Response.status response) with
    | 200 | 201 | 202 -> Ok ()
    | 429 -> Error "Rate limited by Sentry"
    | 413 -> Error "Event too large"
    | 400 -> Error ("Bad request: " ^ response_body_string)
    | 403 -> Error "Authentication failed"
    | _ -> 
        let status = Cohttp.Code.string_of_status (Cohttp.Response.status response) in
        Error (Printf.sprintf "HTTP %s: %s" status response_body_string)

  (* Send event to Sentry *)
  let send_event transport (event : Event.t) =
    let open Lwt.Syntax in
    
    let auth_header = build_auth_header transport.dsn_info in
    let envelope = create_envelope event in
    
    let headers = build_http_headers auth_header in
    
    (* Debug prints to show the entire request structure *)
    Printf.printf "=== SENTRY REQUEST DEBUG ===\n";
    Printf.printf "Endpoint: %s\n" transport.endpoint;
    Printf.printf "Auth Header: %s\n" auth_header;
    Printf.printf "Headers:\n";
    Cohttp.Header.iter (fun k v -> Printf.printf "  %s: %s\n" k v) headers;
    Printf.printf "Envelope:\n%s\n" envelope;
    Printf.printf "===========================\n\n";
    
    let body = Cohttp_lwt.Body.of_string envelope in
    let uri = Uri.of_string transport.endpoint in
    
    let* response, response_body = Cohttp_lwt_unix.Client.post ~headers ~body uri in
    let* response_body_string = Cohttp_lwt.Body.to_string response_body in
    
    (* Debug prints to show the response from Sentry *)
    Printf.printf "=== SENTRY RESPONSE DEBUG ===\n";
    Printf.printf "Response: %s\n" response_body_string;
    Printf.printf "===========================\n\n";

    Lwt.return (handle_response response response_body_string)
end
