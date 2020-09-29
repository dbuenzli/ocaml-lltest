

#    The library graph is as follows with ... denoting fully abstract
#    dependencies (the library does not rexeport constructs of its
#    dependencies in its interface). [a] has no deps, [f] depends on
#    everthing and has C stubs.
#
#     /... c --\
#    a         d ... e ... f
#     \--- b --/
#
#

default: lib-a lib-b lib-c lib-d lib-e lib-f lib-missdep use-d use-da use-e \
         top-use-e top-use-b use-f require

.PHONY: lib-a lib-b lib-c lib-d lib-e lib-f use-d use-e use-f top-use-e \
	      top-use-b use-da use-e use-f use-da-fail use-da-fail-native use-b-fail \
        use-b-fail-native use-missdep use-missdep-native require clean

clean:
	rm -f */*.cmi */*.cmo */*.cmx */*.cma */*.cmxa */*.cmxs */*.a */*.o */*.so \
	*.cmi *.cmo *.cmx *.byte *.native *.o *.top

lib-a:
	ocamlc -L . -c a/a.mli
	ocamlc -L . -c a/a.ml -I a
	ocamlc -L . -a -o a/lib.cma a/a.cmo
	ocamlopt -L . -c a/a.ml -I a
	ocamlopt -L . -a -o a/lib.cmxa a/a.cmx
	ocamlopt -L . -linkall -shared -o a/lib.cmxs a/lib.cmxa

lib-b: lib-a
	ocamlc -L . -c b/b.mli -require a
	ocamlc -L . -c b/b.ml -I b -require a
	ocamlc -L . -a -o b/lib.cma b/b.cmo -require a
	ocamlopt -L . -c b/b.ml -I b -require a
	ocamlopt -L . -a -o b/lib.cmxa b/b.cmx -require a
	ocamlopt -L . -linkall -shared -o b/lib.cmxs b/lib.cmxa

lib-c: lib-a
	ocamlc -L . -c c/c.mli -require a
	ocamlc -L . -c c/c.ml -I c -require a
	ocamlc -L . -a -o c/lib.cma c/c.cmo -require a
	ocamlopt -L . -c c/c.ml -I c -require a
	ocamlopt -L . -a -o c/lib.cmxa c/c.cmx -require a
	ocamlopt -L . -linkall -shared -o c/lib.cmxs c/lib.cmxa

lib-d: lib-b lib-c
	ocamlc -L . -c d/d.mli -require b -require c
	ocamlc -L . -c d/d.ml -I d -require b -require c
	ocamlc -L . -a -o d/lib.cma d/d.cmo -require b -require c
	ocamlopt -L . -c d/d.ml -I d -require b -require c
	ocamlopt -L . -a -o d/lib.cmxa d/d.cmx -require b -require c
	ocamlopt -L . -linkall -shared -o d/lib.cmxs d/lib.cmxa

lib-e: lib-d
	ocamlc -L . -c e/e.mli -require d
	ocamlc -L . -c e/e.ml -I e -require d
	ocamlc -L . -a -o e/lib.cma e/e.cmo -require d
	ocamlopt -L . -c e/e.ml -I e -require d
	ocamlopt -L . -a -o e/lib.cmxa e/e.cmx -require d
	ocamlopt -L . -linkall -shared -o e/lib.cmxs e/lib.cmxa

lib-f: lib-e
	ocamlc -L . -c f/f.mli -require e
	ocamlc -L . -c f/f.ml -I f -require e
	ocamlopt -L . -c f/f.ml -I f -require e
	ocamlc -L . -c f/f_stubs.c
	mv f_stubs.o f/
	ocamlmklib -o f/lib -oc f/f f/f.cmo f/f.cmx f/f_stubs.o -require e \
	-ccopt '-L\$$CAMLORIGIN'
	ocamlopt -linkall -shared -o f/lib.cmxs f/lib.cmxa

lib-missdep:
	# This is ok, lookup is done at link time.
	ocamlc -L . -a -o missdep/lib.cma -require does.not.exist
	ocamlopt -L . -a -o missdep/lib.cmxa -require does.not.exist

use-d: lib-d
	ocamlc -L . -c use_d.ml -require d
	ocamlc -L . -o use_d.byte use_d.cmo -require d
	ocamlopt -L . -c use_d.ml -require d
	ocamlopt -L . -o use_d.native use_d.cmx -require d

use-da: lib-d
	ocamlc -L . -c use_da.ml -require a -require d
	ocamlc -L . -o use_da.byte use_da.cmo -require d # Does not fail but comp fails
	ocamlopt -L . -c use_da.ml -require a -require d
	ocamlopt -L . -o use_da.native use_da.cmx -require d # Does not fail but comp fails

use-e: lib-e
	ocamlc -L . -c use_e.ml -require e
	ocamlc -L . -o use_e.byte use_e.cmo -require e
	ocamlopt -L . -c use_e.ml -require e
	ocamlopt -L . -o use_e.native use_e.cmx -require e
	# Alternate init sequence
	ocamlc -L . -o use_e_alt.byte use_e.cmo -require c -require b -require e
	ocamlopt -L . -o use_e_alt.native use_e.cmx -require c -require b -require e

use-f: lib-f
	ocamlc -L . -c use_f.ml -require f
  # Normally the dll would be installed at the right place
	CAML_LD_LIBRARY_PATH=./f ocamlc -L . -o use_f.byte use_f.cmo -require f
	ocamlc -L . -custom -o use_f_custom.byte use_f.cmo -require f
	ocamlopt -L . -c use_f.ml -require f
	ocamlopt -L . -o use_f.native use_f.cmx -require f

top-use-e: lib-e
	ocamlmktop -L . -o use_e.top -require e

top-use-b: lib-b
	ocamlmktop -L . -o use_b.top -require b

use-da-fail: lib-d
	ocamlc -L . -c use_da.ml -require d

use-da-fail-native: lib-d
	ocamlopt -L . -c use_da.ml -require d

use-b-fail: lib-d
	ocamlc -L . -c use_b.ml -require b
	ocamlc -L . -o use_b.byte use_b.cmo -require b -noautoliblink

use-b-fail-native: lib-d
	ocamlopt -L . -c use_b.ml -require b
	ocamlopt -L . -o use_b.native use_b.cmx -require b -noautoliblink

use-missdep: lib-missdep
	ocamlc -L . -c use_missdep.ml -require missdep
	ocamlc -L . -o use_missdep use_missdep.cmo -require missdep

use-missdep-native: lib-missdep
	ocamlopt -L . -c use_missdep.ml -require missdep
	ocamlopt -L . -o use_missdep use_missdep.cmx -require missdep

require:
	ocamlc -L . -o require.byte dynlink.cma require.ml
	ocamlopt -L . -o require.native dynlink.cmxa require.ml
	ocamlc -L . -linkall -o require_has_implicit_a.byte \
	  dynlink.cma a/lib.cma require.ml -assume-library a
	ocamlopt -L . -linkall -o require_has_implicit_a.native \
		dynlink.cmxa a/lib.cmxa require.ml -assume-library a
	ocamlc -L . -linkall -o require_has_d.byte dynlink.cma require.ml -require d
	ocamlopt -L . -linkall -o require_has_d.native dynlink.cmxa \
	  require.ml -require d
	CAML_LD_LIBRARY_PATH=./f \
  ocamlc -L . -linkall -o require_has_f.byte dynlink.cma require.ml -require f
	ocamlopt -L . -linkall -o require_has_f.native dynlink.cmxa require.ml -require f
