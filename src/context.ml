(* TODO: the data included here is not complete. MVP for now *)
(* TODO: should config be separate from context? *)

module Context = struct
  type user = {
    id : string option;
    username : string option;
    email : string option;
    ip_address : string option;
  }

  type t = { user : user option }

  let default = { user = None }
  let set_user _context user = { user = Some user }
end
