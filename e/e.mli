(* Lib [e] depends on [d] but makes this abstract in its iterface.

    a ... c --\
    \         d ... e
     \--- b --/

   Clients of [e] need only to require [e]. *)

type t
val v : int -> int -> t
