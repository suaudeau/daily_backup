#!/bin/bash
#===================================================================================
#
#         FILE: daily_backup_task.sh
#
#         Please read README.md
#
#===================================================================================

#----------------------------------------------------------------------
#  Actions préparatoires
#----------------------------------------------------------------------
#Include global functions
. "$(dirname "${0}")/lib/inc_lib.sh"
. "$(dirname "${0}")/lib/inc_lib_backup.sh"

#Set flags
VERBOSE_INFO=true

# make sure we're running as root
if [ $(${ID} -u) != 0 ]; then
    ${ECHO} "Sorry, must be root.  Exiting..."; exit;
fi

${ECHO} "$(${DATE} '+%a %d %B %T') : BEGIN backup_and_rotate.sh \"${1}\"" >> "${CRON_LOG_FILE}"

# -------------------------------------------------------
# STEP 1 - Copy from native to working copy
# -------------------------------------------------------
${ECHO} "========================================="
${ECHO} "STEP 1 : Copy from native to working copy"
${ECHO} "========================================="
for config_file in $(ls "${SCRIPT_PATH}/cfg/"*.cfg); do
    native_dir=$(${GREP} '^NATIVE_DIR=' "${config_file}" | ${CUT} -d "=" -f 2-)
    working_dir=$(${GREP} '^WORKING_DIR=' "${config_file}" | ${CUT} -d "=" -f 2-)
    #excludes_file=$(${MKTEMP})
    #${GREP} '^EXCLUDES=' "${config_file}" | ${CUT} -d "=" -f 2- > ${excludes_file}
    exclude_list=$(${GREP} '^EXCLUDES=' "${config_file}" | ${CUT} -d "=" -f 2-)
    exclude_options=$(echo $exclude_list | sed -e "s/ /' '--exclude=/g" | sed -e "s/^/'--exclude=/g" | sed -e "s/$/'/g")
    
    if [[ ! -z "${native_dir}" ]]; then   #Copy only if native_dir is defined
        ${ECHO} "Config file: $(${BASENAME} $config_file) : ${native_dir} to ${working_dir}"
        copy_from_native_to_working_copy "${native_dir}" "${working_dir}" "${exclude_options}"
    fi
    #${RM} ${excludes_file}   #Clean temp file
done

# -------------------------------------------------------
# STEP 2 - Do daily rotations and copies
# -------------------------------------------------------
${ECHO}
${ECHO} "========================================="
${ECHO} "STEP 2 : Do daily rotations and copies"
${ECHO} "========================================="

for config_file in $(ls "${SCRIPT_PATH}/cfg/"*.cfg); do
    working_dir=$(${GREP} '^WORKING_DIR=' "${config_file}" | ${CUT} -d "=" -f 2-)
    backup_dir=$(${GREP} '^BACKUP_DIR=' "${config_file}" | ${CUT} -d "=" -f 2-)
    #excludes_file=$(${MKTEMP})
    backup_selection=$(${GREP} '^BACKUP_SELECTION=' "${config_file}" | ${CUT} -d "=" -f 2-)
    #${GREP} '^EXCLUDES=' "${config_file}" | ${CUT} -d "=" -f 2- > ${excludes_file}
    exclude_list=$(${GREP} '^EXCLUDES=' "${config_file}" | ${CUT} -d "=" -f 2-)
    exclude_options=$(echo $exclude_list | sed -e "s/ /' '--exclude=/g" | sed -e "s/^/'--exclude=/g" | sed -e "s/$/'/g")

    if [[ ! -z "${backup_dir}" ]]; then   #do only if backup_dir is defined
        typeOfDailyJob=$(getTypeOfDailyJob ${backup_dir})
        typeOfMonthlyJob=$(getTypeOfMonthlyJob ${backup_dir})
        echo "Type of job : $typeOfDailyJob + $typeOfMonthlyJob"
        ${ECHO} "Config file: $(${BASENAME} $config_file) : ${working_dir} to ${backup_dir}"
        ${ECHO} "...................................................................................................."
        if [ $typeOfMonthlyJob == "month" ]; then
            monthlyJob "${backup_dir}"
        elif [ $typeOfMonthlyJob == "year" ]; then
            yearlyJob "${backup_dir}"
            monthlyJob "${backup_dir}"
        fi

        if [ $typeOfDailyJob == "day" ]; then
            dailyJob "${working_dir}" "${backup_dir}" "${exclude_options}" "${backup_selection}"
        elif [ $typeOfDailyJob == "week" ]; then
            dailyJob "${working_dir}" "${backup_dir}" "${exclude_options}" "${backup_selection}"
			weeklyJob "${backup_dir}"
        fi
    fi
    #${RM} ${excludes_file}   #Clean temp file
done

# -------------------------------------------------------
# STEP 3 - Finished!
# -------------------------------------------------------
${ECHO} "La commande de sauvegarde et rotation quotidienne a terminé son travail..."
${ECHO} "Vérifiez dans le terminal s'il n'y a pas eu d'erreur !"
${ECHO} "$(${DATE} '+%a %d %B %T') : END backup_and_rotate.sh ${typeOfRotation}" >> "${CRON_LOG_FILE}"
