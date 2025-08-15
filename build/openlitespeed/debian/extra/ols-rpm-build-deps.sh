#!/bin/bash
#set -x

while [[ "$1" != '' ]]; do
  case $1 in
    --with-brotli ) WITH_BROTLI=1
                    ;;
    --with-ip2loc ) WITH_IP2LOC=1
                    ;;
    --with-bssl )   WITH_BSSL=1
                    ;;
    --with-modsec ) WITH_MODSEC=1
                    ;;
  esac
  shift
done

mkdir -p third-party/
mkdir -p third-party/usr/local/lib
mkdir -p third-party/usr/local/include
pushd third-party/

function build_brotli() {
  git clone https://github.com/google/brotli.git
  cd brotli
  git reset --hard
  git fetch
  git pull
  git checkout v1.0.5
  git pull

  mkdir out && cd out
  cmake .. -DBUILD_SHARED_LIBS=OFF
  make

  cp libbrotli*.a ../../usr/local/lib
  cp -r ../c/include/brotli ../../usr/local/include
  cd ../../../
  mkdir -p brotli-master
  cp -r third-party/brotli/* brotli-master/
  cd third-party/
}

function build_ip2loc() {
  git clone https://github.com/chrislim2888/IP2Location-C-Library.git
  cd IP2Location-C-Library
  git fetch
  git pull
  git checkout 8.0.4

  autoreconf -i -v --force
  ./configure
  make

  cp libIP2Location/.libs/libIP2Location.a ../usr/local/lib
  cp libIP2Location/IP2Location.h ../usr/local/include
  cp libIP2Location/IP2Loc_DBInterface.h ../usr/local/include
  cd ../
}

function build_bssl() {
  git clone https://boringssl.googlesource.com/boringssl boringssl
  cd boringssl
  #git checkout 96e744c176328b51239df6e48a8a590e4949e6c8
  git reset --hard
  #git checkout master
  git fetch
  git pull
  #git branch -a
  #git checkout -b chromium-stable
  #git checkout remotes/origin/chromium-stable
  git checkout 3474270abdebbd6235c1391e54aaba5924276666

  #git branch
  #exit 1
  git pull
  rm -rf build
  #rm crypto/err/err_data.c
  patch -p1 < ../../debian/extra/bssl_patch.txt

  mkdir build && cd build
  cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC"
  make
  cd ssl
  make
  cd ../decrepit
  make
  cd ../../../

  if [ -d "../ssl" ] ; then
    rm -rf ../ssl/*
  else
    mkdir ../ssl
  fi
  cp boringssl/build/ssl/libssl.a ../ssl/
  cp boringssl/build/crypto/libcrypto.a ../ssl/
  cp boringssl/build/decrepit/libdecrepit.a ../ssl/
  cp -r boringssl/include/ ../ssl/
  cp boringssl/ssl/internal.h ../ssl/include/openssl/
}

function build_modsec() {
  cd ../src/modules/modsecurity-ls
  git clone https://github.com/SpiderLabs/ModSecurity
  cd ModSecurity
  #git checkout -b v3/master origin/v3/master
  git checkout v3.0.2
  ./build.sh
  git submodule init
  git submodule update

  ./configure --without-yajl
  make -j4
  cd ../../../../third-party
}

if [[ $WITH_BROTLI -eq 1 ]]; then
  build_brotli
fi

if [[ $WITH_IP2LOC -eq 1 ]]; then
  build_ip2loc
fi

if [[ $WITH_BSSL -eq 1 ]]; then
  build_bssl
fi

if [[ $WITH_MODSEC -eq 1 ]]; then
  build_modsec
fi

popd
exit 0

