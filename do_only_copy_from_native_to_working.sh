#!/bin/bash
#===================================================================================
#
#         FILE: do_only_copy_from_native_to_working.sh
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
#if [ $(${ID} -u) != 0 ]; then
#    ${ECHO} "Sorry, must be root.  Exiting..."; exit;
#fi

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
    exclude_list=$(${GREP} '^EXCLUDES=' "${config_file}" | ${CUT} -d "=" -f 2-)
    exclude_options=$(echo $exclude_list | sed -e "s/ / --exclude=/g" | sed -e "s/^/--exclude=/g" )

    if [[ ! -z "${native_dir}" ]]; then   #Copy only if native_dir is defined
        ${ECHO} "Config file: $(${BASENAME} $config_file) : ${native_dir} to ${working_dir}"
        copy_from_native_to_working_copy "${native_dir}" "${working_dir}" "${exclude_options}"
    fi
done
