#!/usr/bin/env bash
#
# Given a full python version (e.g. "pysetup.sh 3.3.5")
#
# Download Python source from python.org,
# unpack it, compile it, install it.
#
# Install setuptools,
# use that to install pip,
# use that to install virtualenvwrapper.
# (these last three steps will be unecessary for Python 3.4 and above)

set -u # fail in uninitialized variables
set -e # exit on first error
# set -x # echo commands with expansions done

PYLONGVER=$1
if [ -z ${PYLONGVER} ]; then
    echo "usage: $0 PYVER # e.g. 3.2.1"
    exit
fi

PYVER=${PYLONGVER:0:3} # e.g. 3.2
INSTALL_PREFIX=/usr/local

# Refuse to run if this same Python ${PYVER} is already installed
PREVIOUS=$(find ${INSTALL_PREFIX} -name "python${PYVER}*" | tr '\n' ',' )
if [ -n "${PREVIOUS}" ]; then
  set +x
  echo "Warning: Traces of a previously installed Python ${PYVER} found:"
  echo -e "$(echo ${PREVIOUS} | tr ',' '\n')"
  exit 1
fi

ROOT=~/scratch/Python

mkdir -p $ROOT
cd $ROOT

# install prereqs

echo "> Installing prerequisites..."
if [ ${PYVER:0:1} == "3" ]; then
    PACKAGENAME=python3
else
    PACKAGENAME=python
fi

if hash apt 2>/dev/null; then
    # Ubuntu/Debian
    sudo apt build-dep -qq $PACKAGENAME
    sudo apt install \
        -y -qq \
        build-essential \
        bzip2 \
        libbz2-dev \
        libc6-dev \
        libffi-dev \
        libgdbm-compat-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libz-dev \
        openssl \
        tk-dev
else
    # RHEL
    sudo yum groupinstall 'Development Tools' -q -y --skip-broken
    sudo yum install \
        bzip2-devel \
        gcc \
        gcc-c++ \
        gdbm-devel \
        glibc-devel \
        libffi-devel \
        libuuid-devel \
        make \
        ncurses-devel \
        openssl-devel \
        readline-devel \
        sqlite-devel \
        tk-devel \
        xz-devel \
        zlib2-devel \
        zlib-devel \
        -q -y
fi
# omitted from serverfault answer because they seem wrong to me:
# python-devel openssl-perl libjpeg-turbo libjpeg-turbo-devel giflib
# tkinter tk kernel-headers glibc libpng wget

# tk8.6-dev (needed by Python3.4.2, is included by default for Ubuntu 14.04)
# libreadline5-dev (readline at REPL works without this. Also, newer versions exist)
# sqlite3 (perhaps only needed at runtime?)

#############################################################
downloadname="Python-${PYLONGVER}.tar.xz"
echo "> Downloading $downloadname"
if [ ! -f "$downloadname" ]; then
    wget --progress=bar:force "http://www.python.org/ftp/python/${PYLONGVER}/$downloadname"
else
    echo "skipping"
fi

#############################################################
echo "> Unpacking..."
if [ ! -d Python-${PYLONGVER} ]; then
    tar --checkpoint-action="dot" -xJf Python-${PYLONGVER}.tar.xz
    echo
else
    echo "skipping"
fi
PYSRC=${ROOT}/Python-${PYLONGVER}

#############################################################
echo "> Configuring..."
cd $PYSRC

pyinstaller_flags=""
if [ -n "${PYINSTALLER+x}" ] ; then
    # --enable-shared and LDFLAGS:
    #   To allow PyInstaller to find .so libs.
    # --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu:
    #   to cross compile 32 bit output from 64 bit host
    #   32 bit Python is required for PyInstaller to generate 32 bit output,
    #   which will run on both 32 bit and 64 bit machines.
    pyinstaller_flags="\
        --enable-shared \
        --build=x86_64-pc-linux-gnu \
        --host=i686-pc-linux-gnu \
        LDFLAGS=-Wl,--rpath=${INSTALL_PREFIX}/lib \
    "
fi

./configure \
    --quiet \
    --enable-optimizations \
    prefix=${INSTALL_PREFIX} \
    $pyinstaller_flags
# Recommended for release builds, but adds a 30-minute profiling step:
#   --enable-optimizations \

#############################################################
echo "> Compiling..."
time make -s -j4

#############################################################
echo "> Installing to ${INSTALL_PREFIX}"
# 'altinstall': Prevents the creation of suffixless 'python' symlinking
# to pythonX.Y, and similar things for shared libs, man pages, etc.
sudo make -s altinstall >/tmp/python-altinstall.out

#############################################################
echo "> Installing virtualenvwrapper-${PYVER}..."
if [ virtualenvwrapper-${PYVER} >/dev/null ]; then
    python${PYVER} -m pip install --user virtualenvwrapper
fi

# No need to install setuptools, it's built-in since Python3.4
# No need to install virtualenv, it's built in to recent Pythons as "-m venv"
# No need to install pip, it's built in to recent Pythons, and each virtualenv

