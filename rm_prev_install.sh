#!/usr/bin/env bash

set -e # exit on first error
# set -x # echo commands with expanded variables

PYLONGVER=$1
if [ -z ${PYLONGVER} ]; then
    echo "usage: $0 PYVER # e.g. 3.2.1"
    exit
fi

IFS='.' read -ra version_array <<< "$PYLONGVER"
PYVER="${version_array[0]}.${version_array[1]}" # e.g. 3.2
INSTALL_PREFIX=/usr/local

# Delete vestiges of any previous install that we can find
find ${INSTALL_PREFIX} -name "python${PYVER}*" -o -name "*${PYVER}"
find ${INSTALL_PREFIX} -name "python${PYVER}*" -o -name "*${PYVER}" | xargs sudo rm -rf

