#!/bin/bash
#===================================================================================
#         FILE: inc_lib_backup.sh
#
#        USAGE: Include in you script with the instruction:
#               . "$(dirname "${0}")/lib/inc_lib_backup.sh"
#
#  DESCRIPTION: Librairy used by dailybackup_task.sh
#
#      OPTIONS: none
# REQUIREMENTS: inc_lib.sh v 1.0
#               . "$(dirname "${0}")/lib/inc_lib.sh"
#
#         BUGS: ---
#        NOTES: ---
#      LICENCE: GPL v3
#       AUTHOR: Hervé SUAUDEAU, herve.suaudeau [arob] parisdescartes.fr
#      COMPANY: CNRS, France
#
#    REVISIONS:
#              | Version |    Date    | Comments
#              | ------- | ---------- | --------------------------------------------
#              | 1.0     | 30.05.2016 | Separation of inc_lib from inc_lib_backup
#
#===================================================================================

#Define paths and files
#----------------------
readonly CRON_LOG_FILE=${SCRIPT_PATH}/cronlog.txt
readonly DATE_BACKUP_LOG_FILE=___date_of_backup___.txt
readonly DATE_WORKING_LOG_FILE=___date_of_update___.txt

#===  FUNCTION  ================================================================
#         NAME:  get_last_timestamp
#  DESCRIPTION:  récupère le timestamp de la dernière sauvegarde
#        USAGE:  get_last_timestamp backup_or_working_dir
# PARAMETER  1:  backup_or_working_dir : chemin du backup directory ou working directory
# RETURN VALUE:  timestamp présent dans le fichier ___date_of_backup___.txt ou ___date_of_update___.txt
#===============================================================================
get_last_timestamp() {
  #argument can be empty ==> return 0
  if [ -z "${1}" ]; then
      return 0
  fi
  local BACKUP_OR_WORKING_DIR="${1}"
  local timestamp=$(${CAT} "${BACKUP_OR_WORKING_DIR}/day-1/${DATE_BACKUP_LOG_FILE}" "${BACKUP_OR_WORKING_DIR}/${DATE_WORKING_LOG_FILE}" 2> /dev/null  | ${GREP} "^timestamp : " | ${CUT} -d " " -f 3| ${TAIL} -n 1)
  if [ ! -z "${timestamp}" ]; then
      ${ECHO} ${timestamp}
      return 0
  else
      return -1
  fi
}
#===  FUNCTION  ================================================================
#         NAME:  copy_from_native_to_working_copy
#  DESCRIPTION:  Copie des nouveaux fichiers du dossier native vers le
#                dossier working_copy
#        USAGE:  copy_from_native_to_working_copy source destination exclude_file
# PARAMETER  1:  source      : chemin du native directory
# PARAMETER  2:  destination : chemin du working directory
# PARAMETER  3:  exclude_file : fichier contenant la liste des fichiers à exclure
# RETURN VALUE:   0 if OK
#                -1 if NOK
#===============================================================================
copy_from_native_to_working_copy() {
    #argument can be empty ==> return 0
    if [ -z "${3}" -o -z "${2}" -o -z "${1}" ]; then
        return 0
    fi
    local REPERTOIRE_SOURCE="${1}"
    local REPERTOIRE_DESTINATION="${2}"
    local EXCLUDES_FILE="${3}"

    ${ECHO} "Copie des nouveaux fichiers de \"${REPERTOIRE_SOURCE}\" vers \"${REPERTOIRE_DESTINATION}\"."

    # Détecter la présence du volume de source et interrompre l'opération si nécessaire
    if !(isDirectory "${REPERTOIRE_SOURCE}") ; then
        ${ECHO} "Attention, le disque a sauvegarder (\"${REPERTOIRE_SOURCE}\") n'est pas présent"
        return -1
    fi
    # Détecter la présence du volume de destination et le créer si nécessaire
    if !(isDirectory "${REPERTOIRE_DESTINATION}") ; then
        if !(createDirectory "${REPERTOIRE_DESTINATION}") ; then
            ${ECHO} "ERREUR: Création du répertoire de destination impossible (\"${REPERTOIRE_DESTINATION}\")"
            return -1
        fi
        ${ECHO} "Création du répertoire de destination (${REPERTOIRE_DESTINATION})"
    fi

    updateDirectory "${REPERTOIRE_SOURCE}" "${REPERTOIRE_DESTINATION}" "${EXCLUDES_FILE}"

    # update the mtime of destination dir to reflect the update time
    #  and add a time stamp in file
    ${TOUCH} "${REPERTOIRE_DESTINATION}" ;
    deleteLocalFile "${REPERTOIRE_DESTINATION}/${DATE_WORKING_LOG_FILE}"
    ${ECHO} "Date de la dernière mise à jour depuis le dossier 'native' (${REPERTOIRE_SOURCE}):\n" > "${REPERTOIRE_DESTINATION}/${DATE_WORKING_LOG_FILE}"
    ${ECHO} $(${DATE}) >> "${REPERTOIRE_DESTINATION}/${DATE_WORKING_LOG_FILE}"
    ${ECHO} "timestamp : $(${DATE} +%s)" >> "${REPERTOIRE_DESTINATION}/${DATE_WORKING_LOG_FILE}"
    return ${?}
}

#===  FUNCTION  ================================================================
#         NAME: yearlyJob
#  DESCRIPTION: Do the necessary rotations needed every first day of year
#               step 1: delete the oldest snapshot, if it exists
#               step 2: shift the middle snapshots(s) back by one, if they exist
#               step 3: year-1 is created from the oldest monthly snapshot
#
#               delete year-10                              (step 1)
#               year-09  ---move---> year-10                (step 2)
#               year-08  ---move---> year-09
#               ...
#               year-01  ---move---> year-02
#               month-12 ---move---> year-01                (step 3)
#
#        USAGE: yearlyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# RETURN VALUE: 0 if OK
#              -1 if NOK
#===============================================================================
yearlyJob() {
    #----------------------------------------------------------------------
    #  Tests préparatoires
    #----------------------------------------------------------------------
    #argument can be empty ==> return 0
    if [ -z "${1}" ]; then
        return 0
    fi
    local REPERTOIRE_DESTINATION="${1}"
    ${ECHO} "rotation annuelle de \"${REPERTOIRE_DESTINATION}\"."

    # Détecter la présence du volume de destination et interrompre l'opération si nécessaire
    if [ ! -e "${REPERTOIRE_DESTINATION}" ]; then
        ${ECHO} "Attention, le disque de sauvegarde (\"${REPERTOIRE_DESTINATION}\") n'est pas présent"
        return -1
    fi

    #----------------------------------------------------------------------
    # rotation des backups
    #----------------------------------------------------------------------
    # step 1: delete the oldest snapshot, if it exists:
    deleteLocalDirectory "${REPERTOIRE_DESTINATION}/year-10"

    # step 2: shift the middle snapshots(s) back by one, if they exist
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-09" "${REPERTOIRE_DESTINATION}/year-10"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-08" "${REPERTOIRE_DESTINATION}/year-09"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-07" "${REPERTOIRE_DESTINATION}/year-08"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-06" "${REPERTOIRE_DESTINATION}/year-07"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-05" "${REPERTOIRE_DESTINATION}/year-06"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-04" "${REPERTOIRE_DESTINATION}/year-05"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-03" "${REPERTOIRE_DESTINATION}/year-04"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-02" "${REPERTOIRE_DESTINATION}/year-03"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/year-01" "${REPERTOIRE_DESTINATION}/year-02"


    # step 3: Get the oldest monthly snapshot as year-1
    if [ -e "${REPERTOIRE_DESTINATION}/month-11" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-11" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-10" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-10" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-09" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-09" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-08" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-08" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-07" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-07" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-06" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-06" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-05" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-05" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-04" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-04" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-03" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-03" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-02" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-02" "${REPERTOIRE_DESTINATION}/year-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/month-01" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-01" "${REPERTOIRE_DESTINATION}/year-01"
    fi

    return 0
}

#===  FUNCTION  ================================================================
#         NAME: monthlyJob
#  DESCRIPTION: Do the necessary rotations needed every first day of month
#               step 1: replace the newest yearly snapshot by the monthly snapshot aged by a year
#               step 2: shift the middle snapshots(s) back by one, if they exist
#               step 3: month-1 is created from the oldest weekly snapshot
#
#               month-11 -->delete                          (step 1)
#               month-10 ---move---> month-11               (step 2)
#               month-09 ---move---> month-10
#               ...
#               month-01 ---move---> month-02
#               week-4   ---move---> month-01               (step 3)
#
#        USAGE: monthlyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# RETURN VALUE: 0 if OK
#              -1 if NOK
#===============================================================================
monthlyJob() {
    #----------------------------------------------------------------------
    #  Tests préparatoires
    #----------------------------------------------------------------------
    #argument can be empty ==> return 0
    if [ -z "${1}" ]; then
        return 0
   fi
    local REPERTOIRE_DESTINATION="${1}"
    ${ECHO} "rotation mensuelle de \"${REPERTOIRE_DESTINATION}\"."

    # Détecter la présence du volume de destination et interrompre l'opération si nécessaire
    if [ ! -e "${REPERTOIRE_DESTINATION}" ]
    then
        ${ECHO} "Attention, le disque de sauvegarde n'est pas présent"
        return -1
    fi

    #----------------------------------------------------------------------
    # rotation des backups
    #----------------------------------------------------------------------
    # step 1: delete the oldest monthly snapshot
    deleteLocalDirectory "${REPERTOIRE_DESTINATION}/month-11"
    # step 2: shift the middle snapshots(s) back by one, if they exist
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-10" "${REPERTOIRE_DESTINATION}/month-11"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-09" "${REPERTOIRE_DESTINATION}/month-10"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-08" "${REPERTOIRE_DESTINATION}/month-09"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-07" "${REPERTOIRE_DESTINATION}/month-08"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-06" "${REPERTOIRE_DESTINATION}/month-07"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-05" "${REPERTOIRE_DESTINATION}/month-06"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-04" "${REPERTOIRE_DESTINATION}/month-05"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-03" "${REPERTOIRE_DESTINATION}/month-04"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-02" "${REPERTOIRE_DESTINATION}/month-03"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/month-01" "${REPERTOIRE_DESTINATION}/month-02"

    # step 3: Get the oldest weekly snapshot as month-1
    if [ -e "${REPERTOIRE_DESTINATION}/week-4" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-4" "${REPERTOIRE_DESTINATION}/month-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/week-3" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-3" "${REPERTOIRE_DESTINATION}/month-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/week-2" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-2" "${REPERTOIRE_DESTINATION}/month-01"
    elif [ -e "${REPERTOIRE_DESTINATION}/week-1" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-1" "${REPERTOIRE_DESTINATION}/month-01"
    fi

    return 0
}

#===  FUNCTION  ================================================================
#         NAME: weeklyJob
#  DESCRIPTION: Do the necessary rotations needed every first day of week
#               step 1: delete the Weekly snapshot aged by hardly a month
#               step 2: shift the middle snapshots(s) back by one, if they exist
#               step 3: Get the oldest daily snapshot as week-1
#
#               week-4 --->delete                       (step 1)
#               week-3 ---move---> week-4               (step 2)
#               week-2 ---move---> week-3
#               week-1 ---move---> week-2
#               day-6  ---move---> week-1               (step 3)
#
#        USAGE: weeklyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# RETURN VALUE: 0 if OK
#              -1 if NOK
#===============================================================================
weeklyJob() {
    #----------------------------------------------------------------------
    #  Tests préparatoires
    #----------------------------------------------------------------------
    #argument can be empty ==> return 0
    if [ -z "${1}" ]; then
        return 0
    fi
    local REPERTOIRE_DESTINATION="${1}"
    ${ECHO} "rotation hebdomadaire de \"${REPERTOIRE_DESTINATION}\"."

    # Détecter la présence du volume de destination et interrompre l'opération si nécessaire
    if [ ! -e "${REPERTOIRE_DESTINATION}" ]; then
        ${ECHO} "Attention, le disque de sauvegarde (\"${REPERTOIRE_DESTINATION}\") n'est pas présent"
        return -1
    fi

    #----------------------------------------------------------------------
    # rotation des backups
    #----------------------------------------------------------------------
    # step 1: delete the oldest weekly snapshot
    deleteLocalDirectory "${REPERTOIRE_DESTINATION}/week-4"
    # step 2: shift the middle snapshots(s) back by one, if they exist
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-3" "${REPERTOIRE_DESTINATION}/week-4"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-2" "${REPERTOIRE_DESTINATION}/week-3"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/week-1" "${REPERTOIRE_DESTINATION}/week-2"

    # step 3: Get the oldest daily snapshot as week-1
    if [ -e "${REPERTOIRE_DESTINATION}/day-6" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-6" "${REPERTOIRE_DESTINATION}/week-1"
    elif [ -e "${REPERTOIRE_DESTINATION}/day-5" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-5" "${REPERTOIRE_DESTINATION}/week-1"
    elif [ -e "${REPERTOIRE_DESTINATION}/day-4" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-4" "${REPERTOIRE_DESTINATION}/week-1"
    elif [ -e "${REPERTOIRE_DESTINATION}/day-3" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-3" "${REPERTOIRE_DESTINATION}/week-1"
    elif [ -e "${REPERTOIRE_DESTINATION}/day-2" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-2" "${REPERTOIRE_DESTINATION}/week-1"
    elif [ -e "${REPERTOIRE_DESTINATION}/day-1" ]; then
        moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-1" "${REPERTOIRE_DESTINATION}/week-1"
    fi

    return 0
}

#===  FUNCTION  ================================================================
#         NAME: dailyJob
#  DESCRIPTION: Do the necessary backups and rotations needed every day
#               step 1: delete the daily snapshot aged by a week
#               step 1: delete the oldest snapshot, if it exists
#               step 2: shift the middle snapshots(s) back by one, if they exist
#               step 3: make a hard-link-only copy of all filles
#                       of the latest snapshot to last daily snapshot
#               step 4: rsync from the system into the newest daily snapshot
#               step 5: update the mtime of day-1 to reflect the snapshot time
#                        and add a time stamp in file
#
#               day-6 --->delete-                       (step 1)
#               day-5 ---move---> day-6                 (step 2)
#               day-4 ---move---> day-5
#               day-3 ---move---> day-4
#               day-2 ---move---> day-3
#               day-1 ---hard-link-copy---> day-2       (step 3)
#               working_copy ---rsync---> day-1         (step 4)
#               touch day-1                             (step 5)
#               create new day-1/date_of_backup_file
#
#        USAGE: dailyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# RETURN VALUE: 0 if OK
#              -1 if NOK
#===============================================================================
dailyJob() {
    #----------------------------------------------------------------------
    #  Tests préparatoires
    #----------------------------------------------------------------------
    #arguments can be empty ==> return 0
    if [ -z "${3}" -o -z "${2}" -o -z "${1}" ]; then
        return 0
    fi
    local REPERTOIRE_SOURCE="${1}"
    local REPERTOIRE_DESTINATION="${2}"
    local EXCLUDES="${3}"

    ${ECHO} "Archivage des fichiers de ${REPERTOIRE_SOURCE} vers ${REPERTOIRE_DESTINATION}."

    # Détecter la présence du volume de source et interrompre l'opération si nécessaire
    if !(isDirectory "${REPERTOIRE_SOURCE}") ; then
        ${ECHO} "Attention, le disque a sauvegarder (${REPERTOIRE_SOURCE}) n'est pas présent"
        return -1
    fi

    # Détecter la présence du volume de destination et le créer si nécessaire
    if [ ! -e "${REPERTOIRE_DESTINATION}" ]; then
        if !(createDirectory "${REPERTOIRE_DESTINATION}") ; then
            ${ECHO} "ERREUR: Création du répertoire de destination impossible (${REPERTOIRE_DESTINATION})"
            return -1
        fi
        ${ECHO} "Création du répertoire de destination (${REPERTOIRE_DESTINATION})"
    fi

    #----------------------------------------------------------------------
    # rotation des backups
    #----------------------------------------------------------------------
    # step 1: delete the oldest daily snapshot
    deleteLocalDirectory "${REPERTOIRE_DESTINATION}/day-6"
    # step 2: shift the middle snapshots(s) back by one, if they exist
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-5" "${REPERTOIRE_DESTINATION}/day-6"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-4" "${REPERTOIRE_DESTINATION}/day-5"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-3" "${REPERTOIRE_DESTINATION}/day-4"
    moveLocalDirectory "${REPERTOIRE_DESTINATION}/day-2" "${REPERTOIRE_DESTINATION}/day-3"
    # step 3: make a hard-link-only (except for dirs) copy of the latest snapshot,
    # if that exists
    if [ -d "${REPERTOIRE_DESTINATION}/day-1" ] ; then          \
        ${ECHO} "-->"${CP} -al "${REPERTOIRE_DESTINATION}/day-1" "${REPERTOIRE_DESTINATION}/day-2"  ;   \
        ${CP} -al "${REPERTOIRE_DESTINATION}/day-1" "${REPERTOIRE_DESTINATION}/day-2" ;
    fi

    # step 4: rsync from the system into the latest snapshot (notice that
    # rsync behaves like cp --remove-destination by default, so the destination
    # is unlinked first.  If it were not so, this would copy over the other
    # snapshot(s) too!
    # Rsync otions:
    #               -a = -rlptgoD
    #                       -r (récusif) -l (copie liens symboliques) -p (copie permissions)
    #                       -t (copie dates modif) -g (copie groupe) -o (copie propriétaire)
    #                       -D (copie fichiers en mode bloc, carractère et fichiers spéciaux)
    #               -H copie les liens en dur
    #               --delete supprime fichiers qui sont effacés de la source
    #               --force supprime les dossiers effacés de la source
    #               --stats Affiche les statistiques sur les fichiers.
    ${ECHO} "-->${RSYNC} -va --delete --force --delete-excluded --exclude-from="${EXCLUDES}" \"${REPERTOIRE_SOURCE}/\" \"${REPERTOIRE_DESTINATION}/day-1/\"" ;
    ${RSYNC} -av --delete --force --delete-excluded --exclude-from="${EXCLUDES}" "${REPERTOIRE_SOURCE}/" "${REPERTOIRE_DESTINATION}/day-1/"

    # step 5: update the mtime of day-1 to reflect the snapshot time
    #         and add a time stamp in file
    ${TOUCH} "${REPERTOIRE_DESTINATION}/day-1" ;
    deleteLocalFile "${REPERTOIRE_DESTINATION}/day-1/${DATE_BACKUP_LOG_FILE}"
    ${ECHO} "Date de la dernière sauvegarde:" > "${REPERTOIRE_DESTINATION}/day-1/${DATE_BACKUP_LOG_FILE}"
    ${ECHO} $(${DATE}) >> "${REPERTOIRE_DESTINATION}/day-1/${DATE_BACKUP_LOG_FILE}"
    ${ECHO} "timestamp : $(${DATE} +%s)" >> "${REPERTOIRE_DESTINATION}/day-1/${DATE_BACKUP_LOG_FILE}"
    return 0
}


#===  FUNCTION  ================================================================
#         NAME: getTypeOfDailyJob
#  DESCRIPTION: Get the date and analyse what type of daily job sould be done
#
#               If today is the first day of the week
#                  or last backup was last week             => weekly job
#               else if last backup was yesterday of before => daily job
#               else                                        => do nothing
#
#        USAGE: getTypeOfDailyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# PARAMETER  2 (optional): change the timestamp of today (usefull for test
#                          or retrospective scripts)
# ECHO VALUE:   "week", "day" or "none"
# RETURN VALUE: none
#===============================================================================
getTypeOfDailyJob () {
  #argument can be empty ==> return 0
  if [ -z "${1}" ]; then
      return 0    return
  fi

  local BACKUP_DIR="${1}"

  if [ -z "${2}" ]; then
    local current_timestamp=$(${DATE} +%s)
  	local day_of_the_week=$(${DATE} '+%u')
  else
	local current_timestamp="${2}"
	local day_of_the_week="$(${DATE} -d @${current_timestamp} +%u)"
  fi

  if [ "${day_of_the_week}" == 1 ]; then
      #If first day of week
      ${ECHO} 'week'
      return
  fi
  local last_backup_timestamp=$(get_last_timestamp ${BACKUP_DIR})
  if [[ ! -z "${last_backup_timestamp}" ]]; then
    local current_week=$(${DATE} -d @${current_timestamp} +%W)
    local last_backup_week=$(${DATE} -d @${last_backup_timestamp} +%W)
    local current_day=$(${DATE} -d @${current_timestamp} +%j)
    local last_backup_day=$(${DATE} -d @${last_backup_timestamp} +%j)
    if [[ "${last_backup_week}" != "${current_week}" ]]; then
      #if last backup was last week
      ${ECHO} 'week'
      return
    fi
    if [[ "${last_backup_day}" != "${current_day}" ]]; then
      #if last backup was yesterday of before
      ${ECHO} 'day'
      return
    fi
    #Backup was not last day => Do nothing
    ${ECHO} 'none'
    return
  fi
  #last_backup_timestamp not recognized
  ${ECHO} 'day'
  return
}

#===  FUNCTION  ================================================================
#         NAME: getTypeOfMonthlyJob
#  DESCRIPTION: Get the date and analyse what type of monthly job sould be done
#               If last backup was yesterday of before
#                 If today is the first day of the year
#                   or if last backup was last year      => yearly job
#                 If today is the first day of the month
#                   or if last backup was last month     => monthly job
#                 else                                   => nothing
#               else                                     => nothing
#
#        USAGE: getTypeOfMonthlyJob backup_directory
# PARAMETER  1: backup_directory : chemin du backup directory
# PARAMETER  2 (optional): change the timestamp of today (usefull for test
#                          or retrospective scripts)
# ECHO VALUE:   "year", "month" or "none"
# RETURN VALUE: none
#===============================================================================
getTypeOfMonthlyJob () {
    #argument can be empty ==> return 0
    if [ -z "${1}" ]; then
        return 0
    fi

	local BACKUP_DIR="${1}"

	if [ -z "${2}" ]; then
		local day_of_the_year=$(${DATE} '+%j')
		local current_timestamp=$(${DATE} +%s)
    else
		local current_timestamp="${2}"
		local day_of_the_year="$(${DATE} -d @${current_timestamp} +%j)"
    fi

    local last_backup_timestamp=$(get_last_timestamp ${BACKUP_DIR})
    if [[ ! -z "${last_backup_timestamp}" ]]; then
        local current_year=$(${DATE} -d @${current_timestamp} +%Y)
        local last_backup_year=$(${DATE} -d @${last_backup_timestamp} +%Y)
        local current_month=$(${DATE} -d @${current_timestamp} +%m)
        local last_backup_month=$(${DATE} -d @${last_backup_timestamp} +%m)
        local current_day=$(${DATE} -d @${current_timestamp} +%j)
        local last_backup_day=$(${DATE} -d @${last_backup_timestamp} +%j)
        if [[ "${last_backup_day}" != "${current_day}" ]]; then
            #if last backup was yesterday of before
            if [ "${day_of_the_year}" == 001 ]; then
                #if first day of year
                ${ECHO} 'year'
                return
            fi
            if [[ "${last_backup_year}" != "${current_year}" ]]; then
                #if last backup was last year
                ${ECHO} 'year'
                return
            fi
            local day_of_the_month=$(${DATE} '+%d')
            if [ "${day_of_the_month}" == 01 ]; then
                #If first day of month
                ${ECHO} 'month'
                return
            fi
            if [[ "${last_backup_month}" != "${current_month}" ]]; then
                #if last backup was last month
                ${ECHO} 'month'
                return
            fi
        fi
    fi
    ${ECHO} 'none'
    return
}
