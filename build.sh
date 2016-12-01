#!/bin/bash

HERE="$(cd $(dirname $0) && pwd)"

PREFIX="$HERE/prefix"
PARALLEL="-j 8"

startpos=0

case "$1" in
  mklinks)
    startpos=0
    ;;
  stage1)
    startpos=1
    ;;
  newlib)
    startpos=2
    ;;
  stage2)
    startpos=3
    ;;
  *)
    ;;
esac
set -e

# This assumes you're running on an x86 linux machine!
if [ "$startpos" -le 0 ]; then
  rm -rf "$PREFIX/bin"
  mkdir -p "$PREFIX/bin"

  pushd "$PREFIX/bin"
  for prog in as ld ar ranlib strip nm; do
    ln -s "$(which $prog)" ia16-unknown-elf-$prog
  done
  popd
fi

export PATH="$PREFIX/bin":$PATH

cd "$HERE"

if [ "$startpos" -le 1 ]; then
  rm -rf build
  mkdir -p build
  pushd build
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --without-headers --with-newlib --enable-languages=c --disable-libssp
  make $PARALLEL
  make install
  popd
fi
if [ "$startpos" -le 2 ]; then
  rm -rf build-newlib
  mkdir -p build-newlib
  pushd build-newlib
  ../newlib-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX"
  make
  make install
  popd
fi
if [ "$startpos" -le 3 ]; then
  rm -rf build2
  mkdir -p build2
  pushd build2
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --disable-libssp --enable-languages=c
  make $PARALLEL
  make install
  popd
fi
