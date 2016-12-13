#!/bin/bash

HERE="$(cd $(dirname $0) && pwd)"

PREFIX="$HERE/prefix"
PARALLEL="-j 8"

startpos=0

case "$1" in
  dosemu)
    startpos=0
    ;;
  binutils)
    startpos=1
    ;;
  mklinks)
    startpos=2
    ;;
  stage1)
    startpos=3
    ;;
  newlib)
    startpos=4
    ;;
  stage2)
    startpos=5
    ;;
  *)
    ;;
esac
set -e

export PATH="$PREFIX/bin":$PATH

cd "$HERE"

if [ "$startpos" -le 0 ]; then
  pushd dosemu
  ./configure
  make
  popd
fi
if [ "$startpos" -le 1 ]; then
  rm -rf "$PREFIX/bin"
  mkdir -p "$PREFIX/bin"
  rm -rf build-binutils
  mkdir -p build-binutils
  pushd build-binutils
  ../binutils-gdb/configure --target=i386-unknown-elf --prefix="$PREFIX"
  make $PARALLEL
  make install
  popd
fi
if [ "$startpos" -le 2 ]; then
  pushd "$PREFIX/bin"
  for prog in addr2line ar as c++filt elfedit gdb gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip; do
    ln -s i386-unknown-elf-$prog ia16-unknown-elf-$prog
  done
  popd
fi
if [ "$startpos" -le 3 ]; then
  rm -rf build
  mkdir -p build
  pushd build
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --without-headers --with-newlib --enable-languages=c --disable-libssp --with-as="$PREFIX/bin/ia16-unknown-elf-as"
  make $PARALLEL
  make install
  popd
fi
if [ "$startpos" -le 4 ]; then
  rm -rf build-newlib
  mkdir -p build-newlib
  pushd build-newlib
  ../newlib-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX"
  make
  make install
  popd
fi
if [ "$startpos" -le 5 ]; then
  rm -rf build2
  mkdir -p build2
  pushd build2
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --disable-libssp --enable-languages=c --with-as="$PREFIX/bin/ia16-unknown-elf-as"
  make $PARALLEL
  make install
  popd
fi
