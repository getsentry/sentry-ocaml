(* TODO: the data included here is not complete. MVP for now *)
(* TODO: should config be separate from context? *)

module Context = struct
  module Request = Request.Request

  type user = {
    id : string option;
    username : string option;
    email : string option;
    ip_address : string option;
  }

  type t = {
    user : user option;
    tags : (string * string) list;
    extra : (string * string) list;
    environment : string option;
    release : string option;
    request : Request.t option;
  }

  let default =
    { user = None; tags = []; extra = []; environment = None; release = None; request = None }
  ;;

  let set_user context user = { context with user = Some user }

  let set_tag context key value =
    let new_tags = (key, value) :: context.tags in
    { context with tags = new_tags }
  ;;

  let set_extra context key value =
    let new_extra = (key, value) :: context.extra in
    { context with extra = new_extra }
  ;;

  let set_environment context env = { context with environment = Some env }
  let set_release context release = { context with release = Some release }
  let set_request context request = { context with request = Some request }

  (** Serialize context to JSON *)
  let to_json context =
    let fields = [] in

    (* Add tags *)
    let fields =
      if context.tags <> [] then
        let tags_json = List.map (fun (k, v) -> (k, `String v)) context.tags in
        ("tags", `Assoc tags_json) :: fields
      else
        fields
    in

    (* Add extra data *)
    let fields =
      if context.extra <> [] then
        let extra_json = List.map (fun (k, v) -> (k, `String v)) context.extra in
        ("extra", `Assoc extra_json) :: fields
      else
        fields
    in

    (* Add environment *)
    let fields =
      match context.environment with
      | Some env -> ("environment", `String env) :: fields
      | None -> fields
    in

    (* Add release *)
    let fields =
      match context.release with
      | Some release -> ("release", `String release) :: fields
      | None -> fields
    in

    (* Add request context *)
    let fields =
      match context.request with
      | Some request ->
          let request_fields = Request.to_json request in
          ("request", `Assoc request_fields) :: fields
      | None -> fields
    in

    (* Add user if present *)
    let fields =
      match context.user with
      | Some user ->
          let user_fields = [] in
          let user_fields =
            match user.id with
            | Some id -> ("id", `String id) :: user_fields
            | None -> user_fields
          in
          let user_fields =
            match user.username with
            | Some username -> ("username", `String username) :: user_fields
            | None -> user_fields
          in
          let user_fields =
            match user.email with
            | Some email -> ("email", `String email) :: user_fields
            | None -> user_fields
          in
          let user_fields =
            match user.ip_address with
            | Some ip -> ("ip_address", `String ip) :: user_fields
            | None -> user_fields
          in
          ("user", `Assoc user_fields) :: fields
      | None -> fields
    in

    fields
  ;;
end
