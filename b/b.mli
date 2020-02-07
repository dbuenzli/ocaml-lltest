(* Lib [b] depends on [a] and shows it in its interface.
   a --- b

   Clients of [b] need to require [b] and [a]. *)

type t = A.t
val v : int -> t
