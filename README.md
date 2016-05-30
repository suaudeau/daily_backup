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

1. Create config files (cfg/myname1.cfg) dir based on the example test.cfg_TEMPLATE
2. Launch everyday, for instance in cron table:
   `7 1 * * * /path_to_script/daily_backup_task.sh`

###Options:  

###Requirement:  
    inc_lib.sh, inc_lib_backup.sh, conf/

###Bugs:

###Notes:  
This code is partly inspired by http://www.mikerubel.org/computers/rsync_snapshots/

###Author:  
Hervé SUAUDEAU, herve.suaudeau (arob.) parisdescartes.fr (CNRS)

###Revisions:
| Version |    Date    | Comments                                              |
| ------- | ---------- | ----------------------------------------------------- |
| 1.0     | 15.05.2016 | First commit into Github. Production version Ubsed from 2010|
| 1.1     | 27.05.2016 | API: Change config file keywords: NATIVE => NATIVE_DIR, WORKING => WORKING_DIR, BACKUP => BACKUP_DIR|
|         |            | API: Suppress global backup_exclude.txt and ad an option EXCLUDE in config file|
| 1.2     | 27.05.2016 | API: Symplify use by suppressing inc_config file|
| 1.3     | 30.05.2016 | CODE: Separation of inc_lib from inc_lib_backup |

###Licence
    GPL v3
