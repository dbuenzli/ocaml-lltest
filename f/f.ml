
external f : unit -> int = "ocaml_f"
type t = E.t
let v () = E.v 53 (f ())
let () =
  ignore (v ());
  print_endline "init f.F"
