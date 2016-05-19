Homebrew-ArmEabi
================

Homebrew tap for ARM EABI toolchain, dedicated to eCos RTOS

Installation quick guide
------------------------

1. Install XCode 6.1 (or above) and starts it once to agree with the end user
   license

2. Install the XCode command line tools

        sudo xcode-select --install

3. Clean up your current PATH

        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

4. Download and install Homebrew from brew.sh

        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

   Brew have already updated the installation URL in the past. In the event of
   an installation failure due to an invalid URL, please check out the official
   web site to retrieve the updated URL, from http://brew.sh/#install

5. Test your Homebrew installation, and report errors if any

        brew doctor

6. Install the default required packages

        brew install dash gettext git ninja pkg-config readline openssl subversion wget xz

7. Add the required Homebrew tap (for versioned tools)

        brew tap homebrew/versions
        brew tap eblot/armeabi
        brew tap eblot/dvb
        brew tap eblot/devtools

8. Install toolchains (and their dependencies)
   Reject all requests to install 'javac', you do not need it.

    * All SDKs

            brew install ecosconfig arm-eabi-gdb
            brew install sdk-script sbx-script

    * To build for all SDK1 series

            brew install cmake28 arm-eabi-gcc45
            brew unlink  cmake28

    * To build for SDK2 A to P series

            brew install cmake28 arm-eabi-gcc46
            brew unlink  cmake28

    * To build for SDK2 R to W series

            brew install cmake30 arm-eabi-gcc49
            brew unlink  cmake30

    * To build for SDK2 X+ series

            brew install cmake33 arm-eabi-gcc52
            brew unlink  cmake33


9. Install DVB tools

        brew install redbutton-author opencaster dvbsnoop

10. Do not forget to move back the files and directories that you may want to
    keep from a previous installation, i.e. from `/usr/local-prev` to `/usr/local`.

11. Take some time to clean up your `~/.bashrc` file that you may have
    customized with a previous installation. You should not need to define
    any `HOMEBREW`* environment variable(s).

