Homebrew-ArmEabi
================

Homebrew tap for ARM EABI toolchain, dedicated to eCos RTOS

Installation quick guide
------------------------

1. Install the XCode 5.0.1 command line tools

        sudo xcode-select --install

2. clean up homebrew

        cd /usr/local
        mv homebrew homebrew-prev

3. clean up your current PATH

        export PATH=/usr/bin:/bin:/usr/sbin:/sbin

4. Download and install Homebrew from brew.sh

        ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

5. Update your current path

        export PATH=/usr/local/bin:$PATH

6. Test your Homebrew installation, and report errors if any

        brew doctor

7. Install the default required packages

        brew install cmake dash gettext git ninja pkg-config readline openssl subversion wget xz

    * reject all requests to install 'javac'


8. Add the Versions Homebrew tap (for versioned tools)

        brew tap homebrew/versions

9. Install the GCC native compiler (and its old dependencies)

        brew install gcc48

10. Add the Neotion SDK Homebrew tap

        brew tap eblot/armeabi

11. Install toolchains (and their dependencies)

        brew install arm-eabi-gcc45
        brew install arm-eabi-gcc46
        brew install arm-eabi-gcc48
        brew install arm-eabi-sdk

12. Add the Neotion DVB Homebrew tap

        brew tap eblot/dvb

13. Install DVB tools

        brew install redbutton-author

14. Install optional DVB tools  

        brew install opencaster dvbsnoop


Configuration
-------------

From a terminal, source the `sdk.sh` script with an SDK version number to
set the proper environment variable for an SDK release. Ex:

    # Set up env for SDK2
    . sdk.sh 2
