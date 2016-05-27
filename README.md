daily_backup
===========

###Description:

Do a dailly rsync backup and archives local or remote directories.
- Can copy through network via SSH
- Archives can be accessed by date directories day-1, day-2 ... week-1, ...,
  month-01,... year-01...
- Archives uses hard links for unmodified files in order to limit disk consuption.

                +--------+             +-------+                 +--------+
                |optional|    daily    |Working|     daily       |optional|
                | native | ===copy===> |       | ===historic===> | Backup |
                |  dir   |    new      |  dir  |     archive     |  dir   |
                +--------+    files    +-------+                 +--------+
              local or remote        local or remote               local

###Configuration:

1. Copy inc_config_TEMPLATE.sh to inc_config.sh and eventually adjust content
2. Create config files (cfg/myname1.cfg) dir based on the
   example test.cfg_TEMPLATE.
3. Launch everyday, for instance in cron table:
   `7 1 * * * /path_to_script/daily_backup_task.sh`

###Options:  

###Requirement:  
    in_config.sh, inc_lib_backup.sh, conf/

###Bugs:

###Notes:  
This code is partly inspired by http://www.mikerubel.org/computers/rsync_snapshots/

###Author:  
Hervé SUAUDEAU, herve.suaudeau (arob.) parisdescartes.fr (CNRS)

###Revisions:
| Version |    Date    | Comments                                              |
| ------- | ---------- | ----------------------------------------------------- |
| 1.0     | 15.05.2016 | First commit into Github. Production version Ubsed from 2010|
| 1.1     | 27.05.2016 | - Change config file keywords: NATIVE => NATIVE_DIR, WORKING => WORKING_DIR, BACKUP => BACKUP_DIR|
|         |            | - Suppress global backup_exclude.txt and ad an option EXCLUDE in config file|

###Licence
    GPL v3
