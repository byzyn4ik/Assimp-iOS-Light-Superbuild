# Define text colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
NOCOLOR=`tput sgr0`

echo -e "Welcome to ${GREEN}Assimp-iOS-Lite${NOCOLOR} build script 🙂\n"

BUILD_FROM_MASTER=false

echo -e "Would you like to build the lib from last release version (4.1.0)?  [y/n] 🤔"
read BUILD_VERSION_ANSWER
case "$BUILD_VERSION_ANSWER" in
  [yY][eE][sS]|[yY])
  BUILD_FROM_MASTER=false
  ;;
  *)
  printf "\n"
  echo "OK, we'll use master branch."
  BUILD_FROM_MASTER=true
  ;;
esac

# Get assimp sources
ASSIMP_SOURCES_FOLDER=""
printf "\n"
echo -e "Do you have a local copy of ${MAGENTA}Assimp${NOCOLOR} sources from ${YELLOW}GitHub${NOCOLOR}? [y/n] 🤔"
read SOURCE_CODE
case "$SOURCE_CODE" in
  [yY][eE][sS]|[yY])
  printf "\n"
  echo "Please enter the path to ${MAGENTA}Assimp${NOCOLOR} ${YELLOW}sources folder${NOCOLOR}. [For example '${GREEN}../../assimp/${NOCOLOR}']"
  read SOURCES_FOLDER

  cd $SOURCES_FOLDER > /dev/null
  if [ -d .git ]; then
    ASSIMP_SOURCES_FOLDER=$SOURCES_FOLDER
  else
    printf "\n"
    echo "Unfortunately this is ${RED}not a git folder${NOCOLOR}. We need a ${GREEN}git forlder${NOCOLOR} that contains Assimp sources."
  fi;
  cd - > /dev/null
  ;;
esac

if [ "$ASSIMP_SOURCES_FOLDER" = "" ]
then
  printf "\n"
  echo "OK, let's download the source code from ${YELLOW}GitHub${NOCOLOR}. Please enter the path to ${YELLOW}save-to directory${NOCOLOR}. [For example '${GREEN}../../assimp/${NOCOLOR}']"
  read DOWNLOAD_FOLDER
  # Refresh download folder
  sudo rm -rf $DOWNLOAD_FOLDER
  mkdir $DOWNLOAD_FOLDER
  # Clone sources from GitHub
  git clone https://github.com/assimp/assimp.git --recursive $DOWNLOAD_FOLDER
  printf "\n"
  echo "Successfully downloaded  ${MAGENTA}Assimp${NOCOLOR} sources from ${YELLOW}GitHub${NOCOLOR} to ${GREEN}$DOWNLOAD_FOLDER${NOCOLOR} 👌"
  ASSIMP_SOURCES_FOLDER=$DOWNLOAD_FOLDER
fi

# Make sure ASSIMP_SOURCES_FOLDER sting ends with "/"
if [ "${ASSIMP_SOURCES_FOLDER:$((${#ASSIMP_SOURCES_FOLDER}-1)):1}" != "/" ]
then
  ASSIMP_SOURCES_FOLDER+="/"
fi

# Checkout 4.1.0
if [ $BUILD_FROM_MASTER == true ]; then
  cd $ASSIMP_SOURCES_FOLDER > /dev/null && git checkout master && cd - > /dev/null
else
  cd $ASSIMP_SOURCES_FOLDER > /dev/null && git checkout 80799bdbf90ce626475635815ee18537718a05b1 && cd - > /dev/null
fi;

# Get build folder path
printf "\n"
echo -e "Please, enter the path to the temporary build folder. [For example '${GREEN}../../assimp-ios-lite-build/${NOCOLOR}']"
read BUILD_DIR

# Make sure BUILD_DIR sting ends with "/"
if [ "${BUILD_DIR:$((${#BUILD_DIR}-1)):1}" != "/" ]
then
  BUILD_DIR+="/"
fi

# Refresh build folder
sudo rm -rf $BUILD_DIR
mkdir $BUILD_DIR

# Begin to construct arguments for build script
printf "\n"
echo "${MAGENTA}Assimp${NOCOLOR} includes the following importers: ${YELLOW}3DS, 3D, 3MF, AC, AMF, ASE, ASSBIN, ASSXML, B3D, BLEND, BVH, COB, COLLADA, CSM, DXF, FBX, GLTF, HMP, IFC, IRRMESH, IRR, LWO, LWS, MD2, MD3, MD5, MDC, MDL, MMD, MS3D, NDO, NFF, C4D, OBJ, OFF, OGRE, OPENGEX, PLY, Q3BSP, Q3D, RAW, SIB, SMD, STL, TERRAGEN, X3D, XGL, X ${NOCOLOR}."
printf "\n"
echo "Please, enter the names of the importers you'd like to include. [For example: '${GREEN}OBJ COLLADA FBX GLTF${NOCOLOR}'. Type '${GREEN}all${NOCOLOR}' to include all the importers.]"
read ARRAY_OF_IMPORTERS_TO_INCLUDE

# Create an array containig selected IMPORTERs
FILTERED_ARRAY_OF_IMPORTERS=()
for IMPORTER in $ARRAY_OF_IMPORTERS_TO_INCLUDE
do
  case $IMPORTER in
    3DS | 3D | 3MF | AC | AMF | ASE | ASSBIN | ASSXML | B3D | BLEND | BVH | COB | COLLADA | CSM | DXF | FBX | GLTF | HMP | IFC | IRRMESH | IRR | LWO | LWS | MD2 | MD3 | MD5 | MDC | MDL | MMD | MS3D | NDO | NFF | C4D | OBJ | OFF | OGRE | OPENGEX | PLY | Q3BSP | Q3D | RAW | SIB | SMD | STL | TERRAGEN | X3D | XGL | X)
    FILTERED_ARRAY_OF_IMPORTERS+=($IMPORTER)
    ;;
    all)
    FILTERED_ARRAY_OF_IMPORTERS+=("3DS 3D 3MF AC AMF ASE ASSBIN ASSXML B3D BLEND BVH COB COLLADA CSM DXF FBX GLTF HMP IFC IRRMESH IRR LWO LWS MD2 MD3 MD5 MDC MDL MMD MS3D NDO NFF C4D OBJ OFF OGRE OPENGEX PLY Q3BSP Q3D RAW SIB SMD STL TERRAGEN X3D XGL X")
    ;;
    *)
    printf "\n"
    echo "You've made a mistake in a module name ${RED}$IMPORTER${NOCOLOR} 😕"
    ;;
  esac
done
# Filter for duplication
FILTERED_ARRAY_OF_IMPORTERS=($(tr ' ' '\n' <<< "${FILTERED_ARRAY_OF_IMPORTERS[@]}" | sort -u | tr '\n' ' '))
printf "\n"
echo "Generating a list of importers you selected"
echo "List of importers to include: ${GREEN}'${FILTERED_ARRAY_OF_IMPORTERS[@]}'${NOCOLOR}."

# Construct IMPORTER flags
ARRAY_OF_IMPORTER_FLAGS=()
ARRAY_OF_IMPORTER_FLAGS+=("-DASSIMP_BUILD_ALL_IMPORTERS_BY_DEFAULT=OFF")
for IMPORTER in "${FILTERED_ARRAY_OF_IMPORTERS[@]}"
do
  IMPORTER_flag="-DASSIMP_BUILD_${IMPORTER}_IMPORTER=ON"
  ARRAY_OF_IMPORTER_FLAGS+=($IMPORTER_flag)
done

# Select archs
printf "\n"
echo "You are able to build a multiple architecture fat library. Please, choose the names of the architectures [${YELLOW}armv7 armv7s arm64 i386 x86_64${NOCOLOR}] you'd like to include. [For example: '${GREEN}arm64 x86_64${NOCOLOR}'. Type '${GREEN}all${NOCOLOR}' to include all the archs.]"
read SELECTED_ARCHS_TO_BUILD

FILTERED_ARRAY_OF_ARCHS=()
for arch in $SELECTED_ARCHS_TO_BUILD
do
  case $arch in
    armv7 | armv7s | arm64 | i386 | x86_64)
    FILTERED_ARRAY_OF_ARCHS+=($arch)
    ;;
    all)
    FILTERED_ARRAY_OF_ARCHS+=("armv7 armv7s arm64 i386 x86_64")
    ;;
    *)
    printf "\n"
    echo "You've made a mistake in arch name ${RED}$arch${NOCOLOR} 😕"
    ;;
  esac
done
# Filter for duplication
FILTERED_ARRAY_OF_ARCHS=($(tr ' ' '\n' <<< "${FILTERED_ARRAY_OF_ARCHS[@]}" | sort -u | tr '\n' ' '))

# Define necessary vars
IOS_SDK_VERSION=
IOS_SDK_TARGET=6.0
#(iPhoneOS iPhoneSimulator) -- determined from arch
IOS_SDK_DEVICE=

XCODE_ROOT_DIR=/Applications/Xcode.app/Contents
TOOLCHAIN=$XCODE_ROOT_DIR//Developer/Toolchains/XcodeDefault.xctoolchain

BUILD_ARCHS_DEVICE="armv7 armv7s arm64"
BUILD_ARCHS_SIMULATOR="i386 x86_64"
BUILD_ARCHS_ALL=(armv7 armv7s arm64 i386 x86_64)

CPP_DEV_TARGET_LIST=(miphoneos-version-min mios-simulator-version-min)
CPP_DEV_TARGET=
CPP_STD_LIB_LIST=(libc++ libstdc++)
CPP_STD_LIB=
CPP_STD_LIST=(c++11 c++14)
CPP_STD=

# Select std libs
printf "\n"
echo "Which of c++ std libs should be used ${GREEN}libc++${NOCOLOR} or ${GREEN}libstdc++${NOCOLOR}?"
read SELECTED_CPP_STD_LIB
if [ "$SELECTED_CPP_STD_LIB" != "libc++" ] && [ "$SELECTED_CPP_STD_LIB" != "libstdc++" ]
then
  printf "\n"
  echo "You've made a mistake in ${RED}$SELECTED_CPP_STD_LIB${NOCOLOR} 😕 "
  printf "\n"
  echo "Using libc++ by default."
  SELECTED_CPP_STD_LIB="libc++"
fi

# Select c++ standard
printf "\n"
echo "Which of c++ standarts should be used ${GREEN}c++11${NOCOLOR} or ${GREEN}c++14${NOCOLOR}?"
read SELECTED_CPP_STANDART
if [ "$SELECTED_CPP_STANDART" != "c++11" ] && [ "$SELECTED_CPP_STD_LIB" != "c++14" ]
then
  printf "\n"
  echo "You've made a mistake in ${RED}$SELECTED_CPP_STANDART${NOCOLOR} 😕 "
  printf "\n"
  echo "Using c++11 by default."
  printf "\n"
  SELECTED_CPP_STANDART="c++11"
fi



function join { local IFS="$1"; shift; echo "$*"; }

build_arch()
{
    IOS_SDK_DEVICE=iPhoneOS
    CPP_DEV_TARGET=${CPP_DEV_TARGET_LIST[0]}

    if [[ "$BUILD_ARCHS_SIMULATOR" =~ "$1" ]]
    then
        echo '[!] Target SDK set to SIMULATOR.'
        IOS_SDK_DEVICE=iPhoneSimulator
        CPP_DEV_TARGET=${CPP_DEV_TARGET_LIST[1]}
    else
        echo '[!] Target SDK set to DEVICE.'
    fi

    unset DEVROOT SDKROOT CFLAGS LDFLAGS CPPFLAGS CXXFLAGS

    export DEVROOT=$XCODE_ROOT_DIR/Developer/Platforms/$IOS_SDK_DEVICE.platform/Developer
    export SDKROOT=$DEVROOT/SDKs/$IOS_SDK_DEVICE$IOS_SDK_VERSION.sdk
    export CFLAGS="-arch $1 -pipe -no-cpp-precomp -stdlib=$CPP_STD_LIB -isysroot $SDKROOT -$CPP_DEV_TARGET=$IOS_SDK_TARGET -I$SDKROOT/usr/include/"
    export LDFLAGS="-L$SDKROOT/usr/lib/"
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS="$CFLAGS -std=$CPP_STD"

    cd $ASSIMP_SOURCES_FOLDER > /dev/null

    rm CMakeCache.txt

    cmake  -G 'Unix Makefiles' -DCMAKE_TOOLCHAIN_FILE=./port/iOS/IPHONEOS_$(echo $1 | tr '[:lower:]' '[:upper:]')_TOOLCHAIN.cmake -DENABLE_BOOST_WORKAROUND=ON -DBUILD_SHARED_LIBS=OFF -DASSIMP_NO_EXPORT=ON $(echo ${ARRAY_OF_IMPORTER_FLAGS[@]})

    printf "\n"
    echo "Building $1 library"

    $XCODE_ROOT_DIR/Developer/usr/bin/make clean
    $XCODE_ROOT_DIR/Developer/usr/bin/make assimp -j 8 -l

    cd - > /dev/null

    echo "[!] Moving built library into: ${BUILD_DIR}${1}/"

    mv ${ASSIMP_SOURCES_FOLDER}lib/libassimp.a ${BUILD_DIR}${1}/
    mv ${ASSIMP_SOURCES_FOLDER}lib/libIrrXML.a ${BUILD_DIR}${1}/
    mv ${ASSIMP_SOURCES_FOLDER}lib/libzlibstatic.a ${BUILD_DIR}${1}/
}

CPP_STD_LIB=$SELECTED_CPP_STD_LIB
CPP_STD=$SELECTED_CPP_STANDART
DEPLOY_ARCHS=${FILTERED_ARRAY_OF_ARCHS[*]}

rm -rf $BUILD_DIR

for ARCH_TARGET in $DEPLOY_ARCHS; do
    mkdir -p $BUILD_DIR/$ARCH_TARGET
    build_arch $ARCH_TARGET
    #rm ./lib/libassimp.a
done

echo '[+] Creating fat binary ...'
for ARCH_TARGET in $DEPLOY_ARCHS; do
    LIPO_LIBASSIMP_ARGS="$LIPO_LIBASSIMP_ARGS-arch $ARCH_TARGET $BUILD_DIR/$ARCH_TARGET/libassimp.a "
    LIPO_LIBIRRXML_ARGS="$LIPO_LIBIRRXML_ARGS-arch $ARCH_TARGET $BUILD_DIR/$ARCH_TARGET/libIrrXML.a "
    LIPO_LIBZLIBSTATIC_ARGS="$LIPO_LIBZLIBSTATIC_ARGS-arch $ARCH_TARGET $BUILD_DIR/$ARCH_TARGET/libzlibstatic.a "
done
LIPO_LIBASSIMP_ARGS="$LIPO_LIBASSIMP_ARGS-create -output $BUILD_DIR/libassimp-fat.a"
LIPO_LIBIRRXML_ARGS="$LIPO_LIBIRRXML_ARGS-create -output $BUILD_DIR/libIrrXML-fat.a"
LIPO_LIBZLIBSTATIC_ARGS="$LIPO_LIBZLIBSTATIC_ARGS-create -output $BUILD_DIR/libzlibstatic-fat.a"

lipo $LIPO_LIBASSIMP_ARGS
lipo $LIPO_LIBIRRXML_ARGS
lipo $LIPO_LIBZLIBSTATIC_ARGS

echo "[!] Done! The fat binary can be found at $BUILD_DIR"
