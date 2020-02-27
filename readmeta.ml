let read_cma ic =
  let lib =
    let toc_pos = input_binary_int ic in
    seek_in ic toc_pos;
    (input_value ic : Cmo_format.library)
  in
  let unit_name u = u.Cmo_format.cu_name in
  let units = List.map unit_name lib.Cmo_format.lib_units in
  let requires = List.map Lib.Name.to_string lib.Cmo_format.lib_requires in
  Printf.printf
    "units: %s\nrequires: %s\nccobjs: %s\nccopts: %s\ndllibs: %s\n%!"
    (String.concat " " units)
    (String.concat " " requires)
    (String.concat " " lib.Cmo_format.lib_ccobjs)
    (String.concat " " lib.Cmo_format.lib_ccopts)
    (String.concat " " lib.Cmo_format.lib_dllibs)

let read_cmxa ic =
  let lib = (input_value ic : Cmx_format.library_infos) in
  let unit_name (u, _) = u.Cmx_format.ui_name in
  let units = List.map unit_name lib.Cmx_format.lib_units in
  let requires = List.map Lib.Name.to_string lib.Cmx_format.lib_requires in
  Printf.printf "units: %s\nrequires: %s\nccobjs: %s\nccopts: %s\n%!"
    (String.concat " " units)
    (String.concat " " requires)
    (String.concat " " lib.Cmx_format.lib_ccobjs)
    (String.concat " " lib.Cmx_format.lib_ccopts)

type handle
external ndl_open : string -> bool -> handle * Cmxs_format.dynheader
  = "caml_natdynlink_open"

let read_cmxs file =
  let _, dynh = ndl_open file false in
  let unit_name d = d.Cmxs_format.dynu_name in
  let units = List.map unit_name dynh.Cmxs_format.dynu_units in
  let requires = List.map Lib.Name.to_string dynh.Cmxs_format.dynu_requires in
  Printf.printf "units: %s\nrequires: %s\n%!"
    (String.concat " " units)
    (String.concat " " requires)

let read_meta file =
  if Filename.extension file = ".cmxs" then read_cmxs file else
  let ic = open_in_bin file in
  try
    let len = String.length Config.cma_magic_number in
    let magic = really_input_string ic len in
    begin match magic with
    | m when String.equal m Config.cma_magic_number -> read_cma ic
    | m when String.equal m Config.cmxa_magic_number -> read_cmxa ic
    | m -> raise (Sys_error ("unknown magic number " ^ m))
    end;
    close_in ic
  with
  | e -> close_in_noerr ic; raise e

let main () =
  try
    if Array.length Sys.argv <> 2
    then (Printf.eprintf "Usage: readmeta CM[X]A\n"; exit 1)
    else (read_meta Sys.argv.(1); exit 0)
  with
  | Sys_error e -> Printf.eprintf "%s: %s" Sys.argv.(1) e; exit 1

let () = if !Sys.interactive then () else main ()
