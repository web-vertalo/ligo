open Proto_alpha_utils.Memory_proto_alpha
open Protocol
open Trace

module LT = Ligo_interpreter.Types
module Mini_proto = Ligo_interpreter.Mini_proto
module Int_repr = Ligo_interpreter.Int_repr_copied

(* type context = Proto_alpha_utils.Memory_proto_alpha.options *)
type context = Ligo_interpreter.Mini_proto.t
type execution_trace = unit
type 'a result_monad = ('a,Errors.interpreter_error) result


module Command = struct
  type 'a t =
    | Fail_overflow : Location.t -> 'a t
    | Fail_reject : Location.t * LT.value -> 'a t
    | Chain_id : bytes t
    | Self : LT.value t
    | Get_script : string -> (LT.value * LT.value) option t
    | Get_contract : string -> LT.value option t
    | External_call : string * LT.Tez.t -> unit t
    | Internal_call : string * LT.Tez.t -> unit t
    | Update_storage : string * LT.value -> unit t
    | Get_storage : string -> LT.value t
    | Inject_script : string * LT.value * LT.value -> unit t
    | Set_now : Z.t -> unit t
    | Set_source : string -> unit t
    | Set_balance : string * LT.Tez.t -> unit t
    | Parse_contract_for_script : Alpha_context.Contract.t * string -> unit t
    | Now : Z.t t
    | Amount : LT.Tez.t t
    | Balance : LT.Tez.t t
    | Sender : string t
    | Source : string t
    | Serialize_pack_data : 'a -> 'a t
    | Serialize_unpack_data : 'a -> 'a t
    | Lift_tz_result : 'a Memory_proto_alpha.Alpha_environment.Error_monad.tzresult -> 'a t
    | Tez_compare_wrapped : LT.Tez.t * LT.Tez.t -> int t
    | Int_compare_wrapped : 'a Int_repr.num * 'a Int_repr.num -> int t
    | Int_compare : 'a Int_repr.num * 'a Int_repr.num -> int t
    | Int_abs : Int_repr.z Int_repr.num -> Int_repr.n Int_repr.num t
    | Int_of_zint : Z.t -> Int_repr.z Int_repr.num t
    | Int_to_zint : 'a Int_repr.num -> Z.t t
    | Int_of_int64 : int64 -> Int_repr.z Int_repr.num t
    | Int_to_int64 : _ Int_repr.num -> int64 option t
    | Int_is_nat : Int_repr.z Int_repr.num -> Int_repr.n Int_repr.num option t
    | Int_neg : _ Int_repr.num -> Int_repr.z Int_repr.num t
    | Int_add : _ Int_repr.num * _ Int_repr.num -> Int_repr.z Int_repr.num t
    | Int_add_n : Int_repr.n Int_repr.num * Int_repr.n Int_repr.num -> Int_repr.n Int_repr.num t
    | Int_mul : _ Int_repr.num * _ Int_repr.num -> Int_repr.z Int_repr.num t
    | Int_mul_n : Int_repr.n Int_repr.num * Int_repr.n Int_repr.num -> Int_repr.n Int_repr.num t
    | Int_ediv :
      _ Int_repr.num * _ Int_repr.num ->
      (Int_repr.z Int_repr.num * Int_repr.n Int_repr.num) option t
    | Int_ediv_n :
      Int_repr.n Int_repr.num * Int_repr.n Int_repr.num ->
      (Int_repr.n Int_repr.num * Int_repr.n Int_repr.num) option t
    | Int_sub : _ Int_repr.num * _ Int_repr.num -> Int_repr.z Int_repr.num t
    | Int_shift_left : 'a Int_repr.num * Int_repr.n Int_repr.num -> 'a Int_repr.num option t
    | Int_shift_right : 'a Int_repr.num * Int_repr.n Int_repr.num -> 'a Int_repr.num option t
    | Int_logor : ('a Int_repr.num * 'a Int_repr.num) -> 'a Int_repr.num t
    | Int_logand : (_ Int_repr.num * Int_repr.n Int_repr.num) -> Int_repr.n Int_repr.num t
    | Int_logxor : (Int_repr.n Int_repr.num * Int_repr.n Int_repr.num) -> Int_repr.n Int_repr.num t
    | Int_lognot : _ Int_repr.num -> Int_repr.z Int_repr.num t
    | Int_of_int : int -> Int_repr.z Int_repr.num t
    | Int_int : Int_repr.n Int_repr.num -> Int_repr.z Int_repr.num t

  let eval
    : type a.
      a t ->
      context ->
      execution_trace ref option ->
      (a * context) result_monad
    = fun command ctxt _log ->
    (* let get_log (log : execution_trace ref option) =
      match log with
      | Some x -> Some !x
      | None -> None in *)
    match command with
    | Fail_overflow location ->
      fail (`Ligo_interpret_overflow location)
    | Fail_reject (location, e) ->
      fail (`Ligo_interpret_reject (location,e))
    | Chain_id ->
      ok (ctxt.step_constants.chain_id, ctxt)
    | Self ->
      let self = Alpha_context.Contract.to_b58check ctxt.step_constants.self in
      ok (LT.V_Ct (LT.C_address self), ctxt)
    | Get_script addr ->
      let contract = Mini_proto.StateMap.find_opt (Address addr) ctxt.contracts in
      let res = match contract with
        | Some contract -> Some (contract.script.code, contract.script.storage)
        | None -> None
      in
      ok (res, ctxt)
    | Get_contract addr ->
      let exists = Mini_proto.StateMap.mem (Address addr) ctxt.contracts in
      if exists then
        ok @@ (Some (LT.V_Ct (LT.C_address addr)), ctxt)
      else
        ok @@ (None, ctxt)
    | External_call (addr, amt) ->
      let aux : Mini_proto.state option -> Mini_proto.state option = fun state_opt ->
        match state_opt with
        | Some state ->
          let script_balance =
            Proto_alpha_utils.Trace.trace_alpha_tzresult (fun _ -> `TODO) @@
            LT.Tez.(state.script_balance +? amt) in
          let script_balance = match script_balance with Ok (x,_) -> x | Error _ -> failwith "TODO" in
          Some { state with script_balance }
        | None -> failwith "EXTERNAL CALL DESTINATION UNKNOWN" (* TODO *)
      in
      let contracts = Mini_proto.StateMap.update (Address addr) aux ctxt.contracts in
      let contract = Mini_proto.StateMap.find (Address addr) contracts in
      let step_constants = { ctxt.step_constants with payer = ctxt.step_constants.source ; balance = contract.script_balance} in
      let ctxt : Mini_proto.t = { contracts ; step_constants } in
      ok ( (), ctxt)
    | Internal_call (addr, amt) ->
      let aux : Mini_proto.state option -> Mini_proto.state option = fun state_opt ->
        match state_opt with
        | Some state ->
          let script_balance =
            Proto_alpha_utils.Trace.trace_alpha_tzresult (fun _ -> `TODO) @@
            LT.Tez.(state.script_balance +? amt) in
          let script_balance = match script_balance with Ok (x,_) -> x | Error _ -> failwith "TODO" in
          Some { state with script_balance }
        | None -> failwith "EXTERNAL CALL DESTINATION UNKNOWN" (* TODO *)
      in
      let contracts = Mini_proto.StateMap.update (Address addr) aux ctxt.contracts in
      let contract = Mini_proto.StateMap.find (Address addr) contracts in
      let step_constants = { ctxt.step_constants with source = ctxt.step_constants.self ; balance = contract.script_balance} in
      let ctxt : Mini_proto.t = { contracts ; step_constants } in
      ok ( (), ctxt)
    | Update_storage (addr, storage) ->
      let aux : Mini_proto.state option -> Mini_proto.state option = fun state_opt ->
        match state_opt with
        | Some state ->
          let script = { state.script with storage } in
          Some { state with script }
        | None -> failwith "ADDR NOT REGISTERED" (* TODO *)
      in
      let contracts = Mini_proto.StateMap.update (Address addr) aux ctxt.contracts in
      ok ((), {ctxt with contracts})
    | Get_storage addr ->
      let storage = Mini_proto.StateMap.find (Address addr) ctxt.contracts in
      ok (storage.script.storage, ctxt)
    | Inject_script (addr, code, storage) ->
      let script : Mini_proto.script = { code ; storage } in
      let contracts : Mini_proto.state = {script ; script_balance = Alpha_context.Tez.zero } in
      let contracts = Mini_proto.StateMap.add (Address addr) contracts ctxt.contracts in
      ok ((), { ctxt with contracts})
    | Set_now now ->
      let now = Alpha_context.Script_timestamp.of_zint now in
      ok ((), { ctxt with step_constants = { ctxt.step_constants with now } })
    | Set_source source ->
      let%bind source =
        Proto_alpha_utils.Trace.trace_alpha_tzresult (fun _ -> `TODO) @@
        Alpha_context.Contract.of_b58check source in
      ok ((), { ctxt with step_constants = { ctxt.step_constants with source } })
    | Set_balance (addr, amt) ->
      let aux : Mini_proto.state option -> Mini_proto.state option = fun contracts_opt ->
        match contracts_opt with
        | Some contracts -> Some { contracts with script_balance = amt }
        | None -> None
      in
      let contracts = Mini_proto.StateMap.update (Address addr) aux ctxt.contracts in
      ok ((), {ctxt with contracts})
    | Now -> ok (LT.Timestamp.to_zint ctxt.step_constants.now, ctxt)
    | Amount -> ok (ctxt.step_constants.amount, ctxt)
    | Balance -> ok (ctxt.step_constants.balance, ctxt)
    | Sender -> ok (Alpha_context.Contract.to_b58check ctxt.step_constants.payer, ctxt)
    | Source -> ok (Alpha_context.Contract.to_b58check ctxt.step_constants.source, ctxt)
    | Serialize_pack_data v -> ok (v,ctxt)
    | Serialize_unpack_data v -> ok (v,ctxt)
    | Parse_contract_for_script _ -> Trace.fail `TODO
    | Tez_compare_wrapped (x, y) ->
      ok (Memory_proto_alpha.Protocol.Script_ir_translator.wrap_compare LT.Tez.compare x y, ctxt)
    | Int_compare_wrapped (x, y) ->
      ok (Memory_proto_alpha.Protocol.Script_ir_translator.wrap_compare Int_repr.compare x y, ctxt)
    | Int_compare (x, y) -> ok (Int_repr.compare x y, ctxt)
    | Int_abs z -> ok (Int_repr.abs z, ctxt)
    | Int_of_int i -> ok (Int_repr.of_int i, ctxt)
    | Int_of_zint z -> ok (Int_repr.of_zint z, ctxt)
    | Int_to_zint z -> ok (Int_repr.to_zint z, ctxt)
    | Int_of_int64 i -> ok (Int_repr.of_int64 i, ctxt)
    | Int_to_int64 i -> ok (Int_repr.to_int64 i, ctxt)
    | Int_is_nat z -> ok (Int_repr.is_nat z, ctxt)
    | Int_neg n -> ok (Int_repr.neg n, ctxt)
    | Int_add (x, y) -> ok (Int_repr.add x y, ctxt)
    | Int_add_n (x, y) -> ok (Int_repr.add_n x y, ctxt)
    | Int_mul (x, y) -> ok (Int_repr.mul x y, ctxt)
    | Int_mul_n (x, y) -> ok (Int_repr.mul_n x y, ctxt)
    | Int_ediv (x, y) -> ok (Int_repr.ediv x y, ctxt)
    | Int_ediv_n (x, y) -> ok (Int_repr.ediv_n x y, ctxt)
    | Int_sub (x, y) -> ok (Int_repr.sub x y, ctxt)
    | Int_shift_left (x, y) -> ok (Int_repr.shift_left x y, ctxt)
    | Int_shift_right (x, y) -> ok (Int_repr.shift_right x y, ctxt)
    | Int_logor (x, y) -> ok (Int_repr.logor x y, ctxt)
    | Int_logand (x, y) -> ok (Int_repr.logand x y, ctxt)
    | Int_logxor (x, y) -> ok (Int_repr.logxor x y, ctxt)
    | Int_lognot n -> ok (Int_repr.lognot n, ctxt)
    | Int_int n -> ok (Int_repr.int n, ctxt)
    | Lift_tz_result r ->
      let%bind r = Proto_alpha_utils.Trace.trace_alpha_tzresult (fun _ -> `TODO) r in
      ok (r, ctxt)
end

type 'a t =
  | Bind : 'a t * ('a -> 'b t) -> 'b t
  | Call : 'a Command.t -> 'a t
  (* | Gas_set_unlimited : 'a t -> 'a t *)
  | Return : 'a -> 'a t
  (* | Trace : Error.t * 'a t -> 'a t *)
  | Bind_err : 'a result_monad -> 'a t
  | Try : 'a t -> 'a option t

let rec eval
  : type a.
    a t ->
    context ->
    execution_trace ref option ->
    (a * context) result_monad
  = fun e ctxt log ->
  match e with
  | Bind (e', f) ->
    let%bind (v, ctxt) = eval e' ctxt log in
    eval (f v) ctxt log
  | Try e ->
    begin
    try
      let%bind (ret, ctxt) = eval e ctxt log in
      ok (Some ret, ctxt)
    with LT.Temporary_hack _s -> ok (None, ctxt)
    end
  | Call command -> Command.eval command ctxt log
  | Return v -> ok (v, ctxt)
  | Bind_err x ->
    let%bind x = x in
    ok (x, ctxt)
  (* | Trace (error, e') -> trace (Script_interpreter_error error) (eval e' ctxt log) *)

(* module Let_syntax = struct
  let bind m ~f = Bind (m, f)
  module Open_on_rhs_bind = struct end
end *)

let return (x: 'a) : 'a t = Return x
let call (command : 'a Command.t) : 'a t = Call command
let ( let>> ) o f = Bind (call o, f)
let ( let* ) o f = Bind (o, f)
let bind_err (x: 'a result_monad) : 'a t = Bind_err x

let rec bind_list = function
  | [] -> return []
  | hd::tl ->
    let* hd = hd in
    let* tl = bind_list tl in
    return @@ hd :: tl

let bind_map_list f lst = bind_list (List.map f lst)

let bind_fold_list f init lst =
  let aux x y = let* x = x in f x y
  in List.fold_left aux (return init) lst