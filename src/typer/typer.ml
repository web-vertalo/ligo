open Trace

module I = Ast_simplified
module O = Ast_typed
open O.Combinators

module SMap = O.SMap

module Environment = O.Environment

type environment = Environment.t

module Errors = struct
  let unbound_type_variable (e:environment) (n:string) () =
    let title = (thunk "unbound type variable") in
    let message () = "" in
    let data = [
      ("variable" , fun () -> Format.asprintf "%s" n) ;
      (* TODO: types don't have srclocs for now. *)
      (* ("location" , fun () -> Format.asprintf "%a" Location.pp (n.location)) ; *)
      ("in" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e)
    ] in
    error ~data title message ()

  let unbound_variable (e:environment) (n:string) (loc:Location.t) () =
    let title = (thunk "unbound variable") in
    let message () = "" in
    let data = [
      ("variable" , fun () -> Format.asprintf "%s" n) ;
      ("environment" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let match_empty_variant : type a . a I.matching -> Location.t -> unit -> _ =
    fun matching loc () ->
    let title = (thunk "match with no cases") in
    let message () = "" in
    let data = [
      ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let match_missing_case : type a . a I.matching -> Location.t -> unit -> _ =
    fun matching loc () ->
    let title = (thunk "missing case in match") in
    let message () = "" in
    let data = [
      ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let match_redundant_case : type a . a I.matching -> Location.t -> unit -> _ =
    fun matching loc () ->
    let title = (thunk "missing case in match") in
    let message () = "" in
    let data = [
      ("variant" , fun () -> Format.asprintf "%a" I.PP.matching_type matching) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let unbound_constructor (e:environment) (n:string) (loc:Location.t) () =
    let title = (thunk "unbound constructor") in
    let message () = "" in
    let data = [
      ("constructor" , fun () -> Format.asprintf "%s" n) ;
      ("environment" , fun () -> Format.asprintf "%a" Environment.PP.full_environment e) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let unrecognized_constant (n:string) (loc:Location.t) () =
    let title = (thunk "unrecognized constant") in
    let message () = "" in
    let data = [
      ("constant" , fun () -> Format.asprintf "%s" n) ;
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

  let constant_declaration_error (name:string) (ae:I.expr) (expected: O.type_expression option) () =
    let title = (thunk "typing constant declaration") in
    let message () = "" in
    let data = [
      ("constant" , fun () -> Format.asprintf "%s" name) ;
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("expected" , fun () ->
          match expected with
            None -> "(no annotation for the expected type)"
          | Some expected -> Format.asprintf "%a" O.PP.type_expression expected) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp ae.location)
    ] in
    error ~data title message ()

  let match_error : type a . ?msg:string -> expected: a I.matching -> actual: O.type_expression -> Location.t -> unit -> _ =
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

  let type_error ?(msg="") ~(expected: O.type_expression) ~(actual: O.type_expression) ~(expression : I.expression) (loc:Location.t) () =
    let title = (thunk "type error") in
    let message () = msg in
    let data = [
      ("expected"   , fun () -> Format.asprintf "%a" O.PP.type_expression expected);
      ("actual"     , fun () -> Format.asprintf "%a" O.PP.type_expression actual);
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression expression) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let bad_tuple_index (index : int) (ae : I.expression) (t : O.type_expression) (loc:Location.t) () =
    let title = (thunk "invalid tuple index") in
    let message () = "" in
    let data = [
      ("index" , fun () -> Format.asprintf "%d" index) ;
      ("tuple_value" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("tuple_type" , fun () -> Format.asprintf "%a" O.PP.type_expression t) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let bad_record_access (field : string) (ae : I.expression) (t : O.type_expression) (loc:Location.t) () =
    let title = (thunk "invalid record field") in
    let message () = "" in
    let data = [
      ("field" , fun () -> Format.asprintf "%s" field) ;
      ("record_value" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("tuple_type" , fun () -> Format.asprintf "%a" O.PP.type_expression t) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()

  let not_supported_yet (message : string) (ae : I.expression) () =
    let title = (thunk "not supported yet") in
    let message () = message in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a"  I.PP.expression ae) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp ae.location)
    ] in
    error ~data title message ()

  let not_supported_yet_untranspile (message : string) (ae : O.expression) () =
    let title = (thunk "not supported yet") in
    let message () = message in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a"  O.PP.expression ae)
    ] in
    error ~data title message ()

  let constant_error loc lst tv_opt =
    let title () = "typing constant" in
    let message () = "" in
    let data = [
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc ) ;
      ("argument_types" , fun () -> Format.asprintf "%a" PP_helpers.(list_sep Ast_typed.PP.type_expression (const " , ")) lst) ;
      ("type_opt" , fun () -> Format.asprintf "%a" PP_helpers.(option Ast_typed.PP.type_expression) tv_opt) ;
    ] in
    error ~data title message
end

open Errors
open Solver.Wrap

let rec type_program (p:I.program) : O.program result =
  let env = Ast_typed.Environment.full_empty in
  let state = Solver.initial_state in
  let aux ((e : environment), (s : Solver.state) , (ds : O.declaration Location.wrap list)) (d:I.declaration Location.wrap) =
    let%bind (e' , s' , d'_opt) = type_declaration e s (Location.unwrap d) in
    let ds' = match d'_opt with
      | None -> ds
      | Some d' -> ds @ [Location.wrap ~loc:(Location.get_location d) d']
    in
    ok (e' , s' , ds')
  in
  let%bind (_env' , _state' , declarations) =
    trace (fun () -> program_error p ()) @@
    bind_fold_list aux (env , state , []) p in
  ok declarations

and type_declaration env state : I.declaration -> (environment * Solver.state * O.declaration option) result = function
  | Declaration_type (type_name , type_expression) ->
      let%bind tv = evaluate_type env type_expression in
      let env' = Environment.add_type type_name tv env in
      ok (env', state , None)
  | Declaration_constant (name , tv_opt , expression) -> (
      let%bind tv'_opt = bind_map_option (evaluate_type env) tv_opt in
      let%bind (ae' , state') =
        trace (constant_declaration_error name expression tv'_opt) @@
        type_expression env state expression in
      let env' = Environment.add_ez_ae name ae' env in
      ok (env', state' , Some (O.Declaration_constant ((make_n_e name ae') , (env , env'))))
    )

and type_match : type i o . (environment -> i -> o result) -> environment -> O.type_expression -> i I.matching -> I.expression -> Location.t -> o O.matching result =
  fun f e t i ae loc -> match i with
    | Match_bool {match_true ; match_false} ->
      let%bind _ =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_bool t in
      let%bind match_true = f e match_true in
      let%bind match_false = f e match_false in
      ok (O.Match_bool {match_true ; match_false})
  | Match_option {match_none ; match_some} ->
      let%bind t_opt =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_option t in
      let%bind match_none = f e match_none in
      let (n, b) = match_some in
      let n' = n, t_opt in
      let e' = Environment.add_ez_binder n t_opt e in
      let%bind b' = f e' b in
      ok (O.Match_option {match_none ; match_some = (n', b')})
  | Match_list {match_nil ; match_cons} ->
      let%bind t_list =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_list t in
      let%bind match_nil = f e match_nil in
      let (hd, tl, b) = match_cons in
      let e' = Environment.add_ez_binder hd t_list e in
      let e' = Environment.add_ez_binder tl t e' in
      let%bind b' = f e' b in
      ok (O.Match_list {match_nil ; match_cons = (hd, tl, b')})
  | Match_tuple (lst, b) ->
      let%bind t_tuple =
        trace_strong (match_error ~expected:i ~actual:t loc)
        @@ get_t_tuple t in
      let%bind lst' =
        generic_try (match_tuple_wrong_arity t_tuple lst loc)
        @@ (fun () -> List.combine lst t_tuple) in
      let aux prev (name, tv) = Environment.add_ez_binder name tv prev in
      let e' = List.fold_left aux e lst' in
      let%bind b' = f e' b in
      ok (O.Match_tuple (lst, b'))
  | Match_variant lst ->
      let%bind variant_opt =
        let aux acc ((constructor_name , _) , _) =
          let%bind (_ , variant) =
            trace_option (unbound_constructor e constructor_name loc) @@
            Environment.get_constructor constructor_name e in
          let%bind acc = match acc with
            | None -> ok (Some variant)
            | Some variant' -> (
                trace (type_error
                         ~msg:"in match variant"
                         ~expected:variant
                         ~actual:variant'
                         ~expression:ae
                         loc
                      ) @@
                Ast_typed.assert_type_expression_eq (variant , variant') >>? fun () ->
                ok (Some variant)
              ) in
          ok acc in
        trace (simple_info "in match variant") @@
        bind_fold_list aux None lst in
      let%bind variant =
        trace_option (match_empty_variant i loc) @@
        variant_opt in
      let%bind () =
        let%bind variant_cases' =
          trace (match_error ~expected:i ~actual:t loc)
          @@ Ast_typed.Combinators.get_t_sum variant in
        let variant_cases = List.map fst @@ Map.String.to_kv_list variant_cases' in
        let match_cases = List.map (Function.compose fst fst) lst in
        let test_case = fun c ->
          Assert.assert_true (List.mem c match_cases)
        in
        let%bind () =
          trace_strong (match_missing_case i loc) @@
          bind_iter_list test_case variant_cases in
        let%bind () =
          trace_strong (match_redundant_case i loc) @@
          Assert.assert_true List.(length variant_cases = length match_cases) in
        ok ()
      in
      let%bind lst' =
        let aux ((constructor_name , name) , b) =
          let%bind (constructor , _) =
            trace_option (unbound_constructor e constructor_name loc) @@
            Environment.get_constructor constructor_name e in
          let e' = Environment.add_ez_binder name constructor e in
          let%bind b' = f e' b in
          ok ((constructor_name , name) , b')
        in
        bind_map_list aux lst in
      ok (O.Match_variant (lst' , variant))

and evaluate_type (e:environment) (t:I.type_expression) : O.type_expression result =
  let return tv' = ok (make_t tv' (Some t)) in
  match t.type_expression' with
  | T_function (a, b) ->
      let%bind a' = evaluate_type e a in
      let%bind b' = evaluate_type e b in
      return (T_function (a', b'))
  | T_tuple lst ->
      let%bind lst' = bind_list @@ List.map (evaluate_type e) lst in
      return (T_tuple lst')
  | T_sum m ->
      let aux k v prev =
        let%bind prev' = prev in
        let%bind v' = evaluate_type e v in
        ok @@ SMap.add k v' prev'
      in
      let%bind m = SMap.fold aux m (ok SMap.empty) in
      return (T_sum m)
  | T_record m ->
      let aux k v prev =
        let%bind prev' = prev in
        let%bind v' = evaluate_type e v in
        ok @@ SMap.add k v' prev'
      in
      let%bind m = SMap.fold aux m (ok SMap.empty) in
      return (T_record m)
  | T_variable name ->
      let%bind tv =
        trace_option (unbound_type_variable e name)
        @@ Environment.get_type_opt name e in
      ok tv
  | T_constant (cst, lst) ->
      let%bind lst' = bind_list @@ List.map (evaluate_type e) lst in
      return (T_constant(cst, lst'))

and type_expression : environment -> Solver.state -> I.expression -> (O.annotated_expression * Solver.state) result = fun e state ae ->
  let open Solver in
  let type_name = Core.fresh_type_variable () in
  let module L = Logger.Stateful() in
  let return : _ -> Solver.state -> _ = fun expr state ->
    let tv = t_variable type_name () in
    let location = ae.location in
    let expr' = make_a_e ~location expr tv e in
    ok @@ (expr' , state) in
  let add_type state t =
    let constraints = Wrap.variable type_name t in
    let%bind state' = aggregate_constraints state constraints in
    ok state' in
  let return_add_type ?(state = state) expr t =
    let%bind state' = add_type state t in
    return expr state' in
  let main_error =
    let title () = "typing expression" in
    let content () = "" in
    let data = [
      ("expression" , fun () -> Format.asprintf "%a" I.PP.expression ae) ;
      ("location" , fun () -> Format.asprintf "%a" Location.pp @@ ae.location) ;
      ("misc" , fun () -> L.get ()) ;
    ] in
    error ~data title content in
  trace main_error @@
  match ae.expression' with
  (* Basic *)
  | E_failwith _ -> fail @@ needs_annotation ae "the failwith keyword"
  | E_variable name -> (
      let%bind tv' =
        trace_option (unbound_variable e name ae.location)
        @@ Environment.get_opt name e in
      return_add_type (e_variable name) tv'.type_expression
    )
  | E_literal (Literal_bool b) -> (
      return_add_type (e_bool b) (t_bool ())
    )
  | E_literal (Literal_string b) -> (
      return_add_type (e_string b) (t_string ())
    )
  | E_literal (Literal_bytes b) -> (
      return_add_type (e_bytes b) (t_bytes ())
    )
  | E_literal (Literal_int b) -> (
      return_add_type (e_int b) (t_int ())
    )
  | E_literal (Literal_nat b) -> (
      return_add_type (e_nat b) (t_nat ())
    )
  | E_literal (Literal_tez b) -> (
      return_add_type (e_tez b) (t_tez ())
    )
  | E_literal (Literal_address b) -> (
      return_add_type (e_address b) (t_address ())
    )
  | E_literal (Literal_timestamp b) -> (
      return_add_type (e_timestamp b) (t_timestamp ())
    )
  | E_literal (Literal_operation b) -> (
      return_add_type (e_operation b) (t_operation ())
    )
  | E_literal Literal_unit | E_skip -> (
      return_add_type (e_unit) (t_unit ())
    )
  (* | E_literal (Literal_string s) -> (
   *     L.log (Format.asprintf "literal_string option type: %a" PP_helpers.(option O.PP.type_expression) tv_opt) ;
   *     match Option.map Ast_typed.get_type' tv_opt with
   *     | Some (T_constant ("address" , [])) -> return (E_literal (Literal_address s)) (t_address ())
   *     | _ -> return (E_literal (Literal_string s)) (t_string ())
   *   ) *)
  (* Tuple *)
  | E_tuple lst -> (
      let aux (exprs , state) cur =
        let%bind (expr' , state') = type_expression e state cur in
        let exprs' = exprs @ [expr'] in
        ok (exprs' , state')
      in
      let%bind (lst' , state') = bind_fold_list aux ([] , state) lst in
      let tv_lst = List.map get_type_annotation lst' in
      return_add_type ~state:state' (E_tuple lst') (t_tuple tv_lst ())
    )
  | E_accessor (base, access) -> (
      let%bind (base' , state') = type_expression e state base in
      match access with
      | Access_tuple index -> (
          let constraints = Wrap.access_int ~base:base'.type_annotation ~index in
          let%bind state' = aggregate_constraints state' constraints in
          return (E_tuple_accessor (base' , index)) state'
        )
      | Access_record property -> (
          let constraints = Wrap.access_string ~base:base'.type_annotation ~property in
          let%bind state' = aggregate_constraints state' constraints in
          return (E_record_accessor (base' , property)) state'
        )
      | Access_map ae' -> (
          let%bind ae'' = type_expression e ae' in
          let%bind (k , v) = get_t_map prev.type_annotation in
          let%bind () =
            Ast_typed.assert_type_expression_eq (k , get_type_annotation ae'') in
          return (E_look_up (prev , ae'')) v
        )
    )
  (* Sum *)
  | E_constructor (c, expr) ->
      let%bind (c_tv, sum_tv) =
        let error =
          let title () = "no such constructor" in
          let content () =
            Format.asprintf "%s in:\n%a\n"
              c O.Environment.PP.full_environment e
          in
          error title content in
        trace_option error @@
        Environment.get_constructor c e in
      let%bind expr' = type_expression e expr in
      let%bind _assert = O.assert_type_expression_eq (expr'.type_annotation, c_tv) in
      return (E_constructor (c , expr')) sum_tv
  (* Record *)
  | E_record m ->
      let aux prev k expr =
        let%bind expr' = type_expression e expr in
        ok (SMap.add k expr' prev)
      in
      let%bind m' = bind_fold_smap aux (ok SMap.empty) m in
      return (E_record m') (t_record (SMap.map get_type_annotation m') ())
  (* Data-structure *)
  | E_list lst ->
      let%bind lst' = bind_map_list (type_expression e) lst in
      let%bind tv =
        let aux opt c =
          match opt with
          | None -> ok (Some c)
          | Some c' ->
              let%bind _eq = Ast_typed.assert_type_expression_eq (c, c') in
              ok (Some c') in
        let%bind init = match tv_opt with
          | None -> ok None
          | Some ty ->
              let%bind ty' = get_t_list ty in
              ok (Some ty') in
        let%bind ty =
          let%bind opt = bind_fold_list aux init
          @@ List.map get_type_annotation lst' in
          trace_option (needs_annotation ae "empty list") opt in
        ok (t_list ty ())
      in
      return (E_list lst') tv
  | E_set lst ->
      let%bind lst' = bind_map_list (type_expression e) lst in
      let%bind tv =
        let aux opt c =
          match opt with
          | None -> ok (Some c)
          | Some c' ->
              let%bind _eq = Ast_typed.assert_type_expression_eq (c, c') in
              ok (Some c') in
        let%bind init = match tv_opt with
          | None -> ok None
          | Some ty ->
              let%bind ty' = get_t_set ty in
              ok (Some ty') in
        let%bind ty =
          let%bind opt = bind_fold_list aux init
          @@ List.map get_type_annotation lst' in
          trace_option (needs_annotation ae "empty set") opt in
        ok (t_set ty ())
      in
      return (E_set lst') tv
  | E_map lst ->
      let%bind lst' = bind_map_list (bind_map_pair (type_expression e)) lst in
      let%bind tv =
        let aux opt c =
          match opt with
          | None -> ok (Some c)
          | Some c' ->
              let%bind _eq = Ast_typed.assert_type_expression_eq (c, c') in
              ok (Some c') in
        let%bind key_type =
          let%bind sub =
            bind_fold_list aux None
            @@ List.map get_type_annotation
            @@ List.map fst lst' in
          let%bind annot = bind_map_option get_t_map_key tv_opt in
          trace (simple_info "empty map expression without a type annotation") @@
          O.merge_annotation annot sub (needs_annotation ae "this map literal")
        in
        let%bind value_type =
          let%bind sub =
            bind_fold_list aux None
            @@ List.map get_type_annotation
            @@ List.map snd lst' in
          let%bind annot = bind_map_option get_t_map_value tv_opt in
          trace (simple_info "empty map expression without a type annotation") @@
          O.merge_annotation annot sub (needs_annotation ae "this map literal")
        in
        ok (t_map key_type value_type ())
      in
      return (E_map lst') tv
  | E_lambda {
      binder ;
      input_type ;
      output_type ;
      result ;
    } -> (
      let%bind input_type =
        let%bind input_type =
          (* Hack to take care of let_in introduced by `simplify/ligodity.ml` in ECase's hack *)
          let default_action e () = fail @@ (needs_annotation e "the returned value") in
          match input_type with
          | Some ty -> ok ty
          | None -> (
              match Location.unwrap result with
              | I.E_let_in li -> (
                  match Location.unwrap li.rhs with
                  | I.E_variable name when name = (fst binder) -> (
                      match snd li.binder with
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
      let e' = Environment.add_ez_binder (fst binder) input_type e in
      let%bind result = type_expression ?tv_opt:output_type e' result in
      let output_type = result.type_annotation in
      return (E_lambda {binder = fst binder;input_type;output_type;result}) (t_function input_type output_type ())
    )
  | E_constant (name, lst) ->
      let%bind lst' = bind_list @@ List.map (type_expression e) lst in
      let tv_lst = List.map get_type_annotation lst' in
      let%bind (name', tv) =
        type_constant name tv_lst tv_opt ae.location in
      return (E_constant (name' , lst')) tv
  | E_application (f, arg) ->
      let%bind f' = type_expression e f in
      let%bind arg = type_expression e arg in
      let%bind tv = match f'.type_annotation.type_expression' with
        | T_function (param, result) ->
            let%bind _ = O.assert_type_expression_eq (param, arg.type_annotation) in
            ok result
        | _ ->
          fail @@ type_error_approximate
            ~expected:"should be a function type"
            ~expression:f
            ~actual:f'.type_annotation
            f'.location
      in
      return (E_application (f' , arg)) tv
  | E_look_up dsi ->
      let%bind (ds, ind) = bind_map_pair (type_expression e) dsi in
      let%bind (src, dst) = get_t_map ds.type_annotation in
      let%bind _ = O.assert_type_expression_eq (ind.type_annotation, src) in
      return (E_look_up (ds , ind)) (t_option dst ())
  (* Advanced *)
  | E_matching (ex, m) -> (
      let%bind ex' = type_expression e ex in
      match m with
      (* Special case for assert-like failwiths. TODO: CLEAN THIS. *)
      | I.Match_bool { match_false ; match_true } when I.is_e_failwith match_true -> (
          let%bind fw = I.get_e_failwith match_true in
          let%bind fw' = type_expression e fw in
          let%bind mf' = type_expression e match_false in
          let t = get_type_annotation ex' in
          let%bind () =
            trace_strong (match_error ~expected:m ~actual:t ae.location)
            @@ assert_t_bool t in
          let%bind () =
            trace_strong (match_error
                            ~msg:"matching not-unit on an assert"
                            ~expected:m
                            ~actual:t
                            ae.location)
            @@ assert_t_unit (get_type_annotation mf') in
          let mt' = make_a_e
              (E_constant ("ASSERT_INFERRED" , [ex' ; fw']))
              (t_unit ())
              e
          in
          let m' = O.Match_bool { match_true = mt' ; match_false = mf' } in
          return (O.E_matching (ex' , m')) (t_unit ())
        )
      | _ -> (
          let%bind m' = type_match (type_expression ?tv_opt:None) e ex'.type_annotation m ae ae.location in
          let tvs =
            let aux (cur:O.value O.matching) =
              match cur with
              | Match_bool { match_true ; match_false } -> [ match_true ; match_false ]
              | Match_list { match_nil ; match_cons = (_ , _ , match_cons) } -> [ match_nil ; match_cons ]
              | Match_option { match_none ; match_some = (_ , match_some) } -> [ match_none ; match_some ]
              | Match_tuple (_ , match_tuple) -> [ match_tuple ]
              | Match_variant (lst , _) -> List.map snd lst in
            List.map get_type_annotation @@ aux m' in
          let aux prec cur =
            let%bind () =
              match prec with
              | None -> ok ()
              | Some cur' -> Ast_typed.assert_type_expression_eq (cur , cur') in
            ok (Some cur) in
          let%bind tv_opt = bind_fold_list aux None tvs in
          let%bind tv =
            trace_option (match_empty_variant m ae.location) @@
            tv_opt in
          return (O.E_matching (ex', m')) tv
        )
    )
  | E_sequence (a , b) ->
    let%bind a' = type_expression e a in
    let%bind b' = type_expression e b in
    let a'_type_annot = get_type_annotation a' in
    let%bind () =
      trace_strong (type_error
                      ~msg:"first part of the sequence should be of unit type"
                      ~expected:(O.t_unit ())
                      ~actual:a'_type_annot
                      ~expression:a
                      a'.location) @@
      Ast_typed.assert_type_expression_eq (t_unit () , a'_type_annot) in
    return (O.E_sequence (a' , b')) (get_type_annotation b')
  | E_loop (expr , body) ->
    let%bind expr' = type_expression e expr in
    let%bind body' = type_expression e body in
    let t_expr' = get_type_annotation expr' in
    let%bind () =
      trace_strong (type_error
                      ~msg:"while condition isn't of type bool"
                      ~expected:(O.t_bool ())
                      ~actual:t_expr'
                      ~expression:expr
                      expr'.location) @@
      Ast_typed.assert_type_expression_eq (t_bool () , t_expr') in
    let t_body' = get_type_annotation body' in
    let%bind () =
      trace_strong (type_error
                     ~msg:"while body isn't of unit type"
                     ~expected:(O.t_unit ())
                     ~actual:t_body'
                     ~expression:body
                     body'.location) @@
      Ast_typed.assert_type_expression_eq (t_unit () , t_body') in
    return (O.E_loop (expr' , body')) (t_unit ())
  | E_assign (name , path , expr) ->
    let%bind typed_name =
      let%bind ele = Environment.get_trace name e in
      ok @@ make_n_t name ele.type_expression in
    let%bind (assign_tv , path') =
      let aux : ((_ * O.access_path) as 'a) -> I.access -> 'a result = fun (prec_tv , prec_path) cur_path ->
        match cur_path with
        | Access_tuple index -> (
            let%bind tpl = get_t_tuple prec_tv in
            let%bind tv' =
              trace_option (bad_tuple_index index ae prec_tv ae.location) @@
              List.nth_opt tpl index in
            ok (tv' , prec_path @ [O.Access_tuple index])
          )
        | Access_record property -> (
            let%bind m = get_t_record prec_tv in
            let%bind tv' =
              trace_option (bad_record_access property ae prec_tv ae.location) @@
              Map.String.find_opt property m in
            ok (tv' , prec_path @ [O.Access_record property])
          )
        | Access_map _ ->
          fail @@ not_supported_yet "assign expressions with maps are not supported yet" ae
      in
      bind_fold_list aux (typed_name.type_expression , []) path in
    let%bind expr' = type_expression e expr in
    let t_expr' = get_type_annotation expr' in
    let%bind () =
      trace_strong (type_error
                     ~msg:"type of the expression to assign doesn't match left-hand-side"
                     ~expected:assign_tv
                     ~actual:t_expr'
                     ~expression:expr
                     expr'.location) @@
      Ast_typed.assert_type_expression_eq (assign_tv , t_expr') in
    return (O.E_assign (typed_name , path' , expr')) (t_unit ())
  | E_let_in {binder ; rhs ; result} ->
    let%bind rhs_tv_opt = bind_map_option (evaluate_type e) (snd binder) in
    let%bind rhs = type_expression ?tv_opt:rhs_tv_opt e rhs in
    let e' = Environment.add_ez_declaration (fst binder) rhs e in
    let%bind result = type_expression e' result in
    return (E_let_in {binder = fst binder; rhs; result}) result.type_annotation
  | E_annotation (expr , te) ->
    let%bind tv = evaluate_type e te in
    let%bind expr' = type_expression ~tv_opt:tv e expr in
    let%bind type_annotation =
      O.merge_annotation
        (Some tv)
        (Some expr'.type_annotation)
        (internal_assertion_failure "merge_annotations (Some ...) (Some ...) failed") in
    ok {expr' with type_annotation}


and type_constant (name:string) (lst:O.type_expression list) (tv_opt:O.type_expression option) (loc : Location.t) : (string * O.type_expression) result =
  (* Constant poorman's polymorphism *)
  let ct = Operators.Typer.constant_typers in
  let%bind typer =
    trace_option (unrecognized_constant name loc) @@
    Map.String.find_opt name ct in
  trace (constant_error loc lst tv_opt) @@
  typer lst tv_opt

let type_statement : I.declaration -> Solver.state -> Solver.state result = fun declaration state ->
  match declaration with
  | I.Declaration_type td -> (
      let constraints = type_declaration td in
      Solver.aggregate_constraints state constraints
    )
  | I.Declaration_constant ((_ , _ , expr) as cd) -> (
      let%bind state' = type_expression expr in
      let constraints = constant_declaration cd in
      Solver.aggregate_constraints state' constraints
    )

let rec type_program : I.program -> O.program result = fun p ->
  let initial_state = Solver.initial_state in
  let aux prec statement =
    let (prec_statements , prec_state) = prec in
    let%bind (statement' , state) = type_statement statement prec_state in
    let statements = prec_statements @ statement' in
    ok (state , statements) in
  let%bind (statements , final_state) = bind_fold_list aux ([] , initial_state) p in
  ignore final_state ;
  ok statements


let untype_type_expression (t:O.type_expression) : (I.type_expression) result =
  match t.simplified with
  | Some s -> ok s
  | _ -> fail @@ internal_assertion_failure "trying to untype generated type"

let untype_literal (l:O.literal) : I.literal result =
  let open I in
  match l with
  | Literal_unit -> ok Literal_unit
  | Literal_bool b -> ok (Literal_bool b)
  | Literal_nat n -> ok (Literal_nat n)
  | Literal_timestamp n -> ok (Literal_timestamp n)
  | Literal_tez n -> ok (Literal_tez n)
  | Literal_int n -> ok (Literal_int n)
  | Literal_string s -> ok (Literal_string s)
  | Literal_bytes b -> ok (Literal_bytes b)
  | Literal_address s -> ok (Literal_address s)
  | Literal_operation s -> ok (Literal_operation s)

let rec untype_expression (e:O.annotated_expression) : (I.expression) result =
  let open I in
  let return e = ok e in
  match e.expression with
  | E_literal l ->
      let%bind l = untype_literal l in
      return (e_literal l)
  | E_constant (n, lst) ->
      let%bind lst' = bind_map_list untype_expression lst in
      return (e_constant n lst')
  | E_variable n ->
      return (e_variable n)
  | E_application (f, arg) ->
      let%bind f' = untype_expression f in
      let%bind arg' = untype_expression arg in
      return (e_application f' arg')
  | E_lambda {binder;input_type;output_type;result} ->
      let%bind input_type = untype_type_expression input_type in
      let%bind output_type = untype_type_expression output_type in
      let%bind result = untype_expression result in
      return (e_lambda binder (Some input_type) (Some output_type) result)
  | E_tuple lst ->
      let%bind lst' = bind_list
        @@ List.map untype_expression lst in
      return (e_tuple lst')
  | E_tuple_accessor (tpl, ind)  ->
      let%bind tpl' = untype_expression tpl in
      return (e_accessor tpl' [Access_tuple ind])
  | E_constructor (n, p) ->
      let%bind p' = untype_expression p in
      return (e_constructor n p')
  | E_record r ->
      let%bind r' = bind_smap
        @@ SMap.map untype_expression r in
      return (e_record r')
  | E_record_accessor (r, s) ->
      let%bind r' = untype_expression r in
      return (e_accessor r' [Access_record s])
  | E_map m ->
      let%bind m' = bind_map_list (bind_map_pair untype_expression) m in
      return (e_map m')
  | E_list lst ->
      let%bind lst' = bind_map_list untype_expression lst in
      return (e_list lst')
  | E_set lst ->
      let%bind lst' = bind_map_list untype_expression lst in
      return (e_set lst')
  | E_look_up dsi ->
      let%bind (a , b) = bind_map_pair untype_expression dsi in
      return (e_look_up a b)
  | E_matching (ae, m) ->
      let%bind ae' = untype_expression ae in
      let%bind m' = untype_matching untype_expression m in
      return (e_matching ae' m')
  | E_failwith ae ->
      let%bind ae' = untype_expression ae in
      return (e_failwith ae')
  | E_sequence _
  | E_loop _
  | E_assign _ -> fail @@ not_supported_yet_untranspile "not possible to untranspile statements yet" e.expression
  | E_let_in {binder;rhs;result} ->
      let%bind tv = untype_type_expression rhs.type_annotation in
      let%bind rhs = untype_expression rhs in
      let%bind result = untype_expression result in
      return (e_let_in (binder , (Some tv)) rhs result)

and untype_matching : type o i . (o -> i result) -> o O.matching -> (i I.matching) result = fun f m ->
  let open I in
  match m with
  | Match_bool {match_true ; match_false} ->
      let%bind match_true = f match_true in
      let%bind match_false = f match_false in
      ok @@ Match_bool {match_true ; match_false}
  | Match_tuple (lst, b) ->
      let%bind b = f b in
      ok @@ Match_tuple (lst, b)
  | Match_option {match_none ; match_some = (v, some)} ->
      let%bind match_none = f match_none in
      let%bind some = f some in
      let match_some = fst v, some in
      ok @@ Match_option {match_none ; match_some}
  | Match_list {match_nil ; match_cons = (hd, tl, cons)} ->
      let%bind match_nil = f match_nil in
      let%bind cons = f cons in
      let match_cons = hd, tl, cons in
      ok @@ Match_list {match_nil ; match_cons}
  | Match_variant (lst , _) ->
      let aux ((a,b),c) =
        let%bind c' = f c in
        ok ((a,b),c') in
      let%bind lst' = bind_map_list aux lst in
      ok @@ Match_variant lst'
