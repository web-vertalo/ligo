open Trace

module I = Ast_core
module O = Ast_typed
open O.Combinators

module DEnv = Environment
module Environment = O.Environment

module Solver = Typer_new.Solver

type environment = Environment.t

module Errors = struct
  let michelson_comb_no_record (loc:Location.t) () =
    let title = (thunk "bad michelson_pair_right_comb type parameter") in
    let message () = "michelson_pair_right_comb type operator must be used on a record type" in
    let data = [
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc) ;
    ] in
    error ~data title message ()

  let michelson_comb_no_variant (loc:Location.t) () =
    let title = (thunk "bad michelson_or_right_comb type parameter") in
    let message () = "michelson_or_right_comb type operator must be used on a variant type" in
    let data = [
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc) ;
    ] in
    error ~data title message ()

  let unbound_type_variable (e:environment) (tv:I.type_variable) (loc:Location.t) () =
    let name = Var.to_name tv in
    let suggestion = match name with
        | "integer" -> "int"
        | "str" -> "string"
        | "boolean" -> "bool"
        | _ -> "no suggestion" in
    let title = (thunk "unbound type variable") in
    let message () = "" in
    let data = [
      ("variable" , fun () -> Format.asprintf "%a" I.PP.type_variable tv) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc) ;
      ("in" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
      ("did_you_mean" , fun () -> suggestion)
    ] in
    error ~data title message ()

  let unbound_variable (e:environment) (n:I.expression_variable) (loc:Location.t) () =
    let name () = Format.asprintf "%a" I.PP.expression_variable n in
    let title = (thunk ("unbound variable "^(name ()))) in
    let message () = "" in
    let data = [
      ("variable" , name) ;
      ("environment" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let match_empty_variant : I.matching_expr -> Location.t -> unit -> _ =
    fun matching loc () ->
      let title = (thunk "match with no cases") in
      let message () = "" in
      let data = [
        ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
        ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
      ] in
      error ~data title message ()

  let match_missing_case : I.matching_expr -> Location.t -> unit -> _ =
    fun matching loc () ->
    let title = (thunk "missing case in match") in
    let message () = "" in
    let data = [
      ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let match_redundant_case : I.matching_expr -> Location.t -> unit -> _ =
    fun matching loc () ->
    let title = (thunk "redundant case in match") in
    let message () = "" in
    let data = [
      ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let unbound_constructor (e:environment) (c:I.constructor') (loc:Location.t) () =
    let title = (thunk "unbound constructor") in
    let message () = "" in
    let data = [
      ("constructor" , fun () -> Format.asprintf "%a" I.PP.constructor c);
      ("environment" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let redundant_constructor (e:environment) (c:I.constructor') () =
    let title = (thunk "redundant constructor") in
    let message () = "" in
    let data = [
      ("constructor" , fun () -> Format.asprintf "%a" I.PP.constructor c);
      ("environment" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
    ] in
    error ~data title message ()
  
  let michelson_or (c:I.constructor') loc () =
    let title = (thunk "michelson_or types must be annotated") in
    let message () = "" in
    let data = [
      ("constructor" , fun () -> Format.asprintf "%a" I.PP.constructor c);
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let wrong_arity (n:string) (expected:int) (actual:int) (loc : Location.t) () =
    let title () = "wrong arity" in
    let message () = "" in
    let data = [
      ("function" , fun () -> Format.asprintf "%s" n) ;
      ("expected" , fun () -> Format.asprintf "%d" expected) ;
      ("actual" , fun () -> Format.asprintf "%d" actual) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()


  let match_tuple_wrong_arity (expected:'a list) (actual:'b list) (loc:Location.t) () =
    let title () = "matching tuple of different size" in
    let message () = "" in
    let data = [
      ("expected" , fun () -> Format.asprintf "%d" (List.length expected)) ;
      ("actual" , fun () -> Format.asprintf "%d" (List.length actual)) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  (* TODO: this should be a trace_info? *)
  let program_error (p:I.program) () =
    let message () = "" in
    let title = (thunk "typing program") in
    let data = [
      ("program" , fun () -> Format.asprintf "%a" I.PP.program p)
    ] in
    error ~data title message ()

  let constant_declaration_error (name:I.expression_variable) (ae:I.expr) (expected: O.type_expression option) () =
    let title = (thunk "typing constant declaration") in
    let message () = "" in
    let data = [
      ("constant" , fun () -> Format.asprintf "%a" I.PP.expression_variable name) ;
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("expected" , fun () ->
          match expected with
            None -> "(no annotation for the expected type)"
          | Some expected -> Format.asprintf "%a" O.PP.type_expression expected) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp ae.location)
    ] in
    error ~data title message ()

  let match_error : ?msg:string -> expected: I.matching_expr -> actual: O.type_expression -> Location.t -> unit -> _ =
    fun ?(msg = "") ~expected ~actual loc () ->
    let title = (thunk "typing match") in
    let message () = msg in
    let data = [
      ("expected" , fun () -> Format.asprintf "%a" I.PP.matching_type expected);
      ("actual" , fun () -> Format.asprintf "%a" O.PP.type_expression actual) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let needs_annotation (e : I.expression) (case : string) () =
    let title = (thunk "this expression must be annotated with its type") in
    let message () = Format.asprintf "%s needs an annotation" case in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp e.location)
    ] in
    error ~data title message ()

  let fvs_in_create_contract_lambda (e : I.expression) (fvar : Ast_typed.expression_variable) () =
    let title = (thunk "No free variable allowed in this lambda") in
    let message () = Format.asprintf "variable '%a'" Var.pp fvar in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp e.location)
    ] in
    error ~data title message ()

  let create_contract_lambda (cst : I.constant') (e : I.expression) () =
    let title () = Format.asprintf "%a first argument must be inlined" I.PP.constant cst in
    let message () = Format.asprintf "contract code can be inlined using a lambda" in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp e.location)
    ] in
    error ~data title message ()

  let type_error_approximate ?(msg="") ~(expected: string) ~(actual: O.type_expression) ~(expression : I.expression) (loc:Location.t) () =
    let title = (thunk "type error") in
    let message () = msg in
    let data = [
      ("expected"   , fun () -> Format.asprintf "%s" expected);
      ("actual"     , fun () -> Format.asprintf "%a" O.PP.type_expression actual);
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression expression) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let _type_error ?(msg="") ~(expected: O.type_expression) ~(actual: O.type_expression) ~(expression : I.expression) (loc:Location.t) () =
    let title = (thunk "type error") in
    let message () = msg in
    let data = [
      ("expected"   , fun () -> Format.asprintf "%a" O.PP.type_expression expected);
      ("actual"     , fun () -> Format.asprintf "%a" O.PP.type_expression actual);
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression expression) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let bad_record_access (field : I.label) (ae : I.expression) (t : O.type_expression) (loc:Location.t) () =
    let title = (thunk "invalid record field") in
    let message () = "" in
    let data = [
      ("field" , fun () -> Format.asprintf "%a" I.PP.label field) ;
      ("record_value" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("tuple_type" , fun () -> Format.asprintf "%a" O.PP.type_expression t) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

end
open Errors

let convert_constructor' (I.Constructor c) = O.Constructor c
let unconvert_constructor' (O.Constructor c) = I.Constructor c
let convert_label (I.Label c) = O.Label c
let convert_type_constant : I.type_constant -> O.type_constant = function
    | TC_unit -> TC_unit
    | TC_string -> TC_string
    | TC_bytes -> TC_bytes
    | TC_nat -> TC_nat
    | TC_int -> TC_int
    | TC_mutez -> TC_mutez
    | TC_operation -> TC_operation
    | TC_address -> TC_address
    | TC_key -> TC_key
    | TC_key_hash -> TC_key_hash
    | TC_chain_id -> TC_chain_id
    | TC_signature -> TC_signature
    | TC_timestamp -> TC_timestamp
    | TC_void -> TC_void

let convert_constant' : I.constant' -> O.constant' = function
  | C_INT -> C_INT
  | C_UNIT -> C_UNIT
  | C_NIL -> C_NIL
  | C_NOW -> C_NOW
  | C_IS_NAT -> C_IS_NAT
  | C_SOME -> C_SOME
  | C_NONE -> C_NONE
  | C_ASSERTION -> C_ASSERTION
  | C_ASSERT_INFERRED -> C_ASSERT_INFERRED
  | C_FAILWITH -> C_FAILWITH
  | C_UPDATE -> C_UPDATE
  (* Loops *)
  | C_ITER -> C_ITER
  | C_FOLD_WHILE -> C_FOLD_WHILE
  | C_FOLD_CONTINUE -> C_FOLD_CONTINUE
  | C_FOLD_STOP -> C_FOLD_STOP
  | C_LOOP_LEFT -> C_LOOP_LEFT
  | C_LOOP_CONTINUE -> C_LOOP_CONTINUE
  | C_LOOP_STOP -> C_LOOP_STOP
  | C_FOLD -> C_FOLD
  (* MATH *)
  | C_NEG -> C_NEG
  | C_ABS -> C_ABS
  | C_ADD -> C_ADD
  | C_SUB -> C_SUB
  | C_MUL -> C_MUL
  | C_EDIV -> C_EDIV
  | C_DIV -> C_DIV
  | C_MOD -> C_MOD
  (* LOGIC *)
  | C_NOT -> C_NOT
  | C_AND -> C_AND
  | C_OR -> C_OR
  | C_XOR -> C_XOR
  | C_LSL -> C_LSL
  | C_LSR -> C_LSR
  (* COMPARATOR *)
  | C_EQ -> C_EQ
  | C_NEQ -> C_NEQ
  | C_LT -> C_LT
  | C_GT -> C_GT
  | C_LE -> C_LE
  | C_GE -> C_GE
  (* Bytes/ String *)
  | C_SIZE -> C_SIZE
  | C_CONCAT -> C_CONCAT
  | C_SLICE -> C_SLICE
  | C_BYTES_PACK -> C_BYTES_PACK
  | C_BYTES_UNPACK -> C_BYTES_UNPACK
  | C_CONS -> C_CONS
  (* Pair *)
  | C_PAIR -> C_PAIR
  | C_CAR -> C_CAR
  | C_CDR -> C_CDR
  | C_LEFT -> C_LEFT
  | C_RIGHT -> C_RIGHT
  (* Set *)
  | C_SET_EMPTY -> C_SET_EMPTY
  | C_SET_LITERAL -> C_SET_LITERAL
  | C_SET_ADD -> C_SET_ADD
  | C_SET_REMOVE -> C_SET_REMOVE
  | C_SET_ITER -> C_SET_ITER
  | C_SET_FOLD -> C_SET_FOLD
  | C_SET_MEM -> C_SET_MEM
  (* List *)
  | C_LIST_EMPTY -> C_LIST_EMPTY
  | C_LIST_LITERAL -> C_LIST_LITERAL
  | C_LIST_ITER -> C_LIST_ITER
  | C_LIST_MAP -> C_LIST_MAP
  | C_LIST_FOLD -> C_LIST_FOLD
  (* Maps *)
  | C_MAP -> C_MAP
  | C_MAP_EMPTY -> C_MAP_EMPTY
  | C_MAP_LITERAL -> C_MAP_LITERAL
  | C_MAP_GET -> C_MAP_GET
  | C_MAP_GET_FORCE -> C_MAP_GET_FORCE
  | C_MAP_ADD -> C_MAP_ADD
  | C_MAP_REMOVE -> C_MAP_REMOVE
  | C_MAP_UPDATE -> C_MAP_UPDATE
  | C_MAP_ITER -> C_MAP_ITER
  | C_MAP_MAP -> C_MAP_MAP
  | C_MAP_FOLD -> C_MAP_FOLD
  | C_MAP_MEM -> C_MAP_MEM
  | C_MAP_FIND -> C_MAP_FIND
  | C_MAP_FIND_OPT -> C_MAP_FIND_OPT
  (* Big Maps *)
  | C_BIG_MAP -> C_BIG_MAP
  | C_BIG_MAP_EMPTY -> C_BIG_MAP_EMPTY
  | C_BIG_MAP_LITERAL -> C_BIG_MAP_LITERAL
  (* Crypto *)
  | C_SHA256 -> C_SHA256
  | C_SHA512 -> C_SHA512
  | C_BLAKE2b -> C_BLAKE2b
  | C_HASH -> C_HASH
  | C_HASH_KEY -> C_HASH_KEY
  | C_CHECK_SIGNATURE -> C_CHECK_SIGNATURE
  | C_CHAIN_ID -> C_CHAIN_ID
  (* Blockchain *)
  | C_CALL -> C_CALL
  | C_CONTRACT -> C_CONTRACT
  | C_CONTRACT_OPT -> C_CONTRACT_OPT
  | C_CONTRACT_ENTRYPOINT -> C_CONTRACT_ENTRYPOINT
  | C_CONTRACT_ENTRYPOINT_OPT -> C_CONTRACT_ENTRYPOINT_OPT
  | C_AMOUNT -> C_AMOUNT
  | C_BALANCE -> C_BALANCE
  | C_SOURCE -> C_SOURCE
  | C_SENDER -> C_SENDER
  | C_ADDRESS -> C_ADDRESS
  | C_SELF -> C_SELF
  | C_SELF_ADDRESS -> C_SELF_ADDRESS
  | C_IMPLICIT_ACCOUNT -> C_IMPLICIT_ACCOUNT
  | C_SET_DELEGATE -> C_SET_DELEGATE
  | C_CREATE_CONTRACT -> C_CREATE_CONTRACT
  | C_CONVERT_TO_LEFT_COMB -> C_CONVERT_TO_LEFT_COMB
  | C_CONVERT_TO_RIGHT_COMB -> C_CONVERT_TO_RIGHT_COMB
  | C_CONVERT_FROM_LEFT_COMB -> C_CONVERT_FROM_LEFT_COMB
  | C_CONVERT_FROM_RIGHT_COMB -> C_CONVERT_FROM_RIGHT_COMB

let unconvert_constant' : O.constant' -> I.constant' = function
  | C_INT -> C_INT
  | C_UNIT -> C_UNIT
  | C_NIL -> C_NIL
  | C_NOW -> C_NOW
  | C_IS_NAT -> C_IS_NAT
  | C_SOME -> C_SOME
  | C_NONE -> C_NONE
  | C_ASSERTION -> C_ASSERTION
  | C_ASSERT_INFERRED -> C_ASSERT_INFERRED
  | C_FAILWITH -> C_FAILWITH
  | C_UPDATE -> C_UPDATE
  (* Loops *)
  | C_ITER -> C_ITER
  | C_FOLD_WHILE -> C_FOLD_WHILE
  | C_FOLD_CONTINUE -> C_FOLD_CONTINUE
  | C_FOLD_STOP -> C_FOLD_STOP
  | C_LOOP_LEFT -> C_LOOP_LEFT
  | C_LOOP_CONTINUE -> C_LOOP_CONTINUE
  | C_LOOP_STOP -> C_LOOP_STOP
  | C_FOLD -> C_FOLD
  (* MATH *)
  | C_NEG -> C_NEG
  | C_ABS -> C_ABS
  | C_ADD -> C_ADD
  | C_SUB -> C_SUB
  | C_MUL -> C_MUL
  | C_EDIV -> C_EDIV
  | C_DIV -> C_DIV
  | C_MOD -> C_MOD
  (* LOGIC *)
  | C_NOT -> C_NOT
  | C_AND -> C_AND
  | C_OR -> C_OR
  | C_XOR -> C_XOR
  | C_LSL -> C_LSL
  | C_LSR -> C_LSR
  (* COMPARATOR *)
  | C_EQ -> C_EQ
  | C_NEQ -> C_NEQ
  | C_LT -> C_LT
  | C_GT -> C_GT
  | C_LE -> C_LE
  | C_GE -> C_GE
  (* Bytes/ String *)
  | C_SIZE -> C_SIZE
  | C_CONCAT -> C_CONCAT
  | C_SLICE -> C_SLICE
  | C_BYTES_PACK -> C_BYTES_PACK
  | C_BYTES_UNPACK -> C_BYTES_UNPACK
  | C_CONS -> C_CONS
  (* Pair *)
  | C_PAIR -> C_PAIR
  | C_CAR -> C_CAR
  | C_CDR -> C_CDR
  | C_LEFT -> C_LEFT
  | C_RIGHT -> C_RIGHT
  (* Set *)
  | C_SET_EMPTY -> C_SET_EMPTY
  | C_SET_LITERAL -> C_SET_LITERAL
  | C_SET_ADD -> C_SET_ADD
  | C_SET_REMOVE -> C_SET_REMOVE
  | C_SET_ITER -> C_SET_ITER
  | C_SET_FOLD -> C_SET_FOLD
  | C_SET_MEM -> C_SET_MEM
  (* List *)
  | C_LIST_EMPTY -> C_LIST_EMPTY
  | C_LIST_LITERAL -> C_LIST_LITERAL
  | C_LIST_ITER -> C_LIST_ITER
  | C_LIST_MAP -> C_LIST_MAP
  | C_LIST_FOLD -> C_LIST_FOLD
  (* Maps *)
  | C_MAP -> C_MAP
  | C_MAP_EMPTY -> C_MAP_EMPTY
  | C_MAP_LITERAL -> C_MAP_LITERAL
  | C_MAP_GET -> C_MAP_GET
  | C_MAP_GET_FORCE -> C_MAP_GET_FORCE
  | C_MAP_ADD -> C_MAP_ADD
  | C_MAP_REMOVE -> C_MAP_REMOVE
  | C_MAP_UPDATE -> C_MAP_UPDATE
  | C_MAP_ITER -> C_MAP_ITER
  | C_MAP_MAP -> C_MAP_MAP
  | C_MAP_FOLD -> C_MAP_FOLD
  | C_MAP_MEM -> C_MAP_MEM
  | C_MAP_FIND -> C_MAP_FIND
  | C_MAP_FIND_OPT -> C_MAP_FIND_OPT
  (* Big Maps *)
  | C_BIG_MAP -> C_BIG_MAP
  | C_BIG_MAP_EMPTY -> C_BIG_MAP_EMPTY
  | C_BIG_MAP_LITERAL -> C_BIG_MAP_LITERAL
  (* Crypto *)
  | C_SHA256 -> C_SHA256
  | C_SHA512 -> C_SHA512
  | C_BLAKE2b -> C_BLAKE2b
  | C_HASH -> C_HASH
  | C_HASH_KEY -> C_HASH_KEY
  | C_CHECK_SIGNATURE -> C_CHECK_SIGNATURE
  | C_CHAIN_ID -> C_CHAIN_ID
  (* Blockchain *)
  | C_CALL -> C_CALL
  | C_CONTRACT -> C_CONTRACT
  | C_CONTRACT_OPT -> C_CONTRACT_OPT
  | C_CONTRACT_ENTRYPOINT -> C_CONTRACT_ENTRYPOINT
  | C_CONTRACT_ENTRYPOINT_OPT -> C_CONTRACT_ENTRYPOINT_OPT
  | C_AMOUNT -> C_AMOUNT
  | C_BALANCE -> C_BALANCE
  | C_SOURCE -> C_SOURCE
  | C_SENDER -> C_SENDER
  | C_ADDRESS -> C_ADDRESS
  | C_SELF -> C_SELF
  | C_SELF_ADDRESS -> C_SELF_ADDRESS
  | C_IMPLICIT_ACCOUNT -> C_IMPLICIT_ACCOUNT
  | C_SET_DELEGATE -> C_SET_DELEGATE
  | C_CREATE_CONTRACT -> C_CREATE_CONTRACT
  | C_CONVERT_TO_LEFT_COMB -> C_CONVERT_TO_LEFT_COMB
  | C_CONVERT_TO_RIGHT_COMB -> C_CONVERT_TO_RIGHT_COMB
  | C_CONVERT_FROM_LEFT_COMB -> C_CONVERT_FROM_LEFT_COMB
  | C_CONVERT_FROM_RIGHT_COMB -> C_CONVERT_FROM_RIGHT_COMB

let rec type_program (p:I.program) : (O.program * O.typer_state) result =
  let aux (e, acc:(environment * O.declaration Location.wrap list)) (d:I.declaration Location.wrap) =
    let%bind ed' = (bind_map_location (type_declaration e (Solver.placeholder_for_state_of_new_typer ()))) d in
    let loc : 'a . 'a Location.wrap -> _ -> _ = fun x v -> Location.wrap ~loc:x.location v in
    let (e', _placeholder_for_state_of_new_typer , d') = Location.unwrap ed' in
    match d' with
    | None -> ok (e', acc)
    | Some d' -> ok (e', loc ed' d' :: acc)
  in
  let%bind (_, lst) =
    trace (fun () -> program_error p ()) @@
    bind_fold_list aux (DEnv.default, []) p in
  ok @@ (List.rev lst , (Solver.placeholder_for_state_of_new_typer ()))

and type_declaration env (_placeholder_for_state_of_new_typer : O.typer_state) : I.declaration -> (environment * O.typer_state * O.declaration option) result = function
  | Declaration_type (type_name , type_expression) ->
      let%bind tv = evaluate_type env type_expression in
      let env' = Environment.add_type (type_name) tv env in
      ok (env', (Solver.placeholder_for_state_of_new_typer ()) , None)
  | Declaration_constant (binder , tv_opt , inline, expression) -> (
      let%bind tv'_opt = bind_map_option (evaluate_type env) tv_opt in
      let%bind expr =
        trace (constant_declaration_error binder expression tv'_opt) @@
        type_expression' ?tv_opt:tv'_opt env expression in
      let post_env = Environment.add_ez_ae binder expr env in
      ok (post_env, (Solver.placeholder_for_state_of_new_typer ()) , Some (O.Declaration_constant { binder ; expr ; inline ; post_env}))
    )

and type_match : (environment -> I.expression -> O.expression result) -> environment -> O.type_expression -> I.matching_expr -> I.expression -> Location.t -> O.matching_expr result =
  fun f e t i ae loc -> match i with
  | Match_option {match_none ; match_some} ->
      let%bind tv =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_option t in
      let%bind match_none = f e match_none in
      let (opt, b,_) = match_some in
      let e' = Environment.add_ez_binder opt tv e in
      let%bind body = f e' b in
      ok (O.Match_option {match_none ; match_some = {opt; body; tv}})
  | Match_list {match_nil ; match_cons} ->
      let%bind t_elt =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_list t in
      let%bind match_nil = f e match_nil in
      let (hd, tl, b,_) = match_cons in
      let e' = Environment.add_ez_binder hd t_elt e in
      let e' = Environment.add_ez_binder tl t e' in
      let%bind body = f e' b in
      ok (O.Match_list {match_nil ; match_cons = {hd; tl; body; tv=t_elt}})
  | Match_tuple ((vars, b),_) ->
      let%bind tvs =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_tuple t in
      let%bind vars' =
        generic_try (match_tuple_wrong_arity tvs vars loc)
        @@ (fun () -> List.combine vars tvs) in
      let aux prev (name, tv) = Environment.add_ez_binder name tv prev in
      let e' = List.fold_left aux e vars' in
      let%bind body = f e' b in
      ok (O.Match_tuple { vars ; body ; tvs})
  | Match_variant (lst,_) ->
      let%bind variant_cases' =
        trace (match_error ~expected:i ~actual:t loc)
        @@ Ast_typed.Combinators.get_t_sum t in
      let variant_cases = List.map fst @@ O.CMap.to_kv_list variant_cases' in
      let match_cases = List.map (fun x -> convert_constructor' @@ fst @@ fst x) lst in
      let test_case = fun c ->
        Assert.assert_true (List.mem c match_cases)
      in
      let%bind () =
        trace_strong (match_missing_case i loc) @@
        bind_iter_list test_case variant_cases in
      let%bind () =
        trace_strong (match_redundant_case i loc) @@
        Assert.assert_true List.(length variant_cases = length match_cases) in
      let%bind cases =
        let aux ((constructor_name , pattern) , b) =
          let%bind {ctor_type=constructor;_} =
            trace_option (unbound_constructor e constructor_name loc) @@
            O.CMap.find_opt (convert_constructor' constructor_name) variant_cases' in
          let e' = Environment.add_ez_binder pattern constructor e in
          let%bind body = f e' b in
          let constructor = convert_constructor' constructor_name in
          ok ({constructor ; pattern ; body} : O.matching_content_case)
        in
        bind_map_list aux lst in
      ok (O.Match_variant { cases ; tv=t })

and evaluate_type (e:environment) (t:I.type_expression) : O.type_expression result =
  let return tv' = ok (make_t ~loc:t.location tv' (Some t)) in
  match t.type_content with
  | T_arrow {type1;type2} ->
      let%bind type1 = evaluate_type e type1 in
      let%bind type2 = evaluate_type e type2 in
      return (T_arrow {type1;type2})
  | T_sum m ->
      let aux k ({ctor_type;michelson_annotation;ctor_decl_pos} : I.ctor_content) prev =
        let%bind prev' = prev in
        let%bind ctor_type = evaluate_type e ctor_type in
        let%bind () = match Environment.get_constructor k e with
          | Some _ ->
            if I.CMap.mem (Constructor "M_left") m || I.CMap.mem (Constructor "M_right") m then
              ok ()
            else fail (redundant_constructor e k)
          | None -> ok () in
        let v' : O.ctor_content = {ctor_type;michelson_annotation;ctor_decl_pos} in
        ok @@ O.CMap.add (convert_constructor' k) v' prev'
      in
      let%bind m = I.CMap.fold aux m (ok O.CMap.empty) in
      return (T_sum m)
  | T_record m ->
      let aux k ({field_type;field_annotation;field_decl_pos}: I.field_content) prev =
        let%bind prev' = prev in
        let%bind field_type = evaluate_type e field_type in
        let v' = ({field_type;michelson_annotation=field_annotation;field_decl_pos} : O.field_content) in
        ok @@ O.LMap.add (convert_label k) v' prev'
      in
      let%bind m = I.LMap.fold aux m (ok O.LMap.empty) in
      return (T_record m)
  | T_variable name ->
      let%bind tv =
        trace_option (unbound_type_variable e name t.location)
        @@ Environment.get_type_opt (name) e in
      ok tv
  | T_constant cst ->
      return (T_constant (convert_type_constant cst))
  | T_operator opt -> ( match opt with
    | TC_set s -> 
        let%bind s = evaluate_type e s in 
        return @@ T_operator (O.TC_set (s))
    | TC_option o -> 
        let%bind o = evaluate_type e o in 
        return @@ T_operator (O.TC_option (o))
    | TC_list l -> 
        let%bind l = evaluate_type e l in 
        return @@ T_operator (O.TC_list (l))
    | TC_map (k,v) ->
        let%bind k = evaluate_type e k in 
        let%bind v = evaluate_type e v in 
        return @@ T_operator (O.TC_map {k;v})
    | TC_big_map (k,v) ->
        let%bind k = evaluate_type e k in 
        let%bind v = evaluate_type e v in 
        return @@ T_operator (O.TC_big_map {k;v})
    | TC_map_or_big_map (k,v) ->
        let%bind k = evaluate_type e k in 
        let%bind v = evaluate_type e v in 
        return @@ T_operator (O.TC_map_or_big_map {k;v})
    | TC_contract c ->
        let%bind c = evaluate_type e c in
        return @@ T_operator (O.TC_contract c)
    | TC_michelson_pair_right_comb c ->
        let%bind c' = evaluate_type e c in
        let%bind lmap = match c'.type_content with
          | T_record lmap when (not (Ast_typed.Helpers.is_tuple_lmap lmap)) -> ok lmap
          | _ -> fail (michelson_comb_no_record t.location) in
        let record = Operators.Typer.Converter.convert_pair_to_right_comb (Ast_typed.LMap.to_kv_list lmap) in
        return @@ record
    | TC_michelson_pair_left_comb c ->
        let%bind c' = evaluate_type e c in
        let%bind lmap = match c'.type_content with
          | T_record lmap when (not (Ast_typed.Helpers.is_tuple_lmap lmap)) -> ok lmap
          | _ -> fail (michelson_comb_no_record t.location) in
        let record = Operators.Typer.Converter.convert_pair_to_left_comb (Ast_typed.LMap.to_kv_list lmap) in
        return @@ record
    | TC_michelson_or_right_comb c ->
        let%bind c' = evaluate_type e c in
        let%bind cmap = match c'.type_content with
          | T_sum cmap -> ok cmap
          | _ -> fail (michelson_comb_no_variant t.location) in
        let pair = Operators.Typer.Converter.convert_variant_to_right_comb (Ast_typed.CMap.to_kv_list cmap) in
        return @@ pair
    | TC_michelson_or_left_comb c ->
        let%bind c' = evaluate_type e c in
        let%bind cmap = match c'.type_content with
          | T_sum cmap -> ok cmap
          | _ -> fail (michelson_comb_no_variant t.location) in
        let pair = Operators.Typer.Converter.convert_variant_to_left_comb(Ast_typed.CMap.to_kv_list cmap) in
        return @@ pair
  )

and type_expression : environment -> O.typer_state -> ?tv_opt:O.type_expression -> I.expression -> (O.expression * O.typer_state) result
  = fun e _placeholder_for_state_of_new_typer ?tv_opt ae ->
    let%bind res = type_expression' e ?tv_opt ae in
    ok (res, (Solver.placeholder_for_state_of_new_typer ()))
and type_expression' : environment -> ?tv_opt:O.type_expression -> I.expression -> O.expression result = fun e ?tv_opt ae ->
  let module L = Logger.Stateful() in
  let return expr tv =
    let%bind () =
      match tv_opt with
      | None -> ok ()
      | Some tv' -> O.assert_type_expression_eq (tv' , tv) in
    let location = ae.location in
    ok @@ make_e ~location expr tv e in
  let main_error =
    let title () = "typing expression" in
    let content () = "" in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp ae.location) ;
      ("misc" , fun () -> L.get ()) ;
    ] in
    error ~data title content in
  trace main_error @@
  match ae.expression_content with
  (* Basic *)
  | E_variable name ->
      let%bind tv' =
        trace_option (unbound_variable e name ae.location)
        @@ Environment.get_opt name e in
      return (E_variable name) tv'.type_value
  | E_literal Literal_unit ->
      return (E_literal (Literal_unit)) (t_unit ())
  | E_literal Literal_void -> return (E_literal (Literal_void)) (t_unit ()) (* TODO : IS this really a t_unit ?*)
  | E_literal (Literal_string s) ->
      return (E_literal (Literal_string s)) (t_string ())
  | E_literal (Literal_key s) ->
      return (E_literal (Literal_key s)) (t_key ())
  | E_literal (Literal_key_hash s) ->
      return (E_literal (Literal_key_hash s)) (t_key_hash ())
  | E_literal (Literal_chain_id s) ->
      return (E_literal (Literal_chain_id s)) (t_chain_id ())
  | E_literal (Literal_signature s) ->
      return (E_literal (Literal_signature s)) (t_signature ())
  | E_literal (Literal_bytes s) ->
      return (E_literal (Literal_bytes s)) (t_bytes ())
  | E_literal (Literal_int n) ->
      return (E_literal (Literal_int n)) (t_int ())
  | E_literal (Literal_nat n) ->
      return (E_literal (Literal_nat n)) (t_nat ())
  | E_literal (Literal_timestamp n) ->
      return (E_literal (Literal_timestamp n)) (t_timestamp ())
  | E_literal (Literal_mutez n) ->
      return (E_literal (Literal_mutez n)) (t_mutez ())
  | E_literal (Literal_address s) ->
      return (e_address s) (t_address ())
  | E_literal (Literal_operation op) ->
      return (e_operation op) (t_operation ())
  | E_record_accessor {record;path} ->
      let%bind e' = type_expression' e record in
      let aux (prev:O.expression) (a:I.label) : O.expression result =
            let property = a in
            let%bind r_tv = get_t_record prev.type_expression in
            let%bind tv =
              generic_try (bad_record_access property ae prev.type_expression ae.location)
              @@ (fun () -> let ({field_type;_} : O.field_content) = O.LMap.find (convert_label property) r_tv in field_type) in
            let location = ae.location in
            ok @@ make_e ~location (E_record_accessor {record=prev; path=convert_label property}) tv e
      in
      let%bind ae =
      trace (simple_info "accessing") @@ aux e' path in
      (* check type annotation of the final accessed element *)
      let%bind () =
        match tv_opt with
        | None -> ok ()
        | Some tv' -> O.assert_type_expression_eq (tv' , ae.type_expression) in
      ok(ae)
  | E_constructor {constructor = Constructor s ; element} when String.equal s "M_left" || String.equal s "M_right" -> (
    let%bind t = trace_option (Errors.michelson_or (Constructor s) ae.location) @@ tv_opt in 
    let%bind expr' = type_expression' e element in
    ( match t.type_content with
      | T_sum c ->
        let {ctor_type ; _} : O.ctor_content = O.CMap.find (O.Constructor s) c in
        let%bind _assert = O.assert_type_expression_eq (expr'.type_expression, ctor_type) in
        return (E_constructor {constructor = Constructor s; element=expr'}) t
      | _ -> simple_fail "ll" 
    )
  )
  (* Sum *)
  | E_constructor {constructor; element} ->
      let%bind (c_tv, sum_tv) =
        let error =
          let title () = "no such constructor" in
          let content () =
            Format.asprintf "%a in:\n%a\n"
              Stage_common.PP.constructor constructor 
              O.Environment.PP.full_environment e
          in
          error title content in
        trace_option error @@
        Environment.get_constructor constructor e in
      let%bind expr' = type_expression' e element in
      let%bind _assert = O.assert_type_expression_eq (expr'.type_expression, c_tv) in
      let constructor = convert_constructor' constructor in
      return (E_constructor {constructor; element=expr'}) sum_tv
  (* Record *)
  | E_record m ->
      let aux prev k expr =
        let%bind expr' = type_expression' e expr in
        ok (O.LMap.add (convert_label k) expr' prev)
      in
      let%bind m' = Stage_common.Helpers.bind_fold_lmap aux (ok O.LMap.empty) m in
      (* let () = match tv_opt with
        Some _ -> Format.printf "YES"
       | None -> Format.printf "NO" in *)
      let lmap = O.LMap.map (fun e -> ({field_type = get_type_expression e; michelson_annotation = None; field_decl_pos=0}:O.field_content)) m' in
      return (E_record m') (t_record lmap ())
  | E_record_update {record; path; update} ->
    let path = convert_label path in
    let%bind record = type_expression' e record in
    let%bind update = type_expression' e update in
    let wrapped = get_type_expression record in
    let%bind tv =
      match wrapped.type_content with
      | T_record record -> (
          let field_op = O.LMap.find_opt path record in
          match field_op with
          | Some {field_type;_} -> ok field_type
          | None -> failwith @@ Format.asprintf "field %a is not part of record %a" Ast_typed.PP.label path O.PP.type_expression wrapped
      )
      | _ -> failwith "Update an expression which is not a record"
    in
    let%bind () = O.assert_type_expression_eq (tv, get_type_expression update) in
    return (E_record_update {record; path; update}) wrapped
  (* Data-structure *)
  | E_lambda lambda -> 
   let%bind (lambda, lambda_type) = type_lambda e lambda in
   return (E_lambda lambda ) lambda_type
  | E_constant {cons_name=( C_LIST_FOLD | C_MAP_FOLD | C_SET_FOLD) as opname ;
                arguments=[
                    ( { expression_content = (I.E_lambda { binder = lname ;
                                                   input_type = None ; 
                                                   output_type = None ; 
                                                   result }) ;
                        location = _ }) as _lambda ;
                    collect ; 
                    init_record ;
                  ]} ->
      (* this special case is here force annotation of the untyped lambda
         generated by pascaligo's for_collect loop *)
      let%bind (v_col , v_initr ) = bind_map_pair (type_expression' e) (collect , init_record ) in
      let tv_col = get_type_expression v_col   in (* this is the type of the collection  *)
      let tv_out = get_type_expression v_initr in (* this is the output type of the lambda*)
      let%bind input_type = match tv_col.type_content with
        | O.T_operator ( TC_list t | TC_set t) -> ok @@ make_t_ez_record (("0",tv_out)::[("1",t)])
        | O.T_operator ( TC_map {k;v}| TC_big_map {k;v}) -> ok @@ make_t_ez_record (("0",tv_out)::[("1",make_t_ez_record [("0",k);("1",v)])])
        | _ ->
          let wtype = Format.asprintf
            "Loops over collections expect lists, sets or maps, got type %a" O.PP.type_expression tv_col in 
          fail @@ simple_error wtype in 
      let e' = Environment.add_ez_binder lname input_type e in
      let%bind body = type_expression' ?tv_opt:(Some tv_out) e' result in
      let output_type = body.type_expression in
      let lambda' = make_e (E_lambda {binder = lname ; result=body}) (t_function input_type output_type ()) e' in
      let lst' = [lambda'; v_col; v_initr] in
      let tv_lst = List.map get_type_expression lst' in
      let%bind (opname', tv) =
        type_constant opname tv_lst tv_opt in
      return (E_constant {cons_name=opname';arguments=lst'}) tv
  | E_constant {cons_name=C_FOLD_WHILE as opname;
                arguments = [
                    ( { expression_content = (I.E_lambda { binder = lname ;
                                                   input_type = None ; 
                                                   output_type = None ; 
                                                   result }) ;
                        location = _ }) as _lambda ;
                    init_record ;
                ]} -> 
      let%bind v_initr = type_expression' e init_record in
      let tv_out = get_type_expression v_initr in
      let input_type  = tv_out in
      let e' = Environment.add_ez_binder lname input_type e in
      let%bind body = type_expression' e' result in
      let output_type = body.type_expression in
      let lambda' = make_e (E_lambda {binder = lname ; result=body}) (t_function input_type output_type ()) e' in
      let lst' = [lambda';v_initr] in
      let tv_lst = List.map get_type_expression lst' in
      let%bind (opname',tv) = type_constant opname tv_lst tv_opt in
      return (E_constant {cons_name=opname';arguments=lst'}) tv
  | E_constant {cons_name=C_CREATE_CONTRACT as cons_name;arguments} ->
      let%bind lst' = bind_list @@ List.map (type_expression' e) arguments in
      let%bind () = match lst' with
        | { expression_content = O.E_lambda l ; _ } :: _ ->
          let open Ast_typed.Misc in
          let fvs = Free_variables.lambda [] l in
          if List.length fvs = 0 then ok ()
          else fail @@ fvs_in_create_contract_lambda ae (List.hd fvs)
        | _ -> fail @@ create_contract_lambda C_CREATE_CONTRACT ae
      in
      let tv_lst = List.map get_type_expression lst' in
      let%bind (name', tv) =
        type_constant cons_name tv_lst tv_opt in
      return (E_constant {cons_name=name';arguments=lst'}) tv
  | E_constant {cons_name=C_SET_ADD|C_CONS as cst;arguments=[key;set]} ->
      let%bind key' =  type_expression' e key in
      let tv_key = get_type_expression key' in
      let tv = match tv_opt with 
          Some tv -> tv 
        | None -> match cst with 
            C_SET_ADD -> t_set tv_key ()
          | C_CONS -> t_list tv_key ()
          | _ -> failwith "Only C_SET_ADD and C_CONS are possible because those were the two cases matched above"
      in
      let%bind set' =  type_expression' e ~tv_opt:tv set in
      let tv_set = get_type_expression set' in 
      let tv_lst = [tv_key;tv_set] in
      let%bind (name', tv) = type_constant cst tv_lst tv_opt in
      return (E_constant {cons_name=name';arguments=[key';set']}) tv
  | E_constant {cons_name=C_MAP_ADD as cst; arguments=[key;value;map]} ->
      let%bind key' = type_expression' e key in
      let%bind val' = type_expression' e value in
      let tv_key = get_type_expression key' in
      let tv_val = get_type_expression val' in
      let tv = match tv_opt with 
          Some tv -> tv 
        | None -> t_map_or_big_map tv_key tv_val ()
      in
      let%bind map' =  type_expression' e ~tv_opt:tv map in
      let tv_map = get_type_expression map' in 
      let tv_lst = [tv_key;tv_val;tv_map] in
      let%bind (name', tv) = type_constant cst tv_lst tv_opt in
      return (E_constant {cons_name=name';arguments=[key';val';map']}) tv
  | E_constant {cons_name;arguments} ->
      let%bind lst' = bind_list @@ List.map (type_expression' e) arguments in
      let tv_lst = List.map get_type_expression lst' in
      let%bind (name', tv) =
        type_constant cons_name tv_lst tv_opt in
      return (E_constant {cons_name=name';arguments=lst'}) tv
  | E_application {lamb; args} ->
      let%bind lamb' = type_expression' e lamb in
      let%bind args' = type_expression' e args in
      let%bind tv = match lamb'.type_expression.type_content with
        | T_arrow {type1;type2} ->
            let%bind _ = O.assert_type_expression_eq (type1, args'.type_expression) in
            ok type2
        | _ ->
          fail @@ type_error_approximate
            ~expected:"should be a function type"
            ~expression:lamb
            ~actual:lamb'.type_expression
            lamb'.location
      in
      return (E_application {lamb=lamb'; args=args'}) tv
  (* Advanced *)
  | E_matching {matchee;cases} -> (
      let%bind ex' = type_expression' e matchee in
      let%bind m' = type_match (type_expression' ?tv_opt:None) e ex'.type_expression cases ae ae.location in
      let tvs =
        let aux (cur:O.matching_expr) =
          match cur with
          | Match_list { match_nil ; match_cons = {hd=_ ; tl=_ ; body ; tv=_} } -> [ match_nil ; body ]
          | Match_option { match_none ; match_some = {opt=_ ; body ; tv=_ } } -> [ match_none ; body ]
          | Match_tuple {vars=_;body;tvs=_} -> [ body ]
          | Match_variant {cases; tv=_} -> List.map (fun (c : O.matching_content_case) -> c.body) cases in
        List.map get_type_expression @@ aux m' in
      let aux prec cur =
        let%bind () =
          match prec with
          | None -> ok ()
          | Some cur' -> Ast_typed.assert_type_expression_eq (cur , cur') in
        ok (Some cur) in
      let%bind tv_opt = bind_fold_list aux None tvs in
      let%bind tv =
        trace_option (match_empty_variant cases ae.location) @@
        tv_opt in
      return (O.E_matching {matchee=ex'; cases=m'}) tv
    )
  | E_let_in {let_binder ; rhs ; let_result; inline} ->
    let%bind rhs_tv_opt = bind_map_option (evaluate_type e) (snd let_binder) in
    let%bind rhs = type_expression' ?tv_opt:rhs_tv_opt e rhs in
    let let_binder = fst let_binder in
    let e' = Environment.add_ez_declaration (let_binder) rhs e in
    let%bind let_result = type_expression' e' let_result in
    return (E_let_in {let_binder; rhs; let_result; inline}) let_result.type_expression
  | E_recursive {fun_name; fun_type; lambda} ->
    let%bind fun_type = evaluate_type e fun_type in
    let e' = Environment.add_ez_binder fun_name fun_type e in
    let%bind (lambda,_) = type_lambda e' lambda in
    return (E_recursive {fun_name;fun_type;lambda}) fun_type
  | E_ascription {anno_expr; type_annotation} ->
    let%bind tv = evaluate_type e type_annotation in
    let%bind expr' = type_expression' ~tv_opt:tv e anno_expr in
    let%bind type_annotation =
      O.merge_annotation
        (Some tv)
        (Some expr'.type_expression)
        (internal_assertion_failure "merge_annotations (Some ...) (Some ...) failed") in
    (* check type annotation of the expression as a whole (e.g. let x : t = (v : t') ) *)
    let%bind () =
      match tv_opt with
      | None -> ok ()
      | Some tv' -> O.assert_type_expression_eq (tv' , type_annotation) in
    ok {expr' with type_expression=type_annotation}

and type_lambda e {
      binder ;
      input_type ;
      output_type ;
      result ;
    } = 
      let%bind input_type =
        let%bind input_type =
          (* Hack to take care of let_in introduced by `simplify/cameligo.ml` in ECase's hack *)
          let default_action e () = fail @@ (needs_annotation e "the returned value") in
          match input_type with
          | Some ty -> ok ty
          | None -> (
              match result.expression_content with
              | I.E_let_in li -> (
                  match li.rhs.expression_content with
                  | I.E_variable name when name = (binder) -> (
                      match snd li.let_binder with
                      | Some ty -> ok ty
                      | None -> default_action li.rhs ()
                    )
                  | _ -> default_action li.rhs ()
                )
              | _ -> default_action result ()
            )
        in
        evaluate_type e input_type in
      let%bind output_type =
        bind_map_option (evaluate_type e) output_type
      in
      let e' = Environment.add_ez_binder binder input_type e in
      let%bind body = type_expression' ?tv_opt:output_type e' result in
      let output_type = body.type_expression in
      ok (({binder; result=body}:O.lambda),(t_function input_type output_type ()))



and type_constant (name:I.constant') (lst:O.type_expression list) (tv_opt:O.type_expression option) : (O.constant' * O.type_expression) result =
  let name = convert_constant' name in
  let%bind typer = Operators.Typer.constant_typers name in
  let%bind tv = typer lst tv_opt in
  ok(name, tv)

let untype_type_expression (t:O.type_expression) : (I.type_expression) result =
  match t.type_meta with
  | Some s -> ok s
  | _ -> fail @@ internal_assertion_failure "trying to untype generated type"

let untype_literal (l:O.literal) : I.literal result =
  let open I in
  match l with
  | Literal_unit -> ok Literal_unit
  | Literal_void -> ok Literal_void
  | Literal_nat n -> ok (Literal_nat n)
  | Literal_timestamp n -> ok (Literal_timestamp n)
  | Literal_mutez n -> ok (Literal_mutez n)
  | Literal_int n -> ok (Literal_int n)
  | Literal_string s -> ok (Literal_string s)
  | Literal_signature s -> ok (Literal_signature s)
  | Literal_key s -> ok (Literal_key s)

  | Literal_key_hash s -> ok (Literal_key_hash s)
  | Literal_chain_id s -> ok (Literal_chain_id s)
  | Literal_bytes b -> ok (Literal_bytes b)
  | Literal_address s -> ok (Literal_address s)
  | Literal_operation s -> ok (Literal_operation s)

let rec untype_expression (e:O.expression) : (I.expression) result =
  untype_expression_content e.type_expression e.expression_content
  and untype_expression_content ty (ec:O.expression_content) : (I.expression) result =
  let open I in
  let return e = ok e in
  match ec with
  | E_literal l ->
      let%bind l = untype_literal l in
      return (e_literal l)
  | E_constant {cons_name;arguments} ->
      let%bind lst' = bind_map_list untype_expression arguments in
      return (e_constant (unconvert_constant' cons_name) lst')
  | E_variable n ->
      return (e_variable (n))
  | E_application {lamb;args} ->
      let%bind f' = untype_expression lamb in
      let%bind arg' = untype_expression args in
      return (e_application f' arg')
  | E_lambda {binder ; result} -> (
      let%bind io = get_t_function ty in
      let%bind (input_type , output_type) = bind_map_pair untype_type_expression io in
      let%bind result = untype_expression result in
      return (e_lambda (binder) (Some input_type) (Some output_type) result)
    )
  | E_constructor {constructor; element} ->
      let%bind p' = untype_expression element in
      let Constructor n = constructor in
      return (e_constructor n p')
  | E_record r ->
    let r = O.LMap.to_kv_list r in
    let%bind r' = bind_map_list (fun (O.Label k,e) -> let%bind e = untype_expression e in ok (I.Label k,e)) r in
    return (e_record @@ LMap.of_list r')
  | E_record_accessor {record; path} ->
      let%bind r' = untype_expression record in
      let Label s = path in
      return (e_record_accessor r' s)
  | E_record_update {record=r; path=O.Label l; update=e} ->
    let%bind r' = untype_expression r in
    let%bind e = untype_expression e in 
    return (e_record_update r' (I.Label l) e)
  | E_matching {matchee;cases} ->
      let%bind ae' = untype_expression matchee in
      let%bind m' = untype_matching untype_expression cases in
      return (e_matching ae' m')
  | E_let_in {let_binder;rhs;let_result; inline} ->
      let%bind tv = untype_type_expression rhs.type_expression in
      let%bind rhs = untype_expression rhs in
      let%bind result = untype_expression let_result in
      return (e_let_in (let_binder , (Some tv)) inline rhs result)
  | E_recursive {fun_name;fun_type; lambda} ->
      let%bind fun_type = untype_type_expression fun_type in
      let%bind unty_expr= untype_expression_content ty @@ E_lambda lambda in
      let lambda = match unty_expr.expression_content with I.E_lambda l -> l | _ -> failwith "impossible case" in
      return @@ e_recursive fun_name fun_type lambda

and untype_matching : (O.expression -> I.expression result) -> O.matching_expr -> I.matching_expr result = fun f m ->
  let open I in
  match m with
  | Match_tuple {vars; body;tvs=_} ->
      let%bind b = f body in
      ok @@ I.Match_tuple ((vars, b),[])
  | Match_option {match_none ; match_some = {opt; body ; tv=_}} ->
      let%bind match_none = f match_none in
      let%bind some = f body in
      let match_some = opt, some, () in
      ok @@ Match_option {match_none ; match_some}
  | Match_list {match_nil ; match_cons = {hd ; tl ; body ; tv=_}} ->
      let%bind match_nil = f match_nil in
      let%bind cons = f body in
      let match_cons = hd , tl , cons, () in
      ok @@ Match_list {match_nil ; match_cons}
  | Match_variant {cases;tv=_} ->
      let aux ({constructor;pattern;body} : O.matching_content_case) =
        let%bind c' = f body in
        ok ((unconvert_constructor' constructor,pattern),c') in
      let%bind lst' = bind_map_list aux cases in
      ok @@ Match_variant (lst',())
