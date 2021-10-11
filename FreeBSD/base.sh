#!/bin/sh
# set -e -u

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

getUsage(){
    echo "Usage: sh base.sh [options...]"
    echo "\t -t: sets target arch"
    echo "\t -b: sets branch to get"
    echo "\t -v: sets version to get"
    echo "\t -j: sets jobs count"
    exit 1
}

export TARGET=""
export BRANCH=""
export VERSION=""
export JOBS=""

while getopts "t:v:b:j:h:" opt
do
   case "$opt" in
      't') TARGET="$OPTARG"  ;;
      'b') BRANCH="$OPTARG"  ;;
      'v') VERSION="$OPTARG" ;;
      'j') JOBS="$OPTARG"    ;;
      'h') getUsage ;;
      *) getUsage   ;;
   esac
done

if [ "${TARGET}" = "" ]; then
    echo "[DEBUG]: No target, specified using default"
    TARGET="amd64"
fi

if [ "${BRANCH}" = "" ]; then
    echo "[DEBUG]: No branch, specified using default"
    BRANCH="stable"
fi

if [ "${VERSION}" = "" ]; then
    echo "[DEBUG]: No version, specified using default"
    VERSION="13"
fi

# Exists for later debugging purposes
# echo "${TARGET}"
# echo "${BRANCH}"
# echo "${VERSION}"
# echo ${JOBS}

# Git management
export PROTOCOL="https"
export HOST="github.com"
export ORG="potabi" # Add if applicable
export REPO="potabi-src"

if [ "${PROTOCOL}" = "https" ]; then
    if [ "${ORG}" = "" ]; then
        export URL="https://${HOST}/${REPO}"
    else
        export URL="https://${HOST}/${ORG}/${REPO}"
    fi
elif [ "${PROTOCOL}" = "ssh" ]; then
    if [ "${ORG}" = "" ]; then
        export URL="git@${HOST}:${REPO}"
    else
        export URL="git@${HOST}:${ORG}/${REPO}"
    fi
fi

export CWD="`realpath | sed 's|/scripts||g'`"
echo "[DEBUG]: Running \"git clone ${URL} -b ${BRANCH}/${VERSION} --depth 1 /usr/src\""
cd /usr/src && git clone ${URL} -b ${BRANCH}/${VERSION} --depth 1 .
if [ "${JOBS}" = "" ]; then
    echo "[DEBUG]: Running make"
    make buildworld buildkernel TARGET=${TARGET}
else
    echo "[DEBUG]: Running make with ${JOBS} jobs"
    make buildworld buildkernel TARGET=${TARGET} -j${JOBS}
fi
cd /usr/src/release
make obj
make real-release NODOCS=1 NOPORTS=1 NOSRC=1 
echo "[DEBUG]: Base compile completed"
echo "[DEBUG]: Check: /usr/obj/usr/src/"
cd ${CWD}