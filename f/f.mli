
(* Lib [f] depends on [e] but makes this abstract in its iterface.
   It also has a c binding.

    a ... c --\
    \         d ... e ... f
     \--- b --/

   Clients of [f] need only to require [f]. *)

type t
val f : unit -> int
val v : unit -> t
