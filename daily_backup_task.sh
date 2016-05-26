#!/bin/bash
#===================================================================================
#
#         FILE: daily_backup_task.sh
#
#        USAGE: daily_backup_task.sh
#
#  DESCRIPTION:  Do a backup and archives of directories.
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

#----------------------------------------------------------------------
#  Actions préparatoires
#----------------------------------------------------------------------
#Include global functions
. "$(dirname "${0}")/inc_lib_backup.sh"

# make sure we're running as root
if [ $(${ID} -u) != 0 ]; then
    ${ECHO} "Sorry, must be root.  Exiting..."; exit;
fi

${ECHO} "$(${DATE} '+%a %d %B %T') : BEGIN backup_and_rotate.sh \"${1}\"" >> "${CRON_LOG_FILE}"

# -------------------------------------------------------
# STEP 1 - Copy from native to working copy
# -------------------------------------------------------
${ECHO} "STEP 1 : Copy from native to working copy"
${ECHO} "-----------------------------------------"
for config_file in $(ls "${SCRIPT_PATH}/cfg/"*.cfg); do
    native_dir=$(${GREP} '^NATIVE=' "${config_file}" | ${CUT} -d "=" -f 2)
    working_dir=$(${GREP} '^WORKING=' "${config_file}" | ${CUT} -d "=" -f 2)
    copy_from_native_to_working_copy "${native_dir}" "${working_dir}"
done

# -------------------------------------------------------
# STEP 2 - Do daily rotations and copies
# -------------------------------------------------------
${ECHO} "-----------------------------------------"
${ECHO} "STEP 2 : Do daily rotations and copies"
typeOfDailyJob=$(getTypeOfDailyJob)
typeOfMonthlyJob=$(getTypeOfMonthlyJob)
echo "Type of job : $typeOfDailyJob + $typeOfMonthlyJob"
${ECHO} "-----------------------------------------"

for config_file in $(ls "${SCRIPT_PATH}/cfg/"*.cfg); do
    working_dir=$(${GREP} '^WORKING=' "${config_file}" | ${CUT} -d "=" -f 2)
    backup_dir=$(${GREP} '^BACKUP=' "${config_file}" | ${CUT} -d "=" -f 2)
    ${ECHO} "Fichier ${config_file} : ${working_dir} to ${backup_dir}"
    ${ECHO} "...................................................................................................."
    if [ $typeOfMonthlyJob == "month" ]; then
        monthlyJob "${backup_dir}"
    elif [ $typeOfMonthlyJob == "year" ]; then
        yearlyJob "${backup_dir}"
        monthlyJob "${backup_dir}"
    fi

    if [ $typeOfDailyJob == "day" ]; then
        dailyJob "${working_dir}" "${backup_dir}"
    elif [ $typeOfDailyJob == "week" ]; then
        weeklyJob "${backup_dir}"
        dailyJob "${working_dir}" "${backup_dir}"
    fi

done

# -------------------------------------------------------
# STEP 3 - Finished!
# -------------------------------------------------------
${ECHO} "La commande de sauvegarde et rotation quotidienne a terminé son travail..."
${ECHO} "Vérifiez dans le terminal s'il n'y a pas eu d'erreur !"
${ECHO} "$(${DATE} '+%a %d %B %T') : END backup_and_rotate.sh ${typeOfRotation}" >> "${CRON_LOG_FILE}"
