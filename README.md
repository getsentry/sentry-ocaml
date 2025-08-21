# (Experimental) Sentry SDK for OCaml 🚀

[![CI](https://github.com/getsentry/sentry-ocaml/workflows/CI/badge.svg)](https://github.com/getsentry/sentry-ocaml/actions/workflows/ci.yml)
[![OCaml](https://img.shields.io/badge/OCaml-4.14%2B-blue.svg)](https://ocaml.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A native OCaml SDK for Sentry error monitoring and performance tracking. Built with modern OCaml features and Lwt for asynchronous operations.

⚠️ This SDK was created as a Sentry Hack Week (hackathon) project and is currently experimental / not production-ready.

## ✨ Features

- 🚨 **Exception Capture**: Automatically capture and report exceptions with full stack traces
- 💬 **Message Capture**: Send custom messages and log entries to Sentry
- 📊 **Performance Monitoring (WIP)**: Track transactions and spans for performance insights
- 👤 **User Context**: Associate events with user information
- 🏷️ **Tags & Extra Data**: Add custom metadata to events
- 🌍 **Environment & Release Tracking**: Distinguish between different deployments
- 🌐 **HTTP Request Context**: Capture request details for web applications
- 🔄 **Asynchronous Operations**: Built on Lwt for non-blocking operations

## 📦 Installation

### From Source

```bash
git clone https://github.com/getsentry/sentry-ocaml.git
cd sentry-ocaml
dune build
dune install
```

### Development Setup

For development or testing, you can also use it directly in your project:

```bash
# Clone into your project's dependencies
git clone https://github.com/getsentry/sentry-ocaml.git deps/sentry-ocaml

# Add to your dune-project
echo "(depends (sentry-ocaml (>= 0.1.0)))" >> dune-project
```

## 🚀 Quick Start

```ocaml
open Lwt.Syntax

let main () =
  (* Initialize Sentry with your DSN *)
  let dsn = "https://your-key@your-org.sentry.io/your-project" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> 
      Printf.printf "Sentry initialized successfully!\n";
      Lwt.return_unit
  | Error msg -> 
      Printf.printf "Failed to initialize: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

## 📝 Usage Examples

### Exception Capture

Capture exceptions automatically with full stack traces:

```ocaml
open Lwt.Syntax

let risky_operation () =
  try
    (* Your potentially failing code here *)
    if Random.int 10 > 5 then
      failwith "Random failure occurred!"
    else
      Printf.printf "Operation succeeded!\n";
    Lwt.return_unit
  with exn ->
    (* Capture the exception in Sentry *)
    let* result = Sentry.capture_exception exn in
    match result with
    | Ok () -> 
        Printf.printf "Exception captured in Sentry\n";
        Lwt.return_unit
    | Error msg -> 
        Printf.printf "Failed to capture exception: %s\n" msg;
        Lwt.return_unit

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> risky_operation ()
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

### Message Capture

Send custom messages and log entries:

```ocaml
open Lwt.Syntax

let log_user_action username action =
  let message = Printf.sprintf "User %s performed action: %s" username action in
  let* result = Sentry.capture_message ~level:"info" message in
  
  match result with
  | Ok () -> Printf.printf "Message logged to Sentry\n"
  | Error msg -> Printf.printf "Failed to log message: %s\n" msg

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> 
      let* () = log_user_action "john_doe" "login" in
      let* () = log_user_action "john_doe" "view_profile" in
      Lwt.return_unit
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

### Performance Monitoring (WIP)

Track transactions and spans for performance insights:

```ocaml
open Lwt.Syntax

(* Simulate some operations *)
let validate_data () = Unix.sleepf 0.1
let process_data () = Unix.sleepf 0.2
let save_data () = Unix.sleepf 0.3

let perform_complex_operation () =
  (* Start a transaction *)
  let transaction = Sentry.start_transaction ~name:"complex_operation" ~operation:"data_processing" in
  
  (* Validate data *)
  let validation_span = 
    Sentry.start_child transaction ~name:"validation" ~operation:"data_validation" 
  in
  validate_data ();
  let _ = Sentry.finish_span validation_span in
  
  (* Process data *)
  let process_span = 
    Sentry.start_child transaction ~name:"processing" ~operation:"data_processing" 
  in
  process_data ();
  let _ = Sentry.finish_span process_span in
  
  (* Save data *)
  let save_span = 
    Sentry.start_child transaction ~name:"saving" ~operation:"data_persistence" 
  in
  save_data ();
  let _ = Sentry.finish_span save_span in
  
  (* Finish and send the transaction *)
  let* _ = Sentry.finish_transaction transaction in
  
  Lwt.return_unit

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> perform_complex_operation ()
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

### User Context & Metadata

Add user information, tags, and extra data to events:

```ocaml
open Lwt.Syntax

let setup_user_context () =
  (* Set user information *)
  let* () = Sentry.set_user {
    id = Some "user123";
    username = Some "john_doe";
    email = Some "john@example.com";
    ip_address = Some "192.168.1.100";
  } in
  
  (* Add tags for categorization *)
  let* () = Sentry.set_tag "component" "user_service" in
  let* () = Sentry.set_tag "service" "api_gateway" in
  
  (* Add extra data for debugging *)
  let* () = Sentry.set_extra "deployment" "us-east-1" in
  let* () = Sentry.set_extra "version" "2.1.0" in
  
  (* Set environment and release *)
  let* () = Sentry.set_environment "production" in
  let* () = Sentry.set_release "v2.1.0" in
  
  Lwt.return_unit

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> 
      let* () = setup_user_context () in
      (* Now all events will include this context *)
      let* () = Sentry.capture_message ~level:"info" "User context configured" in
      Lwt.return_unit
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

### HTTP Request Context

Capture request details for web applications:

```ocaml
open Lwt.Syntax

let handle_api_request () =
  (* Set request context *)
  let* () = Sentry.set_request_context
    ~headers:[
      ("content-type", "application/json");
      ("authorization", "Bearer token123");
      ("user-agent", "MyApp/1.0");
    ]
    ~query_string:"?page=1&limit=10"
    ~data:[("action", "get_users"); ("filter", "active")]
    ~cookies:"session_id=abc123; theme=dark"
    ~env:[
      ("REMOTE_ADDR", "192.168.1.100");
      ("HTTP_HOST", "api.example.com");
      ("SERVER_PORT", "443");
    ]
    ~body_size:1024
    ~user_agent:"MyApp/1.0"
    "GET" "/api/users" in
  
  (* Simulate an API error *)
  try
    raise (Failure "API rate limit exceeded")
  with exn ->
    Sentry.capture_exception exn

let main () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> handle_api_request ()
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit

let () = Lwt_main.run (main ())
```

## 📖 Examples

Check out the `examples/` directory for complete working examples:

- `basic_exn_1.ml` - Basic exception capture
- `basic_exn_2.ml` - Exception capture with error handling
- `basic_msg.ml` - Message capture
- `stack_trace.ml` - Stack trace capture
- `http_request.ml` - HTTP request context
- `performance.ml` - Performance monitoring (WIP)

## 🔧 Configuration

### Environment Variables

**NOTE**: these environment variables are NOT read automatically by the SDK (yet).

- `SENTRY_DSN`: Your Sentry project DSN (required)
- `SENTRY_ENVIRONMENT`: Environment name (optional, can be set programmatically)
- `SENTRY_RELEASE`: Release version (optional, can be set programmatically)

### Programmatic Configuration

```ocaml
open Lwt.Syntax

let configure_sentry () =
  let dsn = Unix.getenv "SENTRY_DSN" in
  let* client_result = Sentry.init dsn in
  
  match client_result with
  | Ok _client -> 
      (* Set global configuration *)
      let* () = Sentry.set_environment "staging" in
      let* () = Sentry.set_release "v1.2.3" in
      let* () = Sentry.set_tag "service" "my_ocaml_app" in
      Lwt.return_unit
  | Error msg -> 
      Printf.printf "Sentry init failed: %s\n" msg;
      Lwt.return_unit
```

## 📚 API Reference

### Core Functions

- `Sentry.init dsn` - Initialize the Sentry client
- `Sentry.capture_exception ?level exn` - Capture an exception
- `Sentry.capture_message ?level message` - Capture a custom message

### Performance Monitoring

- `Sentry.start_transaction ~name ~operation` - Start a new transaction
- `Sentry.start_child transaction ~name ~operation` - Start a child span
- `Sentry.finish_span span` - Finish a span
- `Sentry.finish_transaction transaction` - Finish and send a transaction

### Context Management

- `Sentry.set_user user` - Set user information
- `Sentry.set_tag key value` - Add a tag
- `Sentry.set_extra key value` - Add extra data
- `Sentry.set_environment env` - Set environment
- `Sentry.set_release release` - Set release version
- `Sentry.set_request_context ...` - Set HTTP request context

## 🧪 Testing

Run the test suite:

```bash
dune runtest
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Sentry Documentation](https://docs.sentry.io/)
- [OCaml Documentation](https://ocaml.org/docs/)

---

**Note**: This SDK was created during Sentry Hack Week and is not officially supported by Sentry.
