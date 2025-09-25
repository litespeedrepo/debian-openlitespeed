#!/bin/bash
target_server='repo-dev.litespeedtech.com'
prod_server='rpms.litespeedtech.com'
EPACE='        '
#PHP_V=84
product=$1
dists=$2
input_archs=$3
PUSH_FLAG='OFF'
lsapi_version=8.2
#version=
#revision=

source ./functions.sh #2>/dev/null
if [ $(id -u) != "0" ]; then
    echo "Error: The user is not root "
    echo "Please run this script as root"
    exit 1
fi
echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}
show_help()
{
    echo -e "\033[1mExamples\033[0m"
    echo "${EPACE} ./build.sh [openlitespeed] [noble|bookworm|...|buster] [amd64|arm64]"
    echo "${EPACE} ./build.sh openlitespeed bookworm amd64"    
    echo -e "\033[1mOPTIONS\033[0m"
    echow '--version [NUMBER]'
    echo "${EPACE}${EPACE}Specify package version number"    
    echo "${EPACE}${EPACE}Example:./build.sh openlitespeed noble amd64 --version 1.8.4"
    echow '--revision [NUMBER]'
    echo "${EPACE}${EPACE}Specify package revision number"    
    echo "${EPACE}${EPACE}Example:./build.sh openlitespeed noble amd64 --version 1.8.4 --revision 5"
    echow '--push-flag'
    echo "${EPACE}${EPACE}push packages to dev server."    
    echo "${EPACE}${EPACE}Example:./build.sh openlitespeed noble amd64 --push-flag"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
    exit 0
}
if [ -z "${1}" ]; then
    show_help
fi
if [ -z "${version}" ]; then
    version="$(grep ${product}= VERSION.txt | awk -F '=' '{print $2}')"
fi

if [ $dists = "all" ]; then
    dists="noble jammy focal bookworm bullseye buster"
    echo "The new value for dists is $dists"
fi
if [ -z "${revision}" ]; then
    TMP_DIST=$(echo $dists | awk '{ print $1 }')
    echo ${product} | grep '-' >/dev/null
    if [ $? = 1 ]; then 
        revision=$(curl -isk https://${prod_server}/debian/pool/main/$TMP_DIST/ | grep ${product}_${version} \
          | awk -F '-' '{print $3}' | awk -F '+' '{print $1}' | tail -1)
    else
        revision=$(curl -isk https://${prod_server}/debian/pool/main/$TMP_DIST/ | grep ${product}_${version} \
          | awk -F '-' '{print $4}' | awk -F '+' '{print $1}' | tail -1)      
    fi      
    if [[ $revision == ?(-)+([[:digit:]]) ]]; then
        revision=$((revision+1))
    else
        echo "$revision is not a number, set value to 1"
        revision=1
    fi      
fi
if [ -z ${input_archs} ]; then
    echo 'input_archs is not found, use default value amd64'
    archs='amd64'
else    
    archs=$input_archs
fi
list_packages()
{
    echo "##################################################"
    echo " The package building process has finished ! "
    echo "##################################################"
    echo "########### Build Result Content #################"
    for dist in $dists; do
        ls -lR $BUILD_RESULT_DIR/$dist;
    done
    echo " ################# End of Result #################"
    for dist in $dists; do
        ls -lR $BUILD_RESULT_DIR/$dist | grep ${product}_${version}-${revision}+${dist}_.*.deb >/dev/null
        if [ ${?} != 0 ] ; then
            echo "${product}_${version}-${revision}+${dist}_.*.deb is not found!"
            exit 1   
        fi
    done
}
while [ ! -z "${1}" ]; do
    case $1 in
        --version) shift
            version="${1}"
                ;;
        --revision) shift
            revision="${1}"
                ;;
        --push | --push-flag)
            PUSH_FLAG='ON'
                ;;
        -[hH] | --help)
            show_help
                ;;           
    esac
    shift
done

check_input
set_paras
set_build_dir
prepare_source
pbuild_packages
list_packages
if [ ${PUSH_FLAG} = 'ON' ]; then
    upload_to_server
    gen_dev_release
fi
