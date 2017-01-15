#!/bin/sh
git clone git@github.com:crtc-demos/gcc-ia16.git
git clone git@github.com:crtc-demos/newlib-ia16.git
git clone git://sourceware.org/git/binutils-gdb.git
git clone -b devel git://git.code.sf.net/p/dosemu/code dosemu
wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2
tar -xjf gmp-6.1.2.tar.bz2
wget http://www.mpfr.org/mpfr-current/mpfr-3.1.5.tar.bz2
tar -xjf mpfr-3.1.5.tar.bz2
wget ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
tar -xzf mpc-1.0.3.tar.gz
