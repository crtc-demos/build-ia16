#!/bin/bash

set -e
set -o pipefail

SCRIPTDIR="$(dirname "$0")"
export HERE="$(cd "$SCRIPTDIR" && pwd)"
PREFIX="$HERE/prefix"
PARALLEL="-j 8"
#PARALLEL=""

# Set this to false to disable C++ (speed up build a bit).
WITHCXX=false

in_list () {
  local needle=$1
  local haystackname=$2
  local -a haystack
  eval "haystack=( "\${$haystackname[@]}" )"
  for x in "${haystack[@]}"; do
    if [ "$x" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

declare -a BUILDLIST
BUILDLIST=()

while [ $# -gt 0 ]; do
  case "$1" in
    clean|binutils|mklinks|gcc1|newlib|gcc2|sim|test|debug|binutils-debug)
      BUILDLIST=( "${BUILDLIST[@]}" $1 )
      ;;
    all)
      BUILDLIST=("clean" "binutils" "mklinks" "gcc1" "newlib" "gcc2" "sim" "test" "debug" "binutils-debug")
      ;;
    *)
      echo "Unknown option '$1'."
      exit 1
      ;;
  esac
  shift
done

if [ "${#BUILDLIST}" -eq 0 ]; then
  echo "build options: clean binutils mklinks gcc1 newlib gcc2 sim test debug binutils-debug all"
  exit 1
fi

if $WITHCXX; then
  LANGUAGES="c,c++"
  EXTRABUILD2OPTS="--with-newlib"
else
  LANGUAGES="c"
  EXTRABUILD2OPTS=
fi

BIN=$HERE/prefix/bin
if [[ ":$PATH:" != *":$BIN:"* ]]; then
    export PATH="$BIN:${PATH:+"$PATH:"}"
    echo Path set to $PATH
fi

cd "$HERE"

if in_list clean BUILDLIST; then
  echo
  echo "************"
  echo "* Cleaning *"
  echo "************"
  echo
  rm -rf "$PREFIX"
  mkdir -p "$PREFIX/bin"
fi

if in_list binutils BUILDLIST; then
  echo
  echo "*********************"
  echo "* Building binutils *"
  echo "*********************"
  echo
  rm -rf build-binutils
  mkdir build-binutils
  pushd build-binutils
  ../binutils-gdb/configure --target=i386-unknown-elf --prefix="$PREFIX" | tee build.log
  make $PARALLEL | tee -a build.log
  make $PARALLEL install | tee -a build.log
  popd
fi

if in_list binutils-debug BUILDLIST; then
  echo
  echo "***************************"
  echo "* Building debug binutils *"
  echo "***************************"
  echo
  rm -rf build-binutils-debug
  mkdir build-binutils-debug
  pushd build-binutils-debug
  ../binutils-gdb/configure --target=i386-unknown-elf --prefix="$PREFIX" | tee build.log
  make $PARALLEL 'CFLAGS=-g -O0' 'CXXFLAGS=-g -O0' 'BOOT_CFLAGS=-g -O0' | tee -a build.log
  make $PARALLEL install | tee -a build.log
  popd
fi

if in_list mklinks BUILDLIST; then
  echo
  echo "****************"
  echo "* Making links *"
  echo "****************"
  echo
  pushd "$PREFIX/bin"
  for prog in addr2line ar as c++filt elfedit gdb gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip; do
    ln -s i386-unknown-elf-$prog ia16-unknown-elf-$prog
  done
  popd
fi

if in_list gcc1 BUILDLIST; then
  echo
  echo "************************"
  echo "* Building stage 1 GCC *"
  echo "************************"
  echo
  rm -rf build
  mkdir build
  pushd build
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --without-headers --with-newlib --enable-languages=c --disable-libssp --with-as="$PREFIX/bin/ia16-unknown-elf-as" 2>&1 | tee build.log
#--enable-checking=all,valgrind
  make $PARALLEL 2>&1 | tee -a build.log
  make $PARALLEL 2>&1 install | tee -a build.log
  popd
fi

if in_list newlib BUILDLIST; then
  echo
  echo "*****************************"
  echo "* Building Newlib C library *"
  echo "*****************************"
  echo
  rm -rf build-newlib
  mkdir build-newlib
  pushd build-newlib
  ../newlib-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" 2>&1 | tee build.log
  make $PARALLEL 'CFLAGS=-D_IEEE_LIBM' 2>&1 | tee -a build.log
  make install 2>&1 | tee -a build.log
  popd
fi

if in_list gcc2 BUILDLIST; then
  echo
  echo "************************"
  echo "* Building stage 2 GCC *"
  echo "************************"
  echo
  rm -rf build2
  mkdir build2
  pushd build2
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --disable-libssp --enable-languages=$LANGUAGES --with-as="$PREFIX/bin/ia16-unknown-elf-as" $EXTRABUILD2OPTS 2>&1 | tee build.log
  make $PARALLEL 2>&1 | tee -a build.log
  make $PARALLEL install 2>&1 | tee -a build.log
  popd
fi

if in_list sim BUILDLIST; then
  echo
  echo "**********************"
  echo "* Building simulator *"
  echo "**********************"
  echo
  rm 86sim/86sim
  gcc -Wall -O2 86sim/86sim.cpp -o 86sim/86sim
fi

if in_list test BUILDLIST; then
  echo
  echo "*****************"
  echo "* Running tests *"
  echo "*****************"
  echo
  export DEJAGNU="$HERE/site.exp"
  pushd build2
  i=0
  while [[ -e ../fails-$i.txt ]] ; do
    i=$[$i+1]
  done
  make -k check RUNTESTFLAGS="--target_board=86sim" 2>&1 | tee test.log
  grep -E ^FAIL\|^WARNING\|^ERROR\|^XPASS\|^UNRESOLVED gcc/testsuite/gcc/gcc.log > ../fails-$i.txt
  cp gcc/testsuite/gcc/gcc.log ../gcc-$i.log
  popd
fi

if in_list debug BUILDLIST; then
  echo
  echo "**********************"
  echo "* Building debug GCC *"
  echo "**********************"
  echo
  rm -rf build-debug
  mkdir build-debug
  pushd build-debug
  ../gcc-ia16/configure --target=ia16-unknown-elf --prefix="$PREFIX" --disable-libssp --enable-languages=$LANGUAGES --with-as="$PREFIX/bin/ia16-unknown-elf-as" $EXTRABUILD2OPTS 2>&1 | tee build.log
  make $PARALLEL 'CFLAGS=-g -O0' 'CXXFLAGS=-g -O0' 'BOOT_CFLAGS=-g -O0' 2>&1 | tee -a build.log
  popd
fi
