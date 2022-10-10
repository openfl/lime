#!/usr/bin/env sh
# HashLink needs a specific working directory to find hlboot.dat and libraries
cd "$(dirname "$0")"
exec ./hl "$@"