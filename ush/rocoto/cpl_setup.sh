#!/bin/sh
set -x

echo "Load modules first"
# JW source /usr/Modules/3.2.10/init/sh
module load rocoto
module load hpss

CWD=`pwd`
# $IDATE is the initial start date of your run (first cycle CDATE, YYYYMMDDCC)
#IDATE=$1
IDATE=2013040100
# $EDATE is the ending date of your run (YYYYMMDDCC) and is the last cycle that will complete
#EDATE=2016010100
EDATE=$IDATE
YMD=`echo $IDATE | cut -c1-8`
HH=`echo $IDATE | cut -c9-10`
FROM_HPSS=/global/noscrub/Jiande.Wang/WF3/FROM_HPSS
FV3DATA=$FROM_HPSS/$IDATE/gfs/C384/INPUT

# ./setup_expt_fcstonly.py --pslot $PSLOT --configdir $CONFIGDIR --idate $IDATE --edate $EDATE --res $RES --gfs_cyc $GFS_CYC --comrot $COMROT --expdir $EXPDIR

# $PSLOT is the name of your experiment
PSLOT=c384

# $COMROT is the path to your experiment output directory. DO NOT include PSLOT folder at end of path, it’ll be built for you.
#COMROT=/scratch4/NCEPDEV/nems/noscrub/${USER}/benchmark2/${YMD}/COMFV3
COMROT=/stmpd2/${USER}/preUFSp4/COMFV3/${IDATE}
mkdir -p $COMROT

# $CONFIGDIR is the path to the /config folder under the copy of the system you're using (i.e. ../parm/config/)
#CONFIGDIR=/scratch4/NCEPDEV/nems/noscrub/Patrick.Tripp/new.fv3gfs/parm/config
CONFIGDIR=/marine/noscrub/Jessica.Meixner/global-workflow-wav/parm/config

# do not export ICSDIR, causes error in py script
#BL2018
#ICSDIR=$COMROT/FV3ICS
#
#FROM_HPSS=/scratch4/NCEPDEV/nems/noscrub/Bin.Li/FROM_HPSS
#FV3DATA=$FROM_HPSS/2016040100/gfs/C384/INPUT
#ICSDIR=$FV3DATA
#ICE_DIR=$FROM_HPSS/2016040100/cice5_cfsv2
#OCN_DIR=$FROM_HPSS/2016040100/mom6_cfsv2

# Link the existing FV3ICS folder to here, I prefer this directory to be in main directory, but changing in script can cause issues
#mkdir -p $COMROT
cd $COMROT
mkdir -p ../FV3ICS
ln -s ../FV3ICS .
ln -s $FROM_HPSS/* ../FV3ICS

cd $CWD

# $RES is the resolution of the forecast (i.e. 768 for C768)
RES=384

# $GFS_CYC is the forecast frequency (0 = none, 1 = 00z only [default], 2 = 00z & 12z, 4 = all cycles)
GFS_CYC=1

# $EXPDIR is the path to your experiment directory where your configs will be placed and where you will find your workflow monitoring files (i.e. rocoto database and xml file). DO NOT include PSLOT folder at end of path, it will be built for you.

#EXPDIR=/scratch4/NCEPDEV/nems/noscrub/${USER}/benchmark2/${YMD}/EXPFV3
EXPDIR=/stmpd2/${USER}/preUFSp4/EXPFV3/${IDATE}
mkdir -p $EXPDIR

./setup_expt_fcstonly.py --pslot $PSLOT --configdir $CONFIGDIR --idate $IDATE --edate $EDATE --res $RES --gfs_cyc $GFS_CYC --comrot $COMROT --expdir $EXPDIR

# Edit base.config
# Change noscrub dirs from global to climate
# Change account to CFS-T20

# Copy ICs : can put in a loop if running multiple cycles

#YMD=`echo $IDATE | cut -c1-8`
#HH=`echo $IDATE | cut -c9-10`
mkdir -p $COMROT/$PSLOT/gfs.$YMD/$HH/INPUT
cd $COMROT/$PSLOT/gfs.$YMD/$HH/INPUT

# Copy the ICs if they exist, otherwise the workflow will generate them from EMC_ugcs ICs
#BL2018
#if [ -d $ICSDIR/$IDATE/gfs/C$RES/INPUT ] ; then
#  cp -p $ICSDIR/$IDATE/gfs/C$RES/INPUT/* .

#BL2018
if [ -d $FV3DATA ] ; then
#  cp -p $FV3DATA/* .
  ln -s $FV3DATA/* .
fi

# Come back to this folder
cd $CWD

# Setup workflow
./setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

# Copy rocoto_viewer.py tp EXPDIR
cp rocoto_viewer.py $EXPDIR/$PSLOT
