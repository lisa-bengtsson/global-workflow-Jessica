#Things that need to change: 
BASEDIR=path/to/clone/here
#winter case:
IDATE=2020021300	
# Hurricane case: 
#IDATE=2020091300

#Things that do not necessarily need to change: 
PSLOT=contorl${IDATE}
COMROT=$BASEDIR/$PSLOT/COMROOT
EXPDIR=$BASEDIR/$PSLOT/EXPDIR

#things to leave as is: 
APP=S2SW
CDUMP=gfs #gfs or gefs
CONFIGDIR=$BASEDIR/global-workflow/parm/config/${CDUMP}
EDATE=$IDATE
RES=768
GFS_CYC=1

echo "Don't forget to load module_gwsetup.orion" 
echo " "
echo "Set up script"
echo ./setup_expt.py ${CDUMP} forecast-only --app $APP --pslot $PSLOT --configdir $CONFIGDIR --idate $IDATE --edate $EDATE --res $RES --gfs_cyc $GFS_CYC --comrot $COMROT --expdir $EXPDIR 

echo " " 
echo "Make sure to update HOMEDIR, STMP, PTMP" 
echo "HOMEDIR=$BASEDIR/$PSLOT/HOMEDIR"
echo "STMP/PTMP=$BASEDIR/$PSLOT/TMP"
echo " " 

echo "setup workflow after above changes:"
echo "./setup_xml.py $EXPDIR/$PSLOT"

echo " " 
echo "The crontab has the rocotorun commands" 
echo "crontab:" 
echo $EXPDIR/$PSLOT/$PSLOT.crontab

