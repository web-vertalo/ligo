type storage = (int, int);

let main = 
  (n: (int, storage)): (list(operation), storage) => 
    {
      let x: (int, int) = 
        {
          let x: int = 7;
          (x + n[0], n[1][0] + n[1][1])
        };
      ([] : list(operation), x)
    };

let f0 = (a: string) => true;

let f1 = (a: string) => true;

let f2 = (a: string) => true;

let letin_nesting = 
  (_: unit) => 
    {
      let s = "test";
      let p0 = f0(s);
      assert(p0);
      let p1 = f1(s);
      assert(p1);
      let p2 = f2(s);
      assert(p2);
      s
    };

let letin_nesting2 = 
  (x: int) => 
    {
      let y = 2;
      let z = 3;
      x + y + z
    };
