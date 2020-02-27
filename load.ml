
let ocamlpath = ["."]

let load_file file = try Dynlink.loadfile ~ocamlpath file with
| Dynlink.Error e ->
    Printf.printf "load %s: %s" file (Dynlink.error_message e); exit 2

let main () =
  let objs = List.tl (Array.to_list Sys.argv) in
  Dynlink.allow_unsafe_modules true;
  List.iter load_file objs;
  exit 0

let () = main ()
