#!/bin/bash
#===================================================================================
#         FILE: inc_lib_backup.sh
#
#        USAGE: Include in you script with the instruction:
#               . "$(dirname "${0}")/inc_lib_backup.sh"
#
#  DESCRIPTION: Librairy used by dailybackup_task.sh
#
#      OPTIONS: none
# REQUIREMENTS: inc_lib.sh v 1.0
#               . "$(dirname "${0}")/inc_lib.sh"
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

#===  FUNCTION  ================================================================
#         NAME:  copy_from_native_to_working_copy
#  DESCRIPTION:  Copie des nouveaux fichiers du dossier native vers le
#                dossier working_copy
#        USAGE:  copy_from_native_to_working_copy source destination
# PARAMETER  1:  source      : chemin du native directory
# PARAMETER  1:  destination : chemin du working directory
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
    ${ECHO} "-->${RSYNC} -va --delete --delete-excluded --exclude-from="${EXCLUDES}" \"${REPERTOIRE_SOURCE}/\" \"${REPERTOIRE_DESTINATION}/day-1/\"" ;
    ${RSYNC} -av --delete --delete-excluded --exclude-from="${EXCLUDES}" "${REPERTOIRE_SOURCE}/" "${REPERTOIRE_DESTINATION}/day-1/"

    # step 5: update the mtime of day-1 to reflect the snapshot time
    #         and add a time stamp in file
    ${TOUCH} "${REPERTOIRE_DESTINATION}/day-1" ;
    deleteLocalFile "${REPERTOIRE_DESTINATION}/day-1/${DATE_LOG_FILE}"
    ${ECHO} "Date de la dernière sauvegarde:" > "${REPERTOIRE_DESTINATION}/day-1/${DATE_LOG_FILE}"
    ${ECHO} $(${DATE}) >> "${REPERTOIRE_DESTINATION}/day-1/${DATE_LOG_FILE}"

    return 0
}


#===  FUNCTION  ================================================================
#         NAME: getTypeOfDailyJob
#  DESCRIPTION: Get the date and analyse what type of daily job sould be done
#               If today is the first day of the week  => weekly job
#               else                                   => daily job
#
#        USAGE: getTypeOfDailyJob
# PARAMETER  1: backup_directory : chemin du backup directory
# ECHO VALUE:   "week" or "day"
# RETURN VALUE: none
#===============================================================================
getTypeOfDailyJob () {
    local ifStart=$(${DATE} '+%u')
    if [ "${ifStart}" == 1 ]; then
        #If first day of week
        ${ECHO} 'week'
        return
    fi

    ${ECHO} 'day'
    return
}

#===  FUNCTION  ================================================================
#         NAME: getTypeOfMonthlyJob
#  DESCRIPTION: Get the date and analyse what type of monthly job sould be done
#               If today is the first day of the year  => yearly job
#               If today is the first day of the month => monthly job
#               else                                   => nothing
#
#        USAGE: getTypeOfMonthlyJob
# PARAMETER  1: backup_directory : chemin du backup directory
# ECHO VALUE:   "year", "month" or "none"
# RETURN VALUE: none
#===============================================================================
getTypeOfMonthlyJob () {
    local ifStart=$(${DATE} '+%j')
    if [ "${ifStart}" == 001 ]; then
        #if first day of year
        ${ECHO} 'year'
        return
    fi

    local ifStart=$(${DATE} '+%d')
    if [ "${ifStart}" == 01 ]; then
        #If first day of month
        ${ECHO} 'month'
        return
    fi

    ${ECHO} 'none'
    return
}
