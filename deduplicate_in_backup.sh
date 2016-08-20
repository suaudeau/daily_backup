#!/bin/bash

#----------------------------------------------------------------------
#  Actions préparatoires
#----------------------------------------------------------------------
#Include global functions
. "$(dirname "${0}")/lib/inc_lib.sh"

readonly STAT=$(getPathAndCheckInstall stat)
readonly FIND=$(getPathAndCheckInstall find)

readonly DB_DIR="/tmp/dedup"

#===  FUNCTION  ================================================================
#         NAME:  areFilesHardlinked
#  DESCRIPTION:  Teste si deux fichiers sont liés par des liens durs (hard link)
#        USAGE:  areFilesHardlinked "File1" "File2"
#      EXAMPLE:  if areFilesHardlinked "File1" "File2" ; then
#                   Action si OK
#                fi
# PARAMETER  1:  File1 : Fichier 1
# PARAMETER  2:  File2 : Fichier 2
#===============================================================================
areFilesHardlinked() {
    #arguments cannot be empty ==> die
    if [ -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function areHardlinked"
    fi

    #Are both true files?
    if [ -f "${1}" -a -f  "${2}" ] ; then
        local inode_file1=$(${STAT} -c "%i" -- "${1}")
        local inode_file2=$(${STAT} -c "%i" -- "${2}")
        #Inodes are the same?
        if [ ${inode_file1} = ${inode_file2} ] ; then            \
            return 0
        fi
    fi
    return 1
}
echo "WARNING: This script may loose rights and owners of deduplicated files"

#arguments cannot be empty ==> die
if [ -z "${1}" ]; then
    die "FATAL ERROR: Bad number of arguments in main"
fi
targetDir=${1}

if areFilesHardlinked test/01-hl.mp3 "test/01 - Michel Berger & Luc Plamondon - Ouverture.mp3" ; then
    echo hard
fi

${RM} -rf ${DB_DIR}
${MKDIR} -p ${DB_DIR}

#for every file su
${FIND} "${targetDir}" | while read file; do
    # do something with $file
    if [ -f "${file}" ]; then
        #Build a database of files classified by their sizes
        echo ${file} >> ${DB_DIR}/$(${STAT} -c "%s" -- "${file}").txt
        #echo "$(${STAT} -c "%s" -- "${file}") [${file}]"
    fi
done

#for file in $(${FIND} "${targetDir}"); do
#    echo "[$file]"
#done
