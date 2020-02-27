
let ocamlpath = ["."]

let load_lib lib = try Dynlink.loadlib ~ocamlpath lib with
| Dynlink.Error e ->
    Printf.printf "load lib %s: %s" lib (Dynlink.error_message e); exit 2

let main () =
  let libs = List.tl (Array.to_list Sys.argv) in
  Dynlink.allow_unsafe_modules true;
  List.iter load_lib libs;
  exit 0

let () = main ()
