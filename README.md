Homebrew-ArmEabi
================

Homebrew tap for ARM EABI toolchain, dedicated to eCos RTOS

Installation quick guide
------------------------

1. Install the XCode 5.1.1 (or above) command line tools

        sudo xcode-select --install

2. Clean up homebrew installation directory: `/usr/local`

    Be sure that all existing file or directory from a previous installation
    in destination dir `/usr/local` may be overriden, or Homebrew installation scripts may fail with various errors.

    It is safer to move out the whole `/usr/local` directory, and copy back
    preexisting tools once the Homebrew installation is complete:

        sudo mv /usr/local /usr/local-prev

3. Clean up your current PATH

        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

4. Download and install Homebrew from brew.sh

        ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
        
   Brew have already updated the installation URL in the past. In the event of
   an installation failure due to an invalid URL, please check out the official
   web site to retrieve the updated URL, from http://brew.sh/#install

5. Test your Homebrew installation, and report errors if any

        brew doctor

6. Install the default required packages

        brew install cmake dash gettext git ninja pkg-config readline openssl subversion wget xz

    reject all requests to install 'javac' if any, as you do not need it

7. Add the required Homebrew tap (for versioned tools)

        brew tap homebrew/versions
        brew tap eblot/armeabi
        brew tap eblot/dvb

8. Install toolchains (and their dependencies)

        brew install arm-eabi-gcc45 arm-eabi-gcc46 arm-eabi-gcc49 arm-eabi-sdk ecosconfig

9. Install DVB tools

        brew install redbutton-author opencaster dvbsnoop

10. Do not forget to move back the files and directories that you may want to
    keep from a previous installation, i.e. from `/usr/local-prev` to `/usr/local`.

11. Take some time to clean up your `~/.bashrc` file that you may have 
    customized with a previous installation. You should not need to define
    any `HOMEBREW`* environment variable(s).
 
Configuration
-------------

From a terminal, source the `sdk.sh` script with an SDK version number to
set the proper environment variable for an SDK release. Ex:

    # Set up env for SDK2
    . sdk.sh 2r
