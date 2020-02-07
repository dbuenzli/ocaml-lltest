(* Lib [c] depends on [a] but makes that abstract in his interface.
   a ... c

   Clients of [c] need to require [c]. *)

type t
val v : int -> t
