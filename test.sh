#!/bin/bash

export HERE="$(cd $(dirname $0) && pwd)"
export DEJAGNU="$HERE/site.exp"

pushd build2
make -k check RUNTESTFLAGS="--target_board=dosemu $@"
