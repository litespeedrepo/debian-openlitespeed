#!/bin/bash
#set -x
#set -v
#source ~/.bashrc
cur_path=$(pwd)

check_input(){
    echo " ###########   Check_input  ############# "
    echo " Product name is $product "
    echo " Version number is $version "
    echo " Build revision is $revision "
    echo " Required archs are $archs "
    echo " Required dists are $dists "
}

set_paras(){
    PRODUCT_DIR=${cur_path}/build/$product
    BUILD_DIR=$PRODUCT_DIR/"$version-$revision"
    BUILD_RESULT_DIR=$BUILD_DIR/build-result
}

set_build_dir(){
    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p $BUILD_DIR
        mkdir -p $BUILD_DIR/build-result
    else
        echo " find build directory exists "
        clear_or_not=n
        read -p "do you want to clear it before continuing? y/n:  " -t 15 clear_or_not
        if [ x$clear_or_not == xy ]; then
            echo " now clean the build directory "
            rm -rf $BUILD_DIR/*
            echo " build directory cleared "
        else
            echo " the build directory will not be completely cleared "
            echo " the existing build-result folder will be kept "
            echo " only related files will be overwritten "
            echo " but the source will be downloaded again "
            cd $BUILD_DIR/
            rm -rf `ls $BUILD_DIR | grep -v build-result`
        fi
    fi
    for dist in $dists; do
        mkdir -p $BUILD_DIR/build-result/$dist
    done
}


prepare_source(){
    cd $BUILD_DIR
    case "$product" in
    openlitespeed)
        if [[ ${archs} == 'arm64' ]] ; then
            source_url="https://openlitespeed.org/packages/openlitespeed-${version}-aarch64-linux.tgz"
            wget -qO ./$product-$version-aarch64-linux.tgz $source_url
            tar xzf $product-$version-aarch64-linux.tgz
        else 
            source_url="https://openlitespeed.org/packages/openlitespeed-${version}-x86_64-linux.tgz"
            wget -qO ./$product-$version.tgz $source_url
            tar xzf $product-$version.tgz
        fi
        source_folder_name=`ls -d */ | grep $product`
        SOURCE_DIR=$BUILD_DIR/$source_folder_name
    ;;  
    *)
        echo "Currently this product is not supported"
        ;;
  esac
  echo " source folder name is $source_folder_name "
}

pbuild_packages(){
    echo " now building packages "
    cd $SOURCE_DIR
    for arch in `echo $archs`; do
        for dist in `echo $dists`; do
            TAIL_EDGE=''
            if [ -d ${SOURCE_DIR}/debian ] ; then
                rm -rf ${SOURCE_DIR}/debian
            fi
            
            cp -a ${PRODUCT_DIR}${TAIL_EDGE}/debian $SOURCE_DIR/
            echo " copy changelog template to debian folder "
            cp -af ${PRODUCT_DIR}${TAIL_EDGE}/debian/changelog $SOURCE_DIR/debian/changelog
            echo " now substitute variables in changelog "
            sed -i -e "s/#VERSION#/${version}/g" $SOURCE_DIR/debian/changelog
            sed -i -e "s/#BUILD_REVISION#/${revision}/g" $SOURCE_DIR/debian/changelog
            sed -i -e "s/#DIST#/${dist}/g" $SOURCE_DIR/debian/changelog
            sed -i -e "s/#DATE#/`date +"%a, %d %b %Y %T"`/g" $SOURCE_DIR/debian/changelog
            sed -i -e "s/#PHP_VERSION#/${PHP_VERSION_NUMBER}/g" $SOURCE_DIR/debian/changelog
            echo " changelog preparation done "

        if [ "${product}" = 'openlitespeed' ] ; then
            cd $SOURCE_DIR/..
            #cp -a -f $PRODUCT_DIR/ps-makefile/Makefile-$version-amd64 $SOURCE_DIR/src/modules/pagespeed/Makefile
            rm -f openlitespeed_${version}.orig.tar.xz >/dev/null 2>&1
            tar -cJf openlitespeed_${version}.orig.tar.xz --exclude='debian' ${source_folder_name}
            echo " source orig file generated : openlitespeed_${version}.orig.tar.xz "
            cd $SOURCE_DIR

            # need to change the version dependency to ols for pagespeed
            sed -i -e "s/#VERSION#/${version}/g" $SOURCE_DIR/debian/control
            sed -i -e "s/#BUILD#/${revision}/g" $SOURCE_DIR/debian/control
            sed -i -e "s/#DIST#/${dist}/g" $SOURCE_DIR/debian/control

            # need to change version inside of rules
            sed -i -e "s/%%VERSION%%/${version}/g" $SOURCE_DIR/debian/rules
        fi

          export DISTRO_TEST=${distro}
          DIST=${dist} ARCH=${arch} pbuilder --update
          pdebuild --debbuildopts -j8 --architecture ${arch} --buildresult ../build-result/${dist} --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" -- --hookdir $HOME
        done
    done
}

upload_to_server(){
    cd $BUILD_DIR/build-result
    REP_LOC='/var/www/html'
    for dist in `echo $dists`; do
        echo "Uploading pkg to dev - distribution ${dist}"
        eval `ssh-agent -s`
        echo "${BUILD_KEY}" | ssh-add - > /dev/null 2>&1
        scp -oStrictHostKeyChecking=no $BUILD_DIR/build-result/${dist}/*.deb root@${target_server}:${REP_LOC}/debian/pool/main/${dist}/ #>/dev/null 2>&1
    done
}

gen_dev_release(){
    for dist in `echo $dists`; do
        echo "Sign Release for distribution ${dist}"
        ssh -oStrictHostKeyChecking=no root@${target_server} -t "/var/www/gen_package.sh ${dist}"
    done
}