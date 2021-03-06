#!/usr/bin/env bash

# This script is used for feature detection and setting up other configurations that are required to build libast
set -x
set -e

# This script is run from an unspecified directory so we have to determine directory paths
# http://mesonbuild.com/Reference-manual.html#run_command
script_path=`realpath "$0"`
bin_dir=`dirname "$script_path"`
base_dir=`dirname "$bin_dir"`

PATH=$bin_dir:$PATH

c_tests=('sfinit.c' 'signal.c')

mkdir $base_dir/src/lib/libast/features/FEATURE
$base_dir/src/lib/libast/features/siglist.sh > $base_dir/src/lib/libast/features/FEATURE/siglist

pushd "$base_dir/src/lib/libast/features"

"$bin_dir/conf" -v "$base_dir/src/lib/libast/comp/conf.tab" cc -I../include -D_BLD_DLL -D_BLD_ast

for feature_test in ${c_tests[@]}; do
    name=$(echo "$feature_test" | cut -f1 -d.)
    echo "/* This file is autogenerated by libast_prereq.sh script */" > FEATURE/$name
    echo "#ifndef _def_${name}_features" >> FEATURE/$name
    echo "#define _def_${name}_features    1" >> FEATURE/$name
    cc -D_BLD_DLL -D_BLD_ast -I. -I.. -Icomp -I../comp -Iinclude -I../include -Istd -I../std -I../features -o $name "$feature_test" && ./$name >> FEATURE/$name
    echo "#endif" >> FEATURE/$name
    rm -f $name
done

popd

pushd "$base_dir/"
cc -o "$bin_dir/lcgen" "$base_dir/src/lib/libast/port/lcgen.c"
"$bin_dir/lcgen" "$base_dir/src/lib/libast/include/lc.h" "$base_dir/src/lib/libast/port/lctab.c" < "$base_dir/src/lib/libast/port/lc.tab"
popd
