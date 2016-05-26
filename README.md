# daily_backup
Do a dailly rsync backup and archives local or remote directories.
#===================================================================================
#  DESCRIPTION:  Do a dailly rsync backup and archives local or remote directories.
#                - Can copy through network via SSH
#                - Archives can be accessed by date directories
#                  day-1, day-2 ... week-1, ..., month-01,... year-01...
#                - Archives uses hard links for unmodified files in
#                  order to limit disk consuption.
#                +--------+             +-------+                 +--------+
#                |optional|    daily    |Working|     daily       |optional|
#                | native | ===copy===> |       | ===historic===> | Backup |
#                |  dir   |    new      |  dir  |     archive     |  dir   |
#                +--------+    files    +-------+                 +--------+
#              local or remote        local or remote               local
#                
#CONFIGUTATION:  1 - Copy inc_config_TEMPLATE.sh to inc_config.sh
#                    and eventually adjust content
#                2 - Copy backup_exclude_TEMPLATE.txt to backup_exclude.txt
#                    and eventually adjust content
#                3 - Create config files (cfg/myname1.cfg) dir based on the
#                    example test.cfg_TEMPLATE.
#                4 - Launch everyday, for instance in cron table:
#                    7 1 * * * /path_to_script/daily_backup_task.sh
#
#      OPTIONS:  
# REQUIREMENTS:  in_config.sh, inc_lib_backup.sh, conf/
#         BUGS:  ---
#        NOTES:  This code is partly inspired by http://www.mikerubel.org/computers/rsync_snapshots/
#       AUTHOR:  Hervé SUAUDEAU, herve.suaudeau@parisdescartes.fr
#      COMPANY:  CNRS
#      VERSION:  1.0
#      CREATED:  2010
#     REVISION:  15.05.2016
#      LICENCE:  GPL v3
#=================================================================================== 
