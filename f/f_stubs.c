#include <caml/mlvalues.h>
#include <caml/memory.h>

CAMLprim value ocaml_f (value unit)
{
  CAMLparam1 (unit);
  CAMLreturn (Val_int (42));
}
