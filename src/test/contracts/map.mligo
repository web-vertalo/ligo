type foobar = (int, int) map

let empty_map : foobar = Map.empty

let map1 : foobar =
  Map.literal [(144,23); (51,23); (42,23); (120,23); (421,23)]

let map2 : foobar = Map.literal [(23,0); (42,0)]

let set_ (n: int) (m: foobar) : foobar = Map.update 23 (Some n) m

let rm (m: foobar) : foobar = Map.remove 42 m

(* Dummy test so that we can add the same test for PascaLIGO *)
let patch_ (m: foobar) : foobar = Map.literal [(0,5); (1,6); (2,7)]

(* Second dummy test, see above *)
let patch_empty (m: foobar) : foobar = Map.literal [(0,0); (1,1); (2,2)]

(* Third dummy test, see above *)
let patch_deep (m: foobar * nat) : foobar * nat =
  Map.literal [(0,0); (1,9); (2,2)], 10n

let size_ (m: foobar) : nat = Map.size m

let gf (m: foobar) : int = Map.find 23 m

let get (m: foobar) : int option = Map.find_opt 42 m
let get_ (m: foobar) : int option = Map.find_opt 42 m

let mem (km: int * foobar) : bool = Map.mem km.0 km.1

let iter_op (m : foobar) : unit =
  let assert_eq = fun (i: int) (j: int) -> assert (i=j)
  in Map.iter assert_eq m

let map_op (m : foobar) : foobar =
  let increment = fun (_: int) (j: int) -> j+1
  in Map.map increment m

let fold_op (m : foobar) : foobar =
  let aggregate = fun (i: int) (j: int * int) -> i + j.0 + j.1
  in Map.fold aggregate m 10

let deep_op (m: foobar) : foobar =
  let coco = 0,m in
  let coco = 0, Map.remove 42 coco.1 in
  let coco = 0, Map.update 32 (Some 16) coco.1
  in coco.1
