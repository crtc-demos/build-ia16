#!/bin/bash

export HERE="$(cd $(dirname $0) && pwd)"
BIN = $HERE/prefix/bin

if [[ ":$PATH:" != *":$BIN:"* ]]; then
    export PATH="$BIN${PATH:+"$PATH:"}"
    echo Path set to $PATH
fi

export HERE="$(cd $(dirname $0) && pwd)"
export DEJAGNU="$HERE/site.exp"

pushd build2
make -k check RUNTESTFLAGS="--target_board=dosemu $@"
