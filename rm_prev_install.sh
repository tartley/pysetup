#!/usr/bin/env bash

PYLONGVER=$1
if [ -z ${PYLONGVER} ]; then
    echo "usage: $0 PYVER # e.g. 3.2.1"
    exit
fi

set -e # exit on first error
set -x # echo commands with expanded variables

PYVER=${PYLONGVER:0:3} # e.g. 3.2
INSTALL_PREFIX=/usr/local

# Delete vestiges of any previous install that we can find
find ${INSTALL_PREFIX} -name "python${PYVER}*" -o -name "*${PYVER}"
find ${INSTALL_PREFIX} -name "python${PYVER}*" -o -name "*${PYVER}" | xargs sudo rm -rf

