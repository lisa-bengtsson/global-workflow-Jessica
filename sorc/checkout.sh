#!/bin/sh
set -xu

topdir=$(pwd)
echo $topdir

echo fv3gfs coupled checkout ...
if [[ ! -d fv3gfs.fd ]] ; then
    rm -f ${topdir}/checkout-fv3gfs.log
   
   git clone https://github.com/JessicaMeixner-NOAA/ufs-s2s-model.git fv3gfs.fd >> ${topdir}/checkout-fv3gfs.log 2>&1
   cd fv3gfs.fd
   git checkout 85dc6cc0e20f3545b0ac17c23d8562ea7b0fc534 
   #wcossphase2 branch 
   #prototype 4 tag + wcoss porting updates


    git submodule update --init --recursive
    cd ${topdir}
else
    echo 'Skip.  Directory fv3gfs.fd already exists.'
fi

echo gsi checkout ...
if [[ ! -d gsi.fd ]] ; then
    rm -f ${topdir}/checkout-gsi.log
    git clone --recursive gerrit:ProdGSI gsi.fd >> ${topdir}/checkout-gsi.fd.log 2>&1
    cd gsi.fd
    git checkout fv3da.v1.0.15
    git submodule update
    cd ${topdir}
else
    echo 'Skip.  Directory gsi.fd already exists.'
fi

echo EMC_post checkout ...
if [[ ! -d gfs_post.fd ]] ; then
    rm -f ${topdir}/checkout-gfs_post.log
#    git clone --recursive gerrit:EMC_post gfs_post.fd >> ${topdir}/checkout-gfs_post.log 2>&1
    git clone https://github.com/jiandewang/EMC_post gfs_post.fd >> ${topdir}/checkout-gfs_post.log 2>&1
    cd gfs_post.fd
#    git checkout ncep_post.v8.0.16
#    git checkout ncep_post.v8.0.16-wcossP2
    git checkout EMC_post-P2
    cd ${topdir}
else
    echo 'Skip.  Directory gfs_post.fd already exists.'
fi

exit 0
