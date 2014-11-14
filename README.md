Homebrew-ArmEabi
================

Homebrew tap for ARM EABI toolchain, dedicated to eCos RTOS

Installation quick guide
------------------------

1. Install XCode 6.1 (or above) and starts it once to agree with the end user
   license

2. Install the XCode command line tools

        sudo xcode-select --install

3. Clean up homebrew installation directory: `/usr/local`

    Be sure that all existing file or directory from a previous installation
    in destination dir `/usr/local` may be overriden, or Homebrew installation scripts may fail with various errors.

    It is safer to move out the whole `/usr/local` directory, and copy back
    preexisting tools once the Homebrew installation is complete:

        sudo mv /usr/local /usr/local-prev

4. Clean up your current PATH

        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

5. Download and install Homebrew from brew.sh

        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        
   Brew have already updated the installation URL in the past. In the event of
   an installation failure due to an invalid URL, please check out the official
   web site to retrieve the updated URL, from http://brew.sh/#install

6. Test your Homebrew installation, and report errors if any

        brew doctor

7. Install the default required packages

        brew install dash gettext git ninja pkg-config readline openssl subversion wget xz

8. Add the required Homebrew tap (for versioned tools)

        brew tap homebrew/versions
        brew tap eblot/armeabi
        brew tap eblot/dvb

9. Install toolchains (and their dependencies)

        brew install arm-eabi-gcc45 arm-eabi-gcc46 arm-eabi-gcc49
        brew install arm-eabi-sdk ecosconfig cmake28 cmake30

   reject all requests to install 'javac', you do not need it

10. Install DVB tools

        brew install redbutton-author opencaster dvbsnoop

11. Do not forget to move back the files and directories that you may want to
    keep from a previous installation, i.e. from `/usr/local-prev` to `/usr/local`.

12. Take some time to clean up your `~/.bashrc` file that you may have 
    customized with a previous installation. You should not need to define
    any `HOMEBREW`* environment variable(s).
 