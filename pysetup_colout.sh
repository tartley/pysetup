#!/usr/bin/env bash

./pysetup.sh "$1" 2>&1 | colout '(?i)(^\+\+? .*)|(^> .*)|(\bwarning\b)|(\berror\b)' white,green,yellow,red dim,bold,bold,bold

