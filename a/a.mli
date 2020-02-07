(* Lib [a] has no dependency.
   Clients of [a] need to require [a]. *)

type t
val v : int -> t
