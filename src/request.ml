module Request = struct
  type t = {
    method_ : string;
    url : string;
    headers : (string * string) list;
    query_string : string option;
    data : (string * string) list option;
    cookies : string option;
    env : (string * string) list option;
    body_size : int option;
    user_agent : string option;
  }

  (** Create a basic request context *)
  let create method_ url headers query_string data cookies env body_size user_agent =
    { method_; url; headers; query_string; data; cookies; env; body_size; user_agent }
  ;;

  (** Serialize request context to JSON *)
  let to_json request =
    let fields = [] in
    let fields = ("method", `String request.method_) :: fields in
    let fields = ("url", `String request.url) :: fields in

    (* Add headers if present *)
    let fields =
      if request.headers <> [] then
        let headers_json = List.map (fun (k, v) -> (k, `String v)) request.headers in
        ("headers", `Assoc headers_json) :: fields
      else
        fields
    in

    (* Add query string if present *)
    let fields =
      match request.query_string with
      | Some qs -> ("query_string", `String qs) :: fields
      | None -> fields
    in

    (* Add body size if present *)
    let fields =
      match request.body_size with
      | Some size -> ("body_size", `Int size) :: fields
      | None -> fields
    in

    (* Add data if present *)
    let fields =
      match request.data with
      | Some data_list ->
          if data_list <> [] then
            let data_json = List.map (fun (k, v) -> (k, `String v)) data_list in
            ("data", `Assoc data_json) :: fields
          else
            fields
      | None -> fields
    in

    (* Add cookies if present *)
    let fields =
      match request.cookies with
      | Some cookies -> ("cookies", `String cookies) :: fields
      | None -> fields
    in

    (* Add env if present *)
    let fields =
      match request.env with
      | Some env_list ->
          if env_list <> [] then
            let env_json = List.map (fun (k, v) -> (k, `String v)) env_list in
            ("env", `Assoc env_json) :: fields
          else
            fields
      | None -> fields
    in

    (* Add user agent if present *)
    let fields =
      match request.user_agent with
      | Some ua -> ("user_agent", `String ua) :: fields
      | None -> fields
    in

    fields
  ;;
end
