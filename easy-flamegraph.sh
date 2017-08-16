#!/bin/bash

FPATH="$HOME/os/FlameGraph/"
FPERF="$HOME/perf-output/"
PERF_SCRIPT_CMD="perf script"
PERF_REPORT=""
GREP_STRINGS=""
KERNEL_VERSION=""

while getopts "g:i:k:th" opt; do
    case $opt in
        g) GREP_STRINGS=$OPTARG ;;
        i) PERF_REPORT=$OPTARG ;;
        k) KERNEL_VERSION=$OPTARG ;;
        t) TAR=1 ;;
        h|*)
            echo "usage: $0 -g <grep string to make specific flamegraph> -i <perf file> -k <kernel version #>"
            echo "	i - perf report file"
            echo "	k - kernel version - specific kernel version number"
            echo "	g - grep strings - to grep specific strings e.g., kworker, to make flamegraph"
            echo "	t - tar the $FPERF"
            exit 0
            ;;
    esac
done

if [ ! $PERF_REPORT ]; then
    echo "Please use -i to append the perf.data"
    echo "usage: $0 -g <grep string to make specific flamegraph> -i <perf file> -k <kernel version #>"
    echo "	i - perf report file"
    echo "	k - kernel version - specific kernel version number"
    echo "	g - grep strings - to grep specific strings e.g., kworker, to make flamegraph"
    exit -1
fi

if [ ! -e $FPATH ]; then
    echo "please install the FlameGraph by the following instructions:"
    echo "cd ~/os; git clone https://github.com/brendangregg/FlameGraph"
    exit -1
fi

PSCRIPT="${FPERF}`basename ${PERF_REPORT}`.perf"
PFOLDED="${PSCRIPT}.folded"
PSVG="${PFOLDED}.svg"

# mkdir the folder to store the perf report data
mkdir -p ${FPERF}

# perf script -i ./perf-110417_201609 -k ~/ddebs/ddebs-4.4.0-53.74/usr/lib/debug/boot/vmlinux-4.4.0-53-generic > perf-110417_201609.perf
[[ $PERF_REPORT != "" ]] && PERF_SCRIPT_CMD="${PERF_SCRIPT_CMD} -i $PERF_REPORT"
[[ $KERNEL_VERSION != "" ]] && PERF_SCRIPT_CMD="${PERF_SCRIPT_CMD} -k $KERNEL_VERSION"

# generate the perf script file for the stackcollapse to extract the call stack
${PERF_SCRIPT_CMD} > ${PSCRIPT}

# extract the call stack for the flamegraph.pl to generate the svg interactive graph
${FPATH}stackcollapse-perf.pl ${PSCRIPT} > ${PFOLDED}

if [[ $GREP_STRINGS == "" ]]; then
    cat ${PFOLDED} | ${FPATH}flamegraph.pl > ${PSVG}
else
    # add the string name to the SVG name to identify the file easily
    PSVG="${PFOLDED}S$GREP_STRINGS.svg"
    egrep $GREP_STRINGS ${PFOLDED} | ${FPATH}flamegraph.pl > ${PSVG}
fi

[[ $TAR == "1" ]] && tar zcvf perf-data.tar.gz $FPERF &&
echo "# The perf-related file: \"${FPERF}\" has been tared."

echo "###########"
echo "# The perf interactive .svg graph \"${PSVG}\" has been generated."
echo "###########"