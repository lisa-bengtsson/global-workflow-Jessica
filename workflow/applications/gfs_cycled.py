from typing import Dict, Any
from applications.applications import AppConfig
from wxflow import Configuration
from datetime import timedelta


class GFSCycledAppConfig(AppConfig):
    '''
    Class to define GFS cycled configurations
    '''

    def __init__(self, conf: Configuration):
        super().__init__(conf)
        self.do_hybvar = self._base.get('DOHYBVAR', False)
        self.do_fit2obs = self._base.get('DO_FIT2OBS', True)
        self.do_jediatmvar = self._base.get('DO_JEDIATMVAR', False)
        self.do_jediatmens = self._base.get('DO_JEDIATMENS', False)
        self.do_jediocnvar = self._base.get('DO_JEDIOCNVAR', False)
        self.do_jedilandda = self._base.get('DO_JEDILANDDA', False)
        self.do_mergensst = self._base.get('DO_MERGENSST', False)

        self.lobsdiag_forenkf = False
        self.eupd_cdumps = None
        if self.do_hybvar:
            self.lobsdiag_forenkf = self._base.get('lobsdiag_forenkf', False)
            eupd_cdump = self._base.get('EUPD_CYC', 'gdas').lower()
            if eupd_cdump in ['both']:
                self.eupd_cdumps = ['gfs', 'gdas']
            elif eupd_cdump in ['gfs', 'gdas']:
                self.eupd_cdumps = [eupd_cdump]

    def _get_app_configs(self):
        """
        Returns the config_files that are involved in the cycled app
        """

        configs = ['prep']

        if self.do_jediatmvar:
            configs += ['prepatmiodaobs', 'atmanlinit', 'atmanlrun', 'atmanlfinal']
        else:
            configs += ['anal', 'analdiag']

        if self.do_jediocnvar:
            configs += ['ocnanalprep', 'ocnanalbmat', 'ocnanalrun', 'ocnanalchkpt', 'ocnanalpost', 'ocnanalvrfy']

        if self.do_ocean:
            configs += ['ocnpost']

        configs += ['sfcanl', 'analcalc', 'fcst', 'post', 'vrfy', 'arch', 'cleanup']

        if self.do_hybvar:
            if self.do_jediatmens:
                configs += ['atmensanlinit', 'atmensanlrun', 'atmensanlfinal']
            else:
                configs += ['eobs', 'eomg', 'ediag', 'eupd']
            configs += ['ecen', 'esfc', 'efcs', 'echgres', 'epos', 'earc']

        if self.do_fit2obs:
            configs += ['fit2obs']

        if self.do_verfozn:
            configs += ['verfozn']

        if self.do_verfrad:
            configs += ['verfrad']

        if self.do_vminmon:
            configs += ['vminmon']

        if self.do_metp:
            configs += ['metp']

        if self.do_gempak:
            configs += ['gempak']

        if self.do_bufrsnd:
            configs += ['postsnd']

        if self.do_awips:
            configs += ['awips']

        if self.do_wave:
            configs += ['waveinit', 'waveprep', 'wavepostsbs', 'wavepostpnt']
            if self.do_wave_bnd:
                configs += ['wavepostbndpnt', 'wavepostbndpntbll']
            if self.do_gempak:
                configs += ['wavegempak']
            if self.do_awips:
                configs += ['waveawipsbulls', 'waveawipsgridded']

        if self.do_wafs:
            configs += ['wafs', 'wafsgrib2', 'wafsblending', 'wafsgcip', 'wafsgrib20p25', 'wafsblending0p25']

        if self.do_aero:
            configs += ['aeroanlinit', 'aeroanlrun', 'aeroanlfinal']

        if self.do_jedilandda:
            configs += ['preplandobs', 'landanl']

        return configs

    @staticmethod
    def _update_base(base_in):

        return GFSCycledAppConfig.get_gfs_cyc_dates(base_in)

    def get_task_names(self):
        """
        Get the task names for all the tasks in the cycled application.
        Note that the order of the task names matters in the XML.
        This is the place where that order is set.
        """

        gdas_gfs_common_tasks_before_fcst = ['prep']
        gdas_gfs_common_tasks_after_fcst = ['postanl', 'post']
        # if self.do_ocean:  # TODO: uncomment when ocnpost is fixed in cycled mode
        #    gdas_gfs_common_tasks_after_fcst += ['ocnpost']
        gdas_gfs_common_tasks_after_fcst += ['vrfy']

        gdas_gfs_common_cleanup_tasks = ['arch', 'cleanup']

        if self.do_jediatmvar:
            gdas_gfs_common_tasks_before_fcst += ['prepatmiodaobs', 'atmanlinit', 'atmanlrun', 'atmanlfinal']
        else:
            gdas_gfs_common_tasks_before_fcst += ['anal']

        if self.do_jediocnvar:
            gdas_gfs_common_tasks_before_fcst += ['ocnanalprep', 'ocnanalbmat', 'ocnanalrun',
                                                  'ocnanalchkpt', 'ocnanalpost', 'ocnanalvrfy']

        gdas_gfs_common_tasks_before_fcst += ['sfcanl', 'analcalc']

        if self.do_aero:
            gdas_gfs_common_tasks_before_fcst += ['aeroanlinit', 'aeroanlrun', 'aeroanlfinal']

        if self.do_jedilandda:
            gdas_gfs_common_tasks_before_fcst += ['preplandobs', 'landanl']

        wave_prep_tasks = ['waveinit', 'waveprep']
        wave_bndpnt_tasks = ['wavepostbndpnt', 'wavepostbndpntbll']
        wave_post_tasks = ['wavepostsbs', 'wavepostpnt']

        hybrid_tasks = []
        hybrid_after_eupd_tasks = []
        if self.do_hybvar:
            if self.do_jediatmens:
                hybrid_tasks += ['atmensanlinit', 'atmensanlrun', 'atmensanlfinal', 'echgres']
            else:
                hybrid_tasks += ['eobs', 'eupd', 'echgres']
                hybrid_tasks += ['ediag'] if self.lobsdiag_forenkf else ['eomg']
            hybrid_after_eupd_tasks += ['ecen', 'esfc', 'efcs', 'epos', 'earc', 'cleanup']

        # Collect all "gdas" cycle tasks
        gdas_tasks = gdas_gfs_common_tasks_before_fcst.copy()
        if not self.do_jediatmvar:
            gdas_tasks += ['analdiag']

        if self.do_wave and 'gdas' in self.wave_cdumps:
            gdas_tasks += wave_prep_tasks

        gdas_tasks += ['fcst']

        gdas_tasks += gdas_gfs_common_tasks_after_fcst

        if self.do_wave and 'gdas' in self.wave_cdumps:
            if self.do_wave_bnd:
                gdas_tasks += wave_bndpnt_tasks
            gdas_tasks += wave_post_tasks

        if self.do_fit2obs:
            gdas_tasks += ['fit2obs']

        if self.do_verfozn:
            gdas_tasks += ['verfozn']

        if self.do_verfrad:
            gdas_tasks += ['verfrad']

        if self.do_vminmon:
            gdas_tasks += ['vminmon']

        gdas_tasks += gdas_gfs_common_cleanup_tasks

        # Collect "gfs" cycle tasks
        gfs_tasks = gdas_gfs_common_tasks_before_fcst

        if self.do_wave and 'gfs' in self.wave_cdumps:
            gfs_tasks += wave_prep_tasks

        gfs_tasks += ['fcst']

        gfs_tasks += gdas_gfs_common_tasks_after_fcst

        if self.do_vminmon:
            gfs_tasks += ['vminmon']

        if self.do_metp:
            gfs_tasks += ['metp']

        if self.do_wave and 'gfs' in self.wave_cdumps:
            if self.do_wave_bnd:
                gfs_tasks += wave_bndpnt_tasks
            gfs_tasks += wave_post_tasks
            if self.do_gempak:
                gfs_tasks += ['wavegempak']
            if self.do_awips:
                gfs_tasks += ['waveawipsbulls', 'waveawipsgridded']

        if self.do_bufrsnd:
            gfs_tasks += ['postsnd']

        if self.do_gempak:
            gfs_tasks += ['gempak']

        if self.do_awips:
            gfs_tasks += ['awips']

        if self.do_wafs:
            gfs_tasks += ['wafs', 'wafsgcip', 'wafsgrib2', 'wafsgrib20p25', 'wafsblending', 'wafsblending0p25']

        gfs_tasks += gdas_gfs_common_cleanup_tasks

        tasks = dict()
        tasks['gdas'] = gdas_tasks

        if self.do_hybvar and 'gdas' in self.eupd_cdumps:
            enkfgdas_tasks = hybrid_tasks + hybrid_after_eupd_tasks
            tasks['enkfgdas'] = enkfgdas_tasks

        # Add CDUMP=gfs tasks if running early cycle
        if self.gfs_cyc > 0:
            tasks['gfs'] = gfs_tasks

            if self.do_hybvar and 'gfs' in self.eupd_cdumps:
                enkfgfs_tasks = hybrid_tasks + hybrid_after_eupd_tasks
                enkfgfs_tasks.remove("echgres")
                tasks['enkfgfs'] = enkfgfs_tasks

        return tasks

    @staticmethod
    def get_gfs_cyc_dates(base: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate GFS dates from experiment dates and gfs_cyc choice
        """

        base_out = base.copy()

        gfs_cyc = base['gfs_cyc']
        sdate = base['SDATE']
        edate = base['EDATE']
        base_out['INTERVAL'] = '06:00:00'  # Cycled interval is 6 hours

        interval_gfs = AppConfig.get_gfs_interval(gfs_cyc)

        # Set GFS cycling dates
        hrinc = 0
        hrdet = 0
        if gfs_cyc == 0:
            return base_out
        elif gfs_cyc == 1:
            hrinc = 24 - sdate.hour
            hrdet = edate.hour
        elif gfs_cyc == 2:
            if sdate.hour in [0, 12]:
                hrinc = 12
            elif sdate.hour in [6, 18]:
                hrinc = 6
            if edate.hour in [6, 18]:
                hrdet = 6
        elif gfs_cyc == 4:
            hrinc = 6
        sdate_gfs = sdate + timedelta(hours=hrinc)
        edate_gfs = edate - timedelta(hours=hrdet)
        if sdate_gfs > edate:
            print('W A R N I N G!')
            print('Starting date for GFS cycles is after Ending date of experiment')
            print(f'SDATE = {sdate.strftime("%Y%m%d%H")},     EDATE = {edate.strftime("%Y%m%d%H")}')
            print(f'SDATE_GFS = {sdate_gfs.strftime("%Y%m%d%H")}, EDATE_GFS = {edate_gfs.strftime("%Y%m%d%H")}')
            gfs_cyc = 0

        base_out['gfs_cyc'] = gfs_cyc
        base_out['SDATE_GFS'] = sdate_gfs
        base_out['EDATE_GFS'] = edate_gfs
        base_out['INTERVAL_GFS'] = interval_gfs

        fhmax_gfs = {}
        for hh in ['00', '06', '12', '18']:
            fhmax_gfs[hh] = base.get(f'FHMAX_GFS_{hh}', base.get('FHMAX_GFS_00', 120))
        base_out['FHMAX_GFS'] = fhmax_gfs

        return base_out
