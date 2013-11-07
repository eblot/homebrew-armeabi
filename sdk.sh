#!/bin/sh

usage()
{
    NAME=`basename $0`
    echo "$NAME <sdk_version> [gcc_version]"
    echo "Set up Neotion SDK toolchain"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

SDK_VERSION="$1"

case "${SDK_VERSION}" in
    1)
        PYTHONVER="26"
        GCC_VERSION="6"
        ;;
    2)
        PYTHONVER="27"
        GCC_VERSION="6"
        ;;
    3)
        PYTHONVER="33"
        GCC_VERSION="8"
        ;;
    *)
        echo "Unsupported SDK variant: ${SDK_VERSION}" >&2
        exit 1
        ;;
esac

if [ $# -gt 1 ]; then
    GCC_VERSION="$2"
fi

case "${GCC_VERSION}" in
    3)
        NEOSDK_ARMCC_VER="4.3.6"
        NEOSDK_ARMBU_VER="2.20.1"
        ;;
    5)
        NEOSDK_ARMCC_VER="4.5.4"
        NEOSDK_ARMBU_VER="2.21.1"
        ;;
    6)
        NEOSDK_ARMCC_VER="4.6.4"
        NEOSDK_ARMBU_VER="2.21.1"
        ;;
    8)
        NEOSDK_ARMCC_VER="4.8.2"
        NEOSDK_ARMBU_VER="2.23.2"
        ;;
    *)
        echo "Unsupported GCC variant: ${GCC_VERSION}" >&2
        exit 1
        ;;
esac

ARMCCVER=`echo "${NEOSDK_ARMCC_VER}" | cut -d. -f1-2 | tr -d .`
ARMBUVER=`echo "${NEOSDK_ARMBU_VER}" | cut -d. -f1-2 | tr -d .`
PYTHONPATH=/usr/local/py${PYTHONVER}/bin
ARMBUPATTERN="/usr/local/Cellar/arm-eabi-binutils${ARMBUVER}/${NEOSDK_ARMBU_VER}"
ARMBUPATH=`ls -1d "${ARMBUPATTERN}"?/bin | tail -1`
ARMCCPATH=/usr/local/Cellar/arm-eabi-gcc${ARMCCVER}/${NEOSDK_ARMCC_VER}/bin
SYSPATH=/usr/bin:/bin:/usr/sbin:/sbin
GETTEXTPATH=`ls -1d /usr/local/Cellar/gettext/*/bin | tail -1`

export PATH=${PYTHONPATH}:${ARMCCPATH}:${ARMBUPATH}:${GETTEXTPATH}:/usr/local/bin:${SYSPATH}
export NEOSDK_ARMCC_VER
export NEOSDK_ARMBU_VER
