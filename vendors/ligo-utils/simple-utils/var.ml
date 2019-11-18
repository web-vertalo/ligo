type t = {
  name : string ;
  counter : int option ;
}

let pp ppf v =
  match v.counter with
  | None -> Format.fprintf ppf "%s" v.name
  | Some i -> Format.fprintf ppf "%s#%d" v.name i

module Int = X_int
module Option = X_option

let equal v1 v2 =
  String.equal v1.name v2.name
  && Option.equal Int.equal v1.counter v2.counter

let compare v1 v2 =
  let cname = String.compare v1.name v2.name in
  if Int.equal cname 0
  then Option.compare Int.compare v1.counter v2.counter
  else cname

let global_counter = ref 0

let reset_counter () = global_counter := 0

let fresh ?name () =
  let name = Option.unopt ~default:"" name in
  let counter = incr global_counter ; Some !global_counter in
  { name ; counter }

let of_name name =
  { name = name ;
    counter = None
  }

let name_of v = v.name
