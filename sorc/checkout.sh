#!/bin/sh
set -xu

topdir=$(pwd)
echo $topdir

echo fv3gfs coupled checkout ...
if [[ ! -d fv3gfs.fd ]] ; then
    rm -f ${topdir}/checkout-fv3gfs.log
#    git clone --recursive gerrit:EMC_FV3-MOM6-CICE5 fv3gfs.fd >> ${topdir}/checkout-fv3gfs.log 2>&1
#   remove recursive based on kate hotfix https://vlab.ncep.noaa.gov/redmine/issues/67072

#    git clone gerrit:EMC_FV3-MOM6-CICE5 fv3gfs.fd >> ${topdir}/checkout-fv3gfs.log 2>&1
   git clone https://github.com/ufs-community/ufs-s2s-model fv3gfs.fd >> ${topdir}/checkout-fv3gfs.log 2>&1 
   cd fv3gfs.fd
   git checkout 0eec05469defe6d9f637ceea537fab1a7a165364

# plan A use all top of master for each component
#     git checkout --track origin/bugfix/fv3atmcplflx

# plan B    use FV3-V0606 (note: Partha's run used branch UFS-FV3-V0606-CPC-ice-pre-BM3, not this one)
#     git checkout update_fv3_0606_b3

# plan C: use FV3-V0606 pplus bug fixing (gflux=0 and mask ?), results are b4b identical to plan B
#     git checkout --track origin/bm3fv30606bf
#      git checkout v3.0.3
# plan D: use ESRL bug fixing code based on fv3-V0606
#    git checkout --track origin/bm3fv30606bf_PlanD

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
