require 'formula'

class NoFileStrategy <AbstractDownloadStrategy
    # Intended No-op
end

class ArmEabiSdk <Formula

  url 'none', :using => NoFileStrategy
  version '1.3.1'
  sha1 ''

  def install
    #mkdir "#{prefix}/bin"
    bin.mkpath
    path = bin+"sdk.sh"
    path.write <<-EOS.undent
      #!/bin/sh
      
      usage()
      {
          NAME=`basename $0`
          echo "$NAME <sdk_version> [gcc_version]"
          echo "Set up Neotion SDK toolchain"
      }
      
      if [ $# -lt 1 ]; then
          usage
          return
      fi
      
      SDK_VERSION="$1"
      
      case "${SDK_VERSION}" in
          1)
              PYTHONVER="26"
              GCC_VERSION="6"
              CMAKE_VERSION="28"
              ;;
          2)
              PYTHONVER="27"
              GCC_VERSION="6"
              CMAKE_VERSION="28"
              ;;
          2[r-z]|2[R-Z])
              PYTHONVER="27"
              GCC_VERSION="9"
              CMAKE_VERSION="30"
              ;;
          3)
              PYTHONVER="33"
              GCC_VERSION="8"
              CMAKE_VERSION="30"
              ;;
          *)
              echo "Unsupported SDK variant: ${SDK_VERSION}" >&2
              return
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
          9)
              NEOSDK_ARMCC_VER="4.9.1"
              NEOSDK_ARMBU_VER="2.24"
              ;;
          *)
              echo "Unsupported GCC variant: ${GCC_VERSION}" >&2
              return
              ;;
      esac
      
      OPTPATH="/usr/local/opt"
      ARMCCVER=`echo "${NEOSDK_ARMCC_VER}" | cut -d. -f1-2 | tr -d .`
      ARMBUVER=`echo "${NEOSDK_ARMBU_VER}" | cut -d. -f1-2 | tr -d .`
      PYTHONPATH=/usr/local/py${PYTHONVER}/bin
      ARMBUPATTERN="${OPTPATH}/arm-eabi-binutils${ARMBUVER}"
      ARMBUPATH=`ls -1d "${ARMBUPATTERN}"*/bin | tail -1`
      ARMCCPATH=${OPTPATH}/arm-eabi-gcc${ARMCCVER}/bin
      CMAKEPATH=${OPTPATH}/cmake${CMAKE_VERSION}/bin
      SYSPATH=/usr/bin:/bin:/usr/sbin:/sbin
      GETTEXTPATH=`ls -1d /usr/local/Cellar/gettext/*/bin | tail -1`
      
      export PATH=${PYTHONPATH}:${ARMCCPATH}:${ARMBUPATH}:${CMAKEPATH}:${GETTEXTPATH}:/usr/local/bin:${SYSPATH}
      export NEOSDK_ARMCC_VER
      export NEOSDK_ARMBU_VER
      
      PYTHONVERSTR="`echo "${PYTHONVER}" | cut -c1`.`echo "${PYTHONVER}" | cut -c2`"
      CMAKEVERSTR=`${CMAKEPATH}/cmake --version 2>&1 | head -1 | sed s'/^[^0-9\.]*//'`
      echo "GCC v${NEOSDK_ARMCC_VER}, Binutils v${NEOSDK_ARMBU_VER}, Python v${PYTHONVERSTR}, CMake v${CMAKEVERSTR}"
    EOS
  end
end
