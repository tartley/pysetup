#!/usr/bin/env bash

# Invokes pysetup.py, colorizing the output to make it easy to read.
# Requirements: 'pip install colout'.

./pysetup.sh "$1" 2>&1 | colout '(?i)(^\+\+? .*)|(^> .*)|(\bwarning\b)|(\berror\b)' white,green,yellow,red dim,bold,bold,bold

