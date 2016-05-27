#!/bin/bash
#===================================================================================
#
# Librairy used by dailybackup_task.sh
#
#===================================================================================
#------ Commandes utilisées par ce script ----
readonly WHICH=/usr/bin/which

die() { echo "$@" 1>&2 ; exit 1; }

#===  FUNCTION  ================================================================
#         NAME:  getPathAndCheckInstall
#  DESCRIPTION:  Récupère le chemin d'une application et vérifie si elle
#                est installée
#        USAGE:  $MYAPP_PATH = getPathAndCheckInstall myapp
# PARAMETER  1:  myapp : application
#                        (peut être de la forme login@host:path)
# RETURN VALUE:  Absolute path of application
#===============================================================================
getPathAndCheckInstall() {
    #argument cannot be empty ==> die
    if [[ -z "${1}" ]]; then
        die "FATAL ERROR: Use function getPathAndCheckInstall with an argument"
    fi
    local application=${1}
    local APPLICATION_PATH=$(${WHICH} ${application})
    if [[ ! -x ${APPLICATION_PATH} ]]; then
        die "FATAL ERROR: ${application} is not installed"
    fi
    echo ${APPLICATION_PATH}
}

#----------------------------------------------------------------------
#  Get the path of all programs
#----------------------------------------------------------------------
readonly CAT=$(getPathAndCheckInstall cat)
readonly CP=$(getPathAndCheckInstall cp)
readonly CUT=$(getPathAndCheckInstall cut)
#readonly CRONTAB=$(getPathAndCheckInstall crontab)
readonly DATE=$(getPathAndCheckInstall date)
readonly ECHO=$(getPathAndCheckInstall echo)
readonly GREP=$(getPathAndCheckInstall grep)
readonly ID=$(getPathAndCheckInstall id)
readonly MKDIR=$(getPathAndCheckInstall mkdir)
readonly MV=$(getPathAndCheckInstall mv)
readonly RM=$(getPathAndCheckInstall rm)
readonly RSYNC=$(getPathAndCheckInstall rsync)
readonly SSH=$(getPathAndCheckInstall ssh)
readonly TOUCH=$(getPathAndCheckInstall touch)
readonly MKTEMP=$(getPathAndCheckInstall mktemp)
readonly BASENAME=$(getPathAndCheckInstall basename)
readonly DIRNAME=$(getPathAndCheckInstall dirname)

#Define paths and files
#----------------------
readonly SCRIPT_PATH=$(${DIRNAME} "${0}")
#readonly SERVICE=$(${WHICH} service)
#readonly SERVICE_CRON_RESTART="${SERVICE} cron restart"
readonly CRON_LOG_FILE=${SCRIPT_PATH}/cronlog.txt
readonly DATE_LOG_FILE=___date_of_backup___.txt

#===  FUNCTION  ================================================================
#         NAME:  isDirectory
#  DESCRIPTION:  Teste si un chemin est un bien un répertoire
#                (qu'il soit local ou distant via ssh).
#        USAGE:  if isDirectory $path ; then
#                   Action si OK
#                fi
# PARAMETER  1:  $path : Repertoire à tester
#                        (peut être de la forme login@host:path)
#===============================================================================
isDirectory() {
    #argument cannot be empty ==> die
    if [ -z "${1}" ]; then
         die "FATAL ERROR: Bad number of arguments in function isDirectory"
    fi

    local source=${1}
    if [[ ${1} =~ .+@.+:.+ ]]; then
        #remote path : login@host:path
        local login_host=$(${ECHO} "${1}" | ${CUT} -d ':' -f 1)
        local remote_path=$(${ECHO} "${1}" | ${CUT} -d ':' -f 2)
        isDir=$(${SSH} "${login_host}" "if [ -d '${remote_path}' ] ; then ${ECHO} '0'; fi")
        if [[ ${isDir} == '0' ]]; then
            return 0
        fi
    else
        if [ -d ${source} ] ; then
            return 0
        fi
    fi
    return 1
}

#===  FUNCTION  ================================================================
#         NAME:  createDirectory
#  DESCRIPTION:  Crée un répertoire (local ou distant) puis teste son existence.
#        USAGE:  if createDirectory $path ; then
#                   Action si OK
#                fi
# PARAMETER  1:  $path : Repertoire à créer puis à tester l'existence
#                        (peut être de la forme login@host:path)
#===============================================================================
createDirectory() {
    #argument cannot be empty ==> die
    if [ -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function createDirectory"
     fi

    source="${1}"
    if [[ "${1}" =~ .+@.+:.+ ]]; then
        #source : login@host:path
        local login_host=$(${ECHO} "${source}" | ${CUT} -d ':' -f 1)
        local remote_path=$(${ECHO} "${source}" | ${CUT} -d ':' -f 2)
        ${SSH} "${login_host}" "${MKDIR} -p \"${remote_path}\""
        if isDirectory "${source}" ; then
            return 0
        fi
    else
        ${MKDIR} -p "${source}"
        if [ -d "${source}" ] ; then
            return 0
        fi
    fi
    return 1
}

#===  FUNCTION  ================================================================
#         NAME:  updateDirectory
#  DESCRIPTION:  Synchronise deux répertoires (locaux ou distants).
#                Contrairement à rsync, peut utiliser deux répertoires distants
#        USAGE:  updateDirectory source_path destination_path
# PARAMETER  1:  source_path      : chemin source
#                                   (peut être de la forme login@host:path)
# PARAMETER  2:  destination_path : chemin destination
#                                   (peut être de la forme login@host:path)
#===============================================================================
updateDirectory() {
    #arguments cannot be empty ==> die
    if [ -z "${3}" -o -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function updateDirectory"
    fi

    local REPERTOIRE_SOURCE="${1}"
    local REPERTOIRE_DESTINATION="${2}"
    local EXCLUDES="${3}"

    # Options de Rsync
    # -----------------------
    # -a -a, --archive               mode archivage; identique à -rlptgoD (pas -H)
    #     -r, --recursive             visite récursive des répertoires
    #     -l, --links                 copie les liens symboliques comme liens symboliques
    #     -p, --perms                 préserve les permissions
    #     -t, --times                 préserve les dates
    #     -g, --group                 préserve le groupe
    #     -o, --owner                 préserve le propriétaire (root uniquement)
    #     -D, --devices               préserve les périphériques (root uniquement)
    # -n, --dry-run               montre ce qui aurait été transféré
    #     --ignore-existing       ignore les fichiers qui existent déjà
    #     --cvs-exclude
    #
    if [[ "${REPERTOIRE_SOURCE}" =~ .+@.+:.+ ]]; then
        if [[ "${REPERTOIRE_DESTINATION}" =~ .+@.+:.+ ]]; then
            #Both remote
            local login_host1=$(${ECHO} "${REPERTOIRE_SOURCE}" | ${CUT} -d ':' -f 1)
            local path1=$(${ECHO} "${REPERTOIRE_SOURCE}" | ${CUT} -d ':' -f 2)
            ${ECHO} "-->"${SSH} "${login_host1}" "${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${path1}/\" \"${REPERTOIRE_DESTINATION}/\""
            ${SSH} "${login_host1}" "${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${path1}/\" \"${REPERTOIRE_DESTINATION}/\""
            return ${?}
        fi
    fi
    ${ECHO} "-->${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${REPERTOIRE_SOURCE}/\" \"${REPERTOIRE_DESTINATION}/\""
    ${RSYNC} -av --ignore-existing --exclude-from="${EXCLUDES}" "${REPERTOIRE_SOURCE}/" "${REPERTOIRE_DESTINATION}/"
    return ${?}
}

#===  FUNCTION  ================================================================
#         NAME:  moveLocalDirectory
#  DESCRIPTION:  Déplace un répertoire source vers une destination (teste l'existence)
#        USAGE:  moveLocalDirectory source destination
# PARAMETER  1:  source      : chemin source
# PARAMETER  1:  destination : chemin destination
#===============================================================================
moveLocalDirectory() {
    #arguments cannot be empty ==> die
    if [ -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function moveLocalDirectory"
    fi

    local source="${1}"
    local dest="${2}"
    if [ -d "${source}" ] ; then            \
        ${ECHO} "-->"${MV} "${source}" "${dest}" ;  \
        ${MV} "${source}" "${dest}" ;   \
    fi
}

#===  FUNCTION  ================================================================
#         NAME:  deleteLocalDirectory
#  DESCRIPTION:  Efface un répertoire(teste l'existence)
#        USAGE:  deleteLocalDirectory repertoire
# PARAMETER  1:  repertoire à supprimer
#===============================================================================
deleteLocalDirectory() {
    #arguments cannot be empty ==> die
    if [ -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function deleteLocalDirectory"
    fi

    local dir="${1}"
    if [ -d ${dir} ] ; then         \
        ${ECHO} "-->${RM} -rf \"${dir}\""; \
        ${RM} -rf "${dir}" ; \
    fi
}

#===  FUNCTION  ================================================================
#         NAME:  deleteLocalFile
#  DESCRIPTION:  Efface un fichier (teste l'existence)
#        USAGE:  deleteLocalFile fichier
# PARAMETER  1:  fichier à supprimer
#===============================================================================
deleteLocalFile() {
    #arguments cannot be empty ==> die
    if [ -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function deleteLocalFile"
    fi

    local dir="${1}"
    if [ -f ${dir} ] ; then         \
        ${ECHO} "-->${RM} \"${dir}\""; \
        ${RM} "${dir}" ; \
    fi
}

#===  FUNCTION  ================================================================
#         NAME:  replaceLocalDirectory
#  DESCRIPTION:  Remplace un répertoire par un autre
#        USAGE:  replaceLocalDirectory source destination
# PARAMETER  1:  source      : chemin source
# PARAMETER  1:  destination : chemin destination
#===============================================================================
replaceLocalDirectory() {
    #arguments cannot be empty ==> die
    if [ -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function replaceLocalDirectory"
    fi

    local source="${1}"
    local dest="${2}"
    if [ -d "${source}" ] ; then
        if [ -d "${dest}" ] ; then
            deleteLocalDirectory "${dest}"
        fi
        ${ECHO} "-->${MV} \"${source}\" \"${dest}\"" ;
        ${MV} "${source}" "${dest}" ;
    fi
}

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
