function incr_map (const l : list (int)) : list (int) is
  List.map (function (const i : int) : int is i + 1, l)

type t is timestamp * nat -> map (string, address)
type u is A | B of t * int | C of int -> (string -> int)
type v is record aaaaaa : ttttttt; bbbbbb : record ccccccccc : string end end

function back (var store : store) : list (operation) * store is
  begin
     var operations  : list (operation) := list [];
    const operations : list (operation) = list [];
    const a          : nat =  0n;
    x0               := record foo = "1"; bar = 4n end;
    x1               := nil;
    x2               := list end;
    x3 := 3#4# list [5; 6];
    case foo of
      10n -> skip
    end;
if saaa.0.1.2.a.b.b.x contains xxxxxxxxxxxxxxx[123] then skip else skip;
    s := set [3_000mutez; -2; 1n];
    a := A;
    b := B (a);
    c := C (a, B (a));
    d := None;
    e := Some (a, B (b));
    z := z.1.2;
x := if true then map [1 -> "1"; 2 -> "2"; 3 -> "3"; 4 -> "4"; 5 -> "5555555555555555"] else Unit;
    y := a.b.c[3];
    a := "hello " ^ "world" ^ "!";
    r := record aaaaaaaaaaaa = 100000000; bbbbbbb = ffffff (2, aa, x, y) + 1 end;
    r := r with record aaaaaaaaaaa = 444442; bbbbbbbbb = 43 + f (z) / 234 end;
    patch store.backers.8.aa.33333.5 with set [(1); f(2*3); 123124234/2345];
    remove (1,2,3) from set foo.bar;
    remove 3 from map foo.bar;
    patch store.backers with map [sender -> amount];
    if now > store.deadline and (not True) then
      begin
        f (x,1);
        for k -> d in map m block { skip };
        for x in set s block { skip };
        while i < 10n
          begin
            acc := 2 - (if toggle then f(x) else Unit);
          end;
        for i := 1n to 10n step 2n
          begin
            acc := acc + i;
          end;
        failwith ("Deadline passed");
      end
    else
      case store.backers[sender] of [
        None -> store.0.backers[sender] := amount
      | Some (_) -> skip
      | B (x, C (y,z)) -> skip
      | False#True#Unit#0xAA#"hi"#4#nil -> skip
      ]
  end with (operations, store, (more_stuff, and_here_too))

  function claim (var store : store; const bar : t; const baz : u; var z : operations * store * (more_stuff * and_here_too)) : list (operation) * store * timestamp * nat -> map (string, address) is
  begin
     const operations : list (operation * map (address, map (longname, domain))) = nilllllllllll;
var operations : list (operation * map (address, map (longname, domain))) := nilllllllllll;
     attributes ["foo"; "inline"];
    if now <= store.deadline then
      failwith ("Too soon.")
    else
      case store.backers[sender] of
        None ->
          failwith ("Not a backer.")
      | Some (0) -> skip
      | Some (quantity) ->
          if balance >= store.goal or store.funded then
            failwith ("Goal reached: no refund.")
          else
            begin
               operations.0.foo := list [transaction (unit, sender, quantity); transaction (foo, bar, bazzzzzzzzzzzzzzz)];
               remove sender.0099999.fffff [fiar (abaxxasfdf)] from map store.backers.foooooo.barrrrr.01.bazzzzzzz
            end
      end
  end with long_function_name (operations, store, (more_stuff, (and_here_too, well_in_here_too), hello))

attributes ["inline"; "foo"]

function withdraw (var store : store) : list (operation) * store is
  begin
    var operations : list (operation) := list end;
    if sender = owner then
      if now >= store.deadline then
        if balance >= store.goal then {
//             store.funded := True;
          patch store with record funded = True; a = b end;
          operations := list [Transfer (owner, balance)];
        };
        else failwith ("Below target.")
      else failwith ("Too soon.");
    else skip
  end with case (foo: bar) of
             nil -> (operations, (store : store))
           |   _ -> (operations, store)
           end
