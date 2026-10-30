#!/usr/bin/env bash
set -euo pipefail

matlab25 -batch "run('./scripts/run_wecsim.m')"
