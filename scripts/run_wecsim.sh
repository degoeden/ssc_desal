#!/bin/bash

PTO_ARCH=${1:-basic}
RESISTANCE=${2:-low}
MEMBRANE=${3:-solution}
FEED_X=${4:-36}
PERM_X=${5:-0.7}
HS=${6:-2.64}
TP=${7:-9.86}

echo "PTO_ARCH: ${PTO_ARCH}"

module load matlab/R2025b 
matlab -nojvm -batch "PTO_arch='${PTO_ARCH}'; resistance='${RESISTANCE}'; membrane='${MEMBRANE}'; feed_x=${FEED_X}; perm_x=${PERM_X}; Hs=${HS}; Tp=${TP}; run('./scripts/run_wecsim.m')"