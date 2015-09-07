#!/bin/bash
# This file is managed by puppet! Do not change!

modulename="$1"

checkmodule -M -m -o ${modulename}.mod ${modulename}.te &&\
semodule_package -o ${modulename}.pp -m ${modulename}.mod &&\
semodule -i ${modulename}.pp

exit $?
