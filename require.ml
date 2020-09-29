
let ocamlpath = ["."]

let require arg = try Dynlink.require ~ocamlpath arg with
| Dynlink.Error e ->
    Printf.printf "require %s: %s" arg (Dynlink.error_message e); exit 2

let main () =
  let reqs = List.tl (Array.to_list Sys.argv) in
  Dynlink.allow_unsafe_modules true;
  List.iter require reqs;
  exit 0

let () = main ()
