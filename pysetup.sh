#!/usr/bin/env bash
#
###################################################
## Consider deprecating this script and using uv ##
## to manage installed python versions instead.  ##
###################################################
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

# convert given 3.x.y to 3.x
IFS='.' read -ra version_array <<< "$PYLONGVER"
PYVER="${version_array[0]}.${version_array[1]}"

INSTALL_PREFIX=/usr/local

# Refuse to run if this same Python ${PYVER} is already installed
PREVIOUS=$(find ${INSTALL_PREFIX} -name "python${PYVER}*" | tr '\n' ',' )
if [ -n "${PREVIOUS}" ]; then
  set +x
  echo "Warning: Traces of a previously installed Python ${PYVER} found:"
  echo -e "$(echo ${PREVIOUS} | tr ',' '\n')"
  exit 1
fi

ROOT=/tmp/Python

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
        gdb \
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
        nis \
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

config_flags="\
--quiet \
--enable-optimizations \
prefix=${INSTALL_PREFIX} \
"
if [ -v PYINSTALLER ] ; then
    # --enable-shared and LDFLAGS:
    #   To allow PyInstaller to find .so libs.
    # --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu:
    #   to cross compile 32 bit output from 64 bit host
    #   32 bit Python is required for PyInstaller to generate 32 bit output,
    #   which will run on both 32 bit and 64 bit machines.
    config_flags+="\
--enable-shared \
--build=x86_64-pc-linux-gnu \
--host=i686-pc-linux-gnu \
LDFLAGS=-Wl,--rpath=${INSTALL_PREFIX}/lib \
"

fi

echo "Configure flags: $config_flags"

./configure $config_flags

#############################################################
echo "> Compiling..."
time make -s -j6
# value of 6 measured as "best", see spreadsheet in this dir

#############################################################
echo "> Installing to ${INSTALL_PREFIX}"
# 'altinstall': Prevents the creation of suffixless 'python' symlinking
# to pythonX.Y, and similar things for shared libs, man pages, etc.
sudo make -s altinstall >/tmp/python-altinstall.out

# No need to install setuptools, it's built-in since Python3.4
# No need to install virtualenv, it's built in to recent Pythons as "-m venv"
# No need to install pip, it's built in to each virtualenv
# No need to install virtualenvwrapper. Use ve & workon.

