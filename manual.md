# OCaml library convention

Historically OCaml library management has been provided by the
third-party tool `ocamlfind`. Since vX.Y.Z, the toolchain provides
direct support for using libraries installed according to the library
convention described in this section.

Libraries installed according to the convention can be used as
`ocamlfind` packages transparently. The OCaml toolchain however does
not understand `ocamlfind` packages. Moving to the simpler OCaml
library convention is encouraged.

*Note on terminology.* `.cma`, `.cmxa` or `.cmxs` may sometimes be
mentioned in the wild as being *libraries*. Technically these are
*archives* or *library archives* and should not be confused with
libraries as defined by this convention; archives are an
implementation detail of it.  Also the `ocamlfind` tool uses (most of
the time) the term *package* for what the OCaml library convention
calls a *library*.

## Libraries and OCAMLPATH

A *library* is a named set of modules designed to be used and
distributed together. Each library is installed in its own, isolated,
*library directory*.

The compiler looks for library directories in the root directories
defined in the `OCAMLPATH` environment variable. The *name* of a
library is the relative path up to its root directory with directory
separators substituted by the character `.` (U+002E). For example with
the following `OCAMLPATH` definition:

```
OCAMLPATH=/home/bactrian/opam/lib:/usr/lib/ocaml
```

We get the following map between library directories and library names:

```
Library directory                          Library name
----------------------------------------------------------------
/home/bactrian/opam/lib/ptime/clock/jsoo   ptime.clock.jsoo
/home/bactrian/opam/lib/re/emacs           re.emacs
/usr/lib/ocaml/ocamlgraph                  ocamlgraph
/usr/lib/ocaml/ocaml/unix                  ocaml.unix
/usr/lib/ocaml/re/emacs                    N/A (shadowed)
/haha/hihi/hoho                            N/A (not in a root dir)
```

In library names, each `.` separated segment (and thus directory name)
must be a non-empty, uncapitalized OCaml compilation unit name except
for the `-` (U+002D) character which is also allowed. Even though this
is not checked by the toolchain, having segment names in the same
directory that differ only by their `_` and - characters must not be
done (e.g. `dir.foo-bar` and `dir.foo_bar`).

A library directory always defines a single library. It can contain
subdirectories which have other libraries but there is no connection
between them except for the name prefix they share.

The `OCAMLPATH` variable follows the usual conventions for `PATH`-like
environment variables. Directories are separated by the platform
specific separator, namely `:` (U+003A) on POSIX platforms, `;`
(U+003B) on Windows platforms.  Empty paths are allowed and
discarded.  If the same library name is available in more than one
root directory of `OCAMLPATH` the leftmost one takes over.

The `ocamlc -ocamlpath` invocation returns the current value of the
`OCAMLPATH`. This is either the value of the `OCAMLPATH` environment
variable or, if undefined, a default set at OCaml configuration time.

The toolchain supports prepending to the `OCAMLPATH` directly on the
command line via the `-L DIR` option. 

## Using libraries

To use a library for compiling and linking use the `-require` option.
For example to compile a `test.ml` file with the `re.emacs` library
invoke:

```
ocamlc -require re.emacs test.ml
```

this includes the library directory of `re.emacs` during compilation
and links the library's modules and its dependencies for producing the
final executable.

In the OCaml toplevel (REPL) use the corresponding `#require`
directive.  This loads the library's modules and its dependencies and
adds its directory to the includes:

```
ocaml

    OCaml version 4.09.0
    
# #require "re.emacs"
```

Invoking `ocaml` with `ocaml -require re.emacs` is strictly equivalent.

The current value of the `OCAMLPATH` can be output with the
`-ocamlpath` option:

```
ocamlc -ocamlpath 
/usr/lib/ocaml:/usr/local/lib/ocaml
```

This outputs either the value of the `OCAMLPATH` environment variable
or the default value set at OCaml configuration time if it is
undefined.

```
(unset OCAMLPATH; ocamlc -ocamlpath) # Show default value 
```

If you need to extend the `OCAMLPATH` for your environment you can use:

```
export OCAMLPATH=~/.local/lib/ocaml:$(ocamlc -ocamlpath)
```

It is also possible to extend it directly on the command line via `-L`
option which prepends root directories to the `OCAMLPATH` starting
from the right. These two invocations are equivalent:

```
ocamlc -L foo -L bar -require re.emacs test.ml
OCAMLPATH=foo:bar:$(ocamlc -ocamlpath) ocamlc -require re.emacs test.ml
```

## Defining libraries

The directory of a library holds all the compilation objects of the
modules it defines and archives them into `lib.{cma,cmxa,cmxs,a}` (as
needed) files. For a library named `mylib` with modules
`m0`, ..., `mn`. the library directory has the following files:

```
mylib/{m0,...,mn}.{cmi,cmx,cmti,cmt}
mylib/lib.{cma,cmxa,cmxs,a}
```

The following constraints are assumed to hold on a library directory. 

1. `m.{cmti,cmt}` files are optional they do however enhance other tools.
   `m.cmti` files are needed for documentation generation.
2. If a `m.cmx` has no `m.cmi` then the module is private to the library.
3. If a `m.cmi` has no `m.cmx` and no implementation in the archives then it
   is an `mli`-only module.
4. If there is a `m.cmx` file there must be a `lib.cmxa`. Any `m.cmx` 
   must also be present in the `lib.cmxa` archive. 
6. If there is a `lib.cmxa` there must be a `lib.a` unless `lib.cmxa`
   is empty (since 4.12).
7. FIXME discuss. All `lib.{cma,cmxa,cmxs}` files (as available) contain the 
   same compilation units.
8. FIXME discuss. All `lib.{cma,cmxa,cmxs}` files (as available) contain the 
   same dependency specifications.
9. Empty archives are allowed. They can 
   contain library dependency specifications which are used at link time.
10. A missing library archive means that the library is not available for the 
   given code backend, failures are reported on usage at link time. This 
   entails that a library made from `mli`-only modules must install empty 
   `lib.{cma,cmxa,cmxs}` files in its library directory so that the library
   can be used both during the compilation and link phase without users 
   needing to know it has no implementations.
   
Library dependencies are used to indicate that a particular library
uses other ones for implementing its modules. Dependencies are
specified as library names which are resolved at link time in the
`OCAMLPATH`. The toolchain is in charge of resolving and sorting the
dependencies of libraries specified via `-require` options at link
time.

Library dependencies are stored as library names in library
archives. They are specified by using the `-require` flag during
archive creation (`-a` option). Note that dependencies are not
resolved during archive creation and do not need to exist in the
`OCAMLPATH` at that time.

For example the following generates library archives for a library
`mylib` that needs `re.emacs` at link time:

```
ocamlc -require re.emacs -a -o mylib/lib.cma a.cmo b.cmo
ocamlopt -require re.emacs -a -o mylib/lib.cmxa a.cmx b.cmx
```

Assuming you have a library `mylib` with modules `{a,b}.{mli,ml}`
whose implementations depends on `re.emacs` here are full instructions
on how to define it's library directory in `mylib` according to the
convention:

```
mkdir -p mylib

# Compile interfaces
ocamlc -bin-annot -c -o mylib/a.cmi a.mli
ocamlc -bin-annot -c -o mylib/b.cmi b.mli

# Compile bytecode objects
ocamlc -bin-annot -c -o mylib/a.cmo -I mylib -require re.emacs a.ml
ocamlc -bin-annot -c -o mylib/b.cmo -I mylib -require re.emacs b.ml
ocamlc -a -o mylib/lib.cma -require re.emacs mylib/a.cmo mylib/b.cmo

# Compile native code objects
ocamlopt -c -o mylib/a.cmx -I mylib -require re.emacs a.ml
ocamlopt -c -o mylib/b.cmx -I mylib -require re.emacs b.ml
ocamlopt -a -o mylib/lib.cmxa -require re.emacs mylib/a.cmx mylib/b.cmx
ocamlopt -a -o mylib/lib.cmxa -require re.emacs mylib/a.cmx mylib/b.cmx
ocamlopt -shared -o mylib/lib.cmxs mylib/lib.cmxa
```

## Example

In this example we show how to compile and define two libraries to use 
locally in a native code build. We have:

* Library `a` made of sources `a.{mli,ml}` depending on the `ocaml.str` 
  library.
* Library `b` made of sources `b.{mli,ml}` depending on the library `a`.
* An executable `exec.ml` which depends on `b`

Here are our sources:

```
.
├── a.mli
├── a.ml
├── b.mli
├── b.ml
└── exec.ml
```
We create directories for the libraries. The `libs` directory 
will be added to the `OCAMLPATH` via `-L`.

```
mkdir -p libs/a libs/b
```

We compile and define library `a`:

```
ocamlopt -bin-annot -c -o libs/a/a.cmi a.mli 
ocamlopt -bin-annot -c -o libs/a/a.cmx -I libs/a -require ocaml.str a.ml 
ocamlopt -a -o libs/a/lib.cmxa -require ocaml.str libs/a/a.cmx
```

We compile and define library `b`. We extend the `OCAMLPATH` on the 
command line with the `-L` option of the toolchain.

```
ocamlopt -bin-annot -c -o libs/b/b.cmi b.mli 
ocamlopt -bin-annot -c -o libs/b/b.cmx -L libs -I libs/b -require a b.ml 
ocamlopt -a -o libs/b/lib.cmxa -require ocaml.str libs/b/b.cmx
```

We compile our executable:
```
ocamlopt -L libs -require b exec.ml
```

## Packaging OCaml

If you are packaging OCaml for a system distribution or a package
manager, the resulting install should have a properly setup
`OCAMLPATH` so that by default the OCaml libraries are available under
the `ocaml.*` library name prefix.

A default `OCAMLPATH` value for when the `OCAMLPATH` environment
variable is undefined can be set by setting OCaml's `configure` script
`DEFAULT_OCAMLPATH` variable. For example with:

```
./configure DEFAULT_OCAMLPATH=/usr/lib/ocaml:/usr/local/lib/ocaml
```

the default `OCAMLPATH` value will be: 

```
/usr/lib/ocaml:/usr/local/lib/ocaml
```

If no value is defined at configuration time, the default `OCAMLPATH`
is empty and only the standard library can be used if the `OCAMLPATH`
environment variable is undefined.

End user can extend their `OCAMLPATH` by using `ocamlc -ocamlpath`. For 
example:

```
export OCAMLPATH=~/.local/lib/ocaml:$(ocamlc -ocamlpath)
```


