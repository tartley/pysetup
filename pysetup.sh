#!/usr/bin/env bash
#
# Given a full python version (e.g. "3.3.5")
#
# Download Python source
# unpack it, compile it, install it.
#
# Install setuptools,
# use that to install pip,
# use that to install virtualenvwrapper.
# (these last three steps will be unecessary for Python 3.4 and above)

PYLONGVER=$1
if [ -z ${PYLONGVER} ]; then
    echo "usage: $0 PYVER # e.g. 3.2.1"
    exit
fi

set -e # exit on first error
set -x # echo commands with expanded variables

PYVER=${PYLONGVER:0:3} # e.g. 3.2
INSTALL_PREFIX=/usr/local

# Refuse to run if this same Python ${PYVER} is already installed
PREVIOUS=$(find ${INSTALL_PREFIX} -name "python${PYVER}*" | tr '\n' ',' )
if [ -n "${PREVIOUS}" ]; then
  set +x
  echo "Warning: Traces of a previously installed Python ${PYVER} found:"
  echo -e "$(echo \"${PREVIOUS}\" | tr ',' '\n')"
  exit 1
fi

ROOT=~/scratch/Python

mkdir -p $ROOT
cd $ROOT

# install prereqs

echo "> Installing prerequisite dependencies..."
if [ ${PYVER:0:1} == "3" ]; then
    PACKAGENAME=python3
else
    PACKAGENAME=python
fi
sudo apt build-dep -qq $PACKAGENAME
sudo apt install -qq build-essential bzip2 libbz2-dev libc6-dev libgdbm-dev liblzma-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev libz-dev openssl tk-dev

# tk8.6-dev (needed by Python3.4.2, is default for Ubuntu 14.04)
# libreadline5-dev
# sqlite3

# if Python source isn't already downloaded
if [ ! -f Python-${PYLONGVER}.tar.xz ]; then
    echo "> Downloading..."
    wget http://www.python.org/ftp/python/${PYLONGVER}/Python-${PYLONGVER}.tar.xz
fi

# if Python source isn't already unpacked
if [ ! -d Python-${PYLONGVER} ]; then
    echo "> Unpacking..."
    tar --checkpoint-action="dot" -xJf Python-${PYLONGVER}.tar.xz
    echo
fi
PYSRC=${ROOT}/Python-${PYLONGVER}

cd $PYSRC
# if no ./python executable exists
if [ ! -f python ]; then
    echo "> Configuring..."
    # --enable-shared and LDFLAGS
    #   To allow PyInstaller to find .so libs.
    # prefix
    #   To specify install location
    # --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu
    #   to cross compile 32 bit output from 64 bit host
    #   32 bit Python is required for PyInstaller to generate 32 bit output,
    #   which will run on both 32 bit and 64 bit machines.
    ./configure \
        --enable-shared \
        LDFLAGS="-Wl,--rpath=${INSTALL_PREFIX}/lib" \
        prefix=${INSTALL_PREFIX}
    echo "> Compiling..."
    # 'altinstall': Prevents the creation of suffixless 'python' symlinking
    # to python3.5, and similar things for shared libs, man pages, etc.
    # 'sudo' because altinstall creates some dirs in $INSTALL_PREFIX :-(
    time sudo make -s -j4 altinstall
fi

# If this version of Python isn't already installed
if [ "$(${INSTALL_PREFIX}/bin/python${PYVER} --version)" != "Python ${PYLONGVER}" ]; then
    echo "> Installing to ${INSTALL_PREFIX}"
    sudo make install
fi

cd ..

# if virtualenvwrapper isn't installed
if [ ! virtualenvwrapper-${PYVER} >/dev/null ]; then
    echo "> Installing virtualenvwrapper..."
    sudo pip${PYVER} install virtualenvwrapper
fi

# No need to install setuptools, it's built-in since Python3.4
# No need to install virtualenv, it's built in to recent Pythons as pyvenv
# No need to install pip, it's built in to recent Pythons, and each virtualenv

