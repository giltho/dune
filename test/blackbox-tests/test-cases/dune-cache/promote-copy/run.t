Test that with the cache in copy mode:
- the cache is still used, i.e. dune skip executions of rules that are
. present in the cache
- files are copied rather than hardlinked

  $ cat > config <<EOF
  > (lang dune 2.1)
  > (cache enabled)
  > (cache-duplication copy)
  > (cache-transport daemon)
  > EOF
  $ cat > dune-project <<EOF
  > (lang dune 2.1)
  > EOF
  $ cat > dune <<EOF
  > (rule
  >   (deps source)
  >   (targets target)
  >   (action (bash "touch beacon ; cat source source > target")))
  > EOF
  $ cat > source <<EOF
  > \_o< COIN
  > EOF

Initial build

  $ env XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build --config-file=config target
  $ dune_cmd stat hardlinks _build/default/source
  1
  $ dune_cmd stat hardlinks _build/default/target
  1
  $ ls _build/default/beacon
  _build/default/beacon

Clean + rebuild (we expect dune to reuse things from the cache without
hardlinking them)

  $ rm -rf _build/default
  $ env XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build --config-file=config target
  $ dune_cmd stat hardlinks _build/default/source
  1
  $ dune_cmd stat hardlinks _build/default/target
  1
  $ test -e _build/default/beacon
  [1]
  $ cat _build/default/source
  \_o< COIN
  $ cat _build/default/target
  \_o< COIN
  \_o< COIN


------------------

Check that thins are still rebuild during incremental compilation with
the cache in copy mode

  $ cat > dune-project <<EOF
  > (lang dune 2.1)
  > EOF
  $ cat > dune-v1 <<EOF
  > (rule
  >   (targets t1)
  >   (action (bash "echo running; echo v1 > t1")))
  > (rule
  >   (deps t1)
  >   (targets t2)
  >   (action (bash "echo running; cat t1 t1 > t2")))
  > EOF
  $ cat > dune-v2 <<EOF
  > (rule
  >   (targets t1)
  >   (action (bash "echo running; echo v2 > t1")))
  > (rule
  >   (deps t1)
  >   (targets t2)
  >   (action (bash "echo running; cat t1 t1 > t2")))
  > EOF
  $ cp dune-v1 dune
  $ env XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build --config-file=config t2
          bash t1
  running
          bash t2
  running
  $ cat _build/default/t2
  v1
  v1
  $ cp dune-v2 dune
  $ env XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build --config-file=config t2
          bash t1
  running
          bash t2
  running
  $ cat _build/default/t2
  v2
  v2
  $ cp dune-v1 dune
  $ env XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build --config-file=config t2
  $ cat _build/default/t1
  v1
  $ cat _build/default/t2
  v1
  v1
