#!/bin/bash

###################################################################
# Fetch Google Protobuf from the GitHub repo.  We are going to
# build the master branch, so this is bleeding edge stuff! ;-)
###################################################################

PROTOBUF_SRC_DIR=/tmp/protobuf
(
    if [ -d ${PROTOBUF_SRC_DIR} ]
    then
        rm -rf ${PROTOBUF_SRC_DIR}
    fi
    cd `dirname ${PROTOBUF_SRC_DIR}`
    git clone https://github.com/google/protobuf.git
)

# The results will be stored relative to the location
# where you stored this script, **not** relative to
# the location of the protobuf git repo.
PREFIX=`pwd`/protobuf
if [ -d ${PREFIX} ]
then
    rm -rf "${PREFIX}"
fi
mkdir -p "${PREFIX}/platform"

###################################################################
# Build variables. The stuff in this section controls the outcome
# of the build process.  It selects the iOS SDK version based
# on how xcrun is currently configured.
###################################################################

DARWIN=darwin13.4.0

BUILD_MAXOSX_X86_64=YES
BUILD_I386_IOS=YES
BUILD_IOS_ARMV7=YES
BUILD_IOS_ARMV7S=YES
BUILD_IOS_ARMV64=YES

XCODEDIR=`xcode-select --print-path`
IOS_SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
MIN_SDK_VERSION=7.1

MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
MACOSX_SYSROOT=${MACOSX_PLATFORM}/Developer/MacOSX10.9.sdk

IPHONEOS_PLATFORM=`xcrun --sdk iphoneos --show-sdk-platform-path`
IPHONEOS_SYSROOT=`xcrun --sdk iphoneos --show-sdk-path`

IPHONESIMULATOR_PLATFORM=`xcrun --sdk iphonesimulator --show-sdk-platform-path`
IPHONESIMULATOR_SYSROOT=`xcrun --sdk iphonesimulator --show-sdk-path`

CC=clang
CFLAGS="--verbose -DNDEBUG -g -O0 -pipe -fPIC -fcxx-exceptions"

CXX=clang
CXXFLAGS="--verbose ${CFLAGS} -std=c++11 -stdlib=libc++"

LDFLAGS="-stdlib=libc++"
LIBS="-lc++ -lc++abi"

###################################################################
# The following section is lifted from the autogen.sh script that
# is part of the protobuf source code. It verifies we are in the
# correct folder and fetches the version if Google Test that is
# used by for unit tests.
###################################################################

# Check that we're being run from the right directory.
if test ! -f src/google/protobuf/stubs/common.h; then
  cat >&2 << __EOF__
Could not find source code.  Make sure you are running this script from the
root of the distribution tree.
__EOF__
  exit 1
fi

# Check that gtest is present. Older versions of protobuf were stored in SVN
# and the gtest directory was setup as an SVN external.  Now, protobuf is
# stored in GitHub and the gtest directory is not included. The commands
# below will grab the latest version of gtest. Currently that is 1.7.0.
if test ! -e gtest; then
  echo "Google Test not present.  Fetching gtest-1.7.0 from the web..."
  curl --location http://googletest.googlecode.com/files/gtest-1.7.0.zip --output gtest-1.7.0.zip
  unzip gtest-1.7.0.zip
  rm gtest-1.7.0.zip
  mv gtest-1.7.0 gtest
fi

###################################################################
# This section contains the build commands to create the native
# protobuf library for Mac OS X.  This is done first so we have
# a copy of the protoc compiler.  It will be used in all of the
# susequent iOS builds.
###################################################################

echo "###################################################################"
echo "# x86_64 for Mac OS X"
echo "###################################################################"

if [ "${BUILD_MACOSX_X86_64}" == "YES" ]
then
    (
        make distclean
        ./configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/x86_64 "CC=${CC}" "CFLAGS=${CFLAGS} -arch x86_64" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch x86_64" "LDFLAGS=${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
    )
fi

###################################################################
# This section contains the build commands for each of the 
# architectures that will be included in the universal binaries.
###################################################################

echo "###########################"
echo "# i386 for iPhone Simulator"
echo "###########################"

if [ "${BUILD_I386_IOS}" == "YES" ]
then
    (
        make distclean
        ./configure --build=x86_64-apple-${DARWIN} --host=i386-apple-${DARWIN} --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/i386 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" LDFLAGS="-arch i386 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
    )
fi

echo "##################"
echo "# armv7 for iPhone"
echo "##################"

if [ "${BUILD_IOS_ARMV7}" == "YES" ]
then
    (
        make distclean
        ./configure --build=x86_64-apple-${DARWIN} --host=armv7-apple-${DARWIN} --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
    )
fi

echo "###################"
echo "# armv7s for iPhone"
echo "###################"

if [ "${BUILD_IOS_ARMV7S}" == "YES" ]
then
    (
        make distclean
        ./configure --build=x86_64-apple-${DARWIN} --host=armv7s-apple-${DARWIN} --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7s "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7s -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
    )
fi

########################################
# Patch Protobuf 2.5.0 for 64bit support
########################################

# (
#     cd /tmp/${PROTOBUF_FOLDER}
#     make distclean
#     curl https://gist.github.com/BennettSmith/7111094/raw/171695f70b102de2301f5b45d9e9ab3167b4a0e8/0001-Add-generic-GCC-support-for-atomic-operations.patch --output /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
#     curl https://gist.github.com/BennettSmith/7111094/raw/a4e85ffc82af00ae7984020300db51a62110db48/0001-Add-generic-gcc-header-to-Makefile.am.patch --output /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
#     patch -p1 < /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
#     patch -p1 < /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
#     rm /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
#     rm /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
# )

echo "##################"
echo "# arm64 for iPhone"
echo "##################"

if [ "${BUILD_IOS_ARMV64}" == "YES" ]
then
    (
        ./configure --build=x86_64-apple-${DARWIN} --host=arm --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/arm64 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch arm64 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
    )
fi

###################################################################
# Create Universal Libraries
###################################################################

(
    cd ${PREFIX}/platform
    mkdir universal
    lipo x86_64/lib/libprotobuf.a arm64/lib/libprotobuf.a armv7s/lib/libprotobuf.a armv7/lib/libprotobuf.a i386/lib/libprotobuf.a -create -output universal/libprotobuf.a
    lipo x86_64/lib/libprotobuf-lite.a arm64/lib/libprotobuf-lite.a armv7s/lib/libprotobuf-lite.a armv7/lib/libprotobuf-lite.a i386/lib/libprotobuf-lite.a -create -output universal/libprotobuf-lite.a
)

###################################################################
# Finalize the packaging
###################################################################

(
    cd ${PREFIX}
    mkdir bin
    mkdir lib
    cp -r platform/x86_64/bin/protoc bin
    cp -r platform/x86_64/lib/* lib
    cp -r platform/universal/* lib
    rm -rf platform
)

echo Done!

