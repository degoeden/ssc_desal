#!/bin/bash

module load matlab/R2025b 
matlab -nojvm -batch "run('./scripts/run_wecsim.m')"