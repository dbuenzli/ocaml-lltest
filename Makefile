
default: lib-a lib-b lib-c lib-d lib-e lib-f lib-missdep use-d use-da use-e \
         top-use-e use-f

lib-a: export OCAMLPATH=.
lib-a:
	ocamlc -c a/a.mli
	ocamlc -c a/a.ml -I a
	ocamlc -a -o a/lib.cma a/a.cmo
	ocamlopt -c a/a.ml -I a
	ocamlopt -a -o a/lib.cmxa a/a.cmx

lib-b:	export OCAMLPATH=.
lib-b: lib-a
	ocamlc -c b/b.mli -require a
	ocamlc -c b/b.ml -I b -require a
	ocamlc -a -o b/lib.cma b/b.cmo -require a
	ocamlopt -c b/b.ml -I b -require a
	ocamlopt -a -o b/lib.cmxa b/b.cmx -require a

lib-c:	export OCAMLPATH=.
lib-c: lib-a
	ocamlc -c c/c.mli -require a
	ocamlc -c c/c.ml -I c -require a
	ocamlc -a -o c/lib.cma c/c.cmo -require a
	ocamlopt -c c/c.ml -I c -require a
	ocamlopt -a -o c/lib.cmxa c/c.cmx -require a

lib-d:	export OCAMLPATH=.
lib-d: lib-b lib-c
	ocamlc -c d/d.mli -require b -require c
	ocamlc -c d/d.ml -I d -require b -require c
	ocamlc -a -o d/lib.cma d/d.cmo -require b -require c
	ocamlopt -c d/d.ml -I d -require b -require c
	ocamlopt -a -o d/lib.cmxa d/d.cmx -require b -require c

lib-e: export OCAMLPATH=.
lib-e: lib-d
	ocamlc -c e/e.mli -require d
	ocamlc -c e/e.ml -I e -require d
	ocamlc -a -o e/lib.cma e/e.cmo -require d
	ocamlopt -c e/e.ml -I e -require d
	ocamlopt -a -o e/lib.cmxa e/e.cmx -require d

lib-f: export OCAMLPATH=.
lib-f: lib-e
	ocamlc -c f/f.mli -require e
	ocamlc -c f/f.ml -I f -require e
	ocamlopt -c f/f.ml -I f -require e
	ocamlc -c f/f_stubs.c
	mv f_stubs.o f/
	ocamlmklib -o f/lib -oc f/f f/f.cmo f/f.cmx f/f_stubs.o -require e \
	-ccopt '-L\$$CAMLORIGIN'

lib-missdep: export OCAMLPATH=.
lib-missdep:
	# This is ok, lookup is done at link time.
	ocamlc -a -o missdep/lib.cma -require does.not.exist
	ocamlopt -a -o missdep/lib.cmxa -require does.not.exist

use-d: export OCAMLPATH=.
use-d: lib-d
	ocamlc -c use_d.ml -require d
	ocamlc -o use_d.byte use_d.cmo -require d
	ocamlopt -c use_d.ml -require d
	ocamlopt -o use_d.native use_d.cmx -require d

use-da: export OCAMLPATH=.
use-da: lib-d
	ocamlc -c use_da.ml -require a -require d
	ocamlc -o use_da.byte use_da.cmo -require d # Does not fail but comp fails
	ocamlopt -c use_da.ml -require a -require d
	ocamlopt -o use_da.native use_da.cmx -require d # Does not fail but comp fails

use-e: export OCAMLPATH=.
use-e: lib-e
	ocamlc -c use_e.ml -require e
	ocamlc -o use_e.byte use_e.cmo -require e
	ocamlopt -c use_e.ml -require e
	ocamlopt -o use_e.native use_e.cmx -require e
	# Alternate init sequence
	ocamlc -o use_e_alt.byte use_e.cmo -require c -require b -require e
	ocamlopt -o use_e_alt.native use_e.cmx -require c -require b -require e

use-f: export OCAMLPATH=.
use-f: lib-f
	ocamlc -c use_f.ml -require f
  # Normally the dll would be installed at the right place
	CAML_LD_LIBRARY_PATH=./f ocamlc -o use_f.byte use_f.cmo -require f
	ocamlc -custom -o use_f_custom.byte use_f.cmo -require f
	ocamlopt -c use_f.ml -require f
	ocamlopt -o use_f.native use_f.cmx -require f

top-use-e: export OCAMLPATH=.
top-use-e: lib-e
	ocamlmktop -o use_e.top -require e

use-da-fail: export OCAMLPATH=.
use-da-fail: lib-d
	ocamlc -c use_da.ml -require d

use-da-fail-native: export OCAMLPATH=.
use-da-fail-native: lib-d
	ocamlopt -c use_da.ml -require d

use-b-fail: export OCAMLPATH=.
use-b-fail: lib-d
	ocamlc -c use_b.ml -require b
	ocamlc -o use_b.byte use_b.cmo -require b -noautoliblink

use-b-fail-native: export OCAMLPATH=.
use-b-fail-native: lib-d
	ocamlopt -c use_b.ml -require b
	ocamlopt -o use_b.native use_b.cmx -require b -noautoliblink

use-missdep: export OCAMLPATH=.
use-missdep: lib-missdep
	ocamlc -c use_missdep.ml -require missdep
	ocamlc -o use_missdep use_missdep.cmo -require missdep

use-missdep-native: export OCAMLPATH=.
use-missdep-native: lib-missdep
	ocamlopt -c use_missdep.ml -require missdep
	ocamlopt -o use_missdep use_missdep.cmx -require missdep

clean:
	rm -f */*.cmi */*.cmo */*.cmx */*.cma */*.cmxa */*.a */*.o */*.so \
	*.cmi *.cmo *.cmx *.byte *.native *.o *.top

.PHONY: lib-a lib-b lib-c lib-d lib-e lib-f use-d use-e use-f top-use-e \
        use-da use-e use-f use-da-fail use-da-fail-native use-b-fail \
        use-b-fail-native use-missdep use-missdep-native \
        clean