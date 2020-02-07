(* Lib [d] depends on [b] and [c] and shows it in its interface since
   [b] didn't make its usage of [a] abstract it also depends on
   [a] and so do its clients.

   a .... c --\
    \          d
     \--- b --/

   Clients of [d] need to require [b], [c] and [a] (via [b]) aswell.
*)

type b = B.t
type c = C.t
val b : int -> b
val c : int -> c
