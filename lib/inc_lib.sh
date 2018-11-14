#!/bin/bash
#===================================================================================
#         FILE: inc_lib.sh
#
#        USAGE: Include in you script and set the VERBOSE_INFO flag. Example:
#               . "$(dirname "${0}")/lib/inc_lib.sh"
#               VERBOSE_INFO=true
#
#  DESCRIPTION: General purpose Bash librairy
#
#               Check errors, installtion and verbose info:
#               -------------------------------------------
#                   -> die "Fatal error message"
#                   -> getPathAndCheckInstall ProgramToTestInstallation
#                   -> verbose_info "Message a afficher"
#
#               local or remote manipulation of files :
#               ---------------------------------------
#                   -> isDirectory [login@host:]pathToTest
#                   -> createDirectory [login@host:]pathToCreate
#                   -> updateDirectory [login1@host1:]source_path [login2@host2:]destination_path exclude_file
#
#               local manipulation of files :
#               -----------------------------
#                   -> moveLocalDirectory LocalSource LocalDestination
#                   -> deleteLocalDirectory repertoire
#                   -> deleteLocalFile fichier
#                   -> replaceLocalDirectory source destination
#
#      OPTIONS: none
# REQUIREMENTS: none
#         BUGS: ---
#        NOTES: ---
#      LICENCE: GPL v3
#       AUTHOR: Hervé SUAUDEAU, herve.suaudeau [arob] parisdescartes.fr
#      COMPANY: CNRS, France
#
#    REVISIONS:
#              | Version |    Date    | Comments
#              | ------- | ---------- | --------------------------------------------
#              | 1.0     | 30.05.2016 | First commit into Github.
#              | 1.1     | 31.05.2016 | Improve doc and add verbose_info
#
#===================================================================================
#------ Commandes utilisées par ce script ----
readonly WHICH=/usr/bin/which

#"quit" replaces "exit 1" to avoid kill connexion to the shell
quit() { kill -SIGINT $$; }
die() { echo "$@" 1>&2 ; quit; }

#===  FUNCTION  ================================================================
#         NAME:  getPathAndCheckInstall
#  DESCRIPTION:  Récupère le chemin d'une application et vérifie si elle
#                est installée
#        USAGE:  $MYAPP_PATH=$(getPathAndCheckInstall myapp)
# PARAMETER  1:  myapp : application
#                        (peut être de la forme login@host:path)
# RETURN VALUE:  Absolute path of application
#===============================================================================
getPathAndCheckInstall() {
    #argument cannot be empty ==> die
    if [[ -z "${1}" ]]; then
        die "FATAL ERROR: Use function getPathAndCheckInstall with an argument"
    else
      local application="${1}"
      local APPLICATION_PATH=$(${WHICH} "${application}")
      if [[ ! -x "${APPLICATION_PATH}" ]]; then
          die "FATAL ERROR: ${application} is not installed"
      else
        echo "${APPLICATION_PATH}"
      fi
    fi
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
readonly TAIL=$(getPathAndCheckInstall tail)

#Define paths and files
#----------------------
readonly SCRIPT_PATH=$(${DIRNAME} "${0}")
#readonly SERVICE=$(${WHICH} service)
#readonly SERVICE_CRON_RESTART="${SERVICE} cron restart"

#===  FUNCTION  ================================================================
#         NAME:  verbose_info
#  DESCRIPTION:  Affiche un texte que si VERBOSE_INFO = true
#        USAGE:  verbose_info "Message a afficher"
#===============================================================================
verbose_info() {
    if [[ "${VERBOSE_INFO}" == "true" ]]; then
        ${ECHO} "$*" >&2
    fi
}

#===  FUNCTION  ================================================================
#         NAME:  isDirectory
#  DESCRIPTION:  Teste si un chemin est un bien un répertoire
#                (qu'il soit local ou distant via ssh).
#        USAGE:  isDirectory [login@host:]pathToTest
#      EXAMPLE:  if isDirectory $pathToTest ; then
#                   Action si OK
#                fi
# PARAMETER  1:  $pathToTest : Repertoire à tester
#                        (peut être de la forme login@host:pathToTest)
#===============================================================================
isDirectory() {
    #argument cannot be empty ==> die
    if [[ -z "${1}" ]]; then
         die "FATAL ERROR: Bad number of arguments in function isDirectory"
    fi

    local source=${1}
    if [[ "${1}" =~ .+@.+:.+ ]]; then
        #remote path : login@host:path
        local login_host=$(${ECHO} "${1}" | ${CUT} -d ':' -f 1)
        local remote_path=$(${ECHO} "${1}" | ${CUT} -d ':' -f 2)
        isDir=$(${SSH} "${login_host}" "if [ -d '${remote_path}' ] ; then ${ECHO} '0'; fi")
        if [[ "${isDir}" == '0' ]]; then
            return 0
        fi
    else
        if [[ -d "${source}" ]] ; then
            return 0
        fi
    fi
    return 1
}

#===  FUNCTION  ================================================================
#         NAME:  createDirectory
#  DESCRIPTION:  Crée un répertoire (local ou distant) puis teste son existence.
#        USAGE:  createDirectory [login@host:]pathToCreate
#      EXAMPLE:  if createDirectory $pathToCreate ; then
#                   Action si OK
#                fi
# PARAMETER  1:  $pathToCreate : Repertoire à créer puis à tester l'existence
#                        (peut être de la forme login@host:pathToCreate)
#===============================================================================
createDirectory() {
    #argument cannot be empty ==> die
    if [[ -z "${1}" ]]; then
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
        if [[ -d "${source}" ]] ; then
            return 0
        fi
    fi
    return 1
}

#===  FUNCTION  ================================================================
#         NAME:  updateDirectory
#  DESCRIPTION:  Synchronise deux répertoires (locaux ou distants).
#                Contrairement à rsync, peut utiliser deux répertoires distants
#        USAGE:  updateDirectory [login1@host1:]source_path [login2@host2:]destination_path
# PARAMETER  1:  source_path      : chemin source
#                                   (peut être de la forme login@host:path)
# PARAMETER  2:  destination_path : chemin destination
#                                   (peut être de la forme login@host:path)
# PARAMETER  3:  exclude_file     : Fichier listant les fichiers à exclure
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
    # -H copie les liens en dur
    # --delete supprime fichiers qui sont effacés de la source
    # --force supprime les dossiers effacés de la source
    # --stats Affiche les statistiques sur les fichiers.
    if [[ "${REPERTOIRE_SOURCE}" =~ .+@.+:.+ ]]; then
        if [[ "${REPERTOIRE_DESTINATION}" =~ .+@.+:.+ ]]; then
            #Both remote
            local login_host1=$(${ECHO} "${REPERTOIRE_SOURCE}" | ${CUT} -d ':' -f 1)
            local path1=$(${ECHO} "${REPERTOIRE_SOURCE}" | ${CUT} -d ':' -f 2)
            verbose_info "-->"${SSH} "${login_host1}" "${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${path1}/\" \"${REPERTOIRE_DESTINATION}/\""
            echo ${SSH} "${login_host1}" "${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${path1}/\" \"${REPERTOIRE_DESTINATION}/\""
            return ${?}
        fi
    fi
    verbose_info "-->${RSYNC} -av --ignore-existing --exclude-from=\"${EXCLUDES}\" \"${REPERTOIRE_SOURCE}/\" \"${REPERTOIRE_DESTINATION}/\""
    ${RSYNC} -av --ignore-existing --exclude-from="${EXCLUDES}" "${REPERTOIRE_SOURCE}/" "${REPERTOIRE_DESTINATION}/"
    return ${?}
}

#===  FUNCTION  ================================================================
#         NAME:  moveLocalDirectory
#  DESCRIPTION:  Déplace un répertoire source vers une destination (teste l'existence)
#        USAGE:  moveLocalDirectory LocalSource LocalDestination
# PARAMETER  1:  LocalSource      : chemin source local
# PARAMETER  1:  LocalDestination : chemin destination local
#===============================================================================
moveLocalDirectory() {
    #arguments cannot be empty ==> die
    if [ -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function moveLocalDirectory"
    fi

    local source="${1}"
    local dest="${2}"
    if [[ -d "${source}" ]] ; then            \
        verbose_info "-->"${MV} "${source}" "${dest}" ;  \
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
    if [[ -z "${1}" ]]; then
        die "FATAL ERROR: Bad number of arguments in function deleteLocalDirectory"
    fi

    local dir="${1}"
    if [[ -d "${dir}" ]] ; then         \
        verbose_info "-->${RM} -rf \"${dir}\""; \
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
    if [ -f "${dir}" ] ; then         \
        verbose_info "-->${RM} \"${dir}\""; \
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
        verbose_info "-->${MV} \"${source}\" \"${dest}\"" ;
        ${MV} "${source}" "${dest}" ;
    fi
}
