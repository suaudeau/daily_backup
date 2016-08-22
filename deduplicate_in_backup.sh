#!/bin/bash

#----------------------------------------------------------------------
#  Preliminary actions
#----------------------------------------------------------------------
#Include global functions
. "$(dirname "${0}")/lib/inc_lib.sh"

readonly STAT=$(getPathAndCheckInstall stat)
readonly FIND=$(getPathAndCheckInstall find)
readonly MD5SUM=$(getPathAndCheckInstall md5sum)
readonly UNIQ=$(getPathAndCheckInstall uniq)
readonly WC=$(getPathAndCheckInstall wc)
readonly SORT=$(getPathAndCheckInstall sort)
readonly PRINTF=$(getPathAndCheckInstall printf)
readonly CUT=$(getPathAndCheckInstall cut)

readonly DB_DIR="/tmp/dedup"
readonly DEDUP_INSTRUCTIONS="/tmp/deduplicate_instructions.sh"

getInodeOfFile() {
    ${ECHO} $(${STAT} -c "%i" -- "${1}")
}
getSizeOfFile() {
    ${ECHO} $(${STAT} -c "%s" -- "${1}")
}

#===  FUNCTION  ================================================================
#         NAME:  echoWithFixedsize
#  DESCRIPTION:  Display a text with a fixed size (add spaces if necessary,
#                trucate too long texts)
#        USAGE:  echoWithFixedsize size "String_to_adjust"
#     EXAMPLES:  echoWithFixedsize 8 "This will be trucated to 8 characters"
#                echoWithFixedsize 100 "This will be completed up to 100 chars"
# PARAMETER  1:  size : Size of the desired string
# PARAMETER  2:  "String_to_adjust" : String to ajust size.
#===============================================================================
echoWithFixedsize() {
    #arguments cannot be empty ==> die
    if [ -z "${2}" -o -z "${1}" ]; then
        die "FATAL ERROR: Bad number of arguments in function areHardlinked"
    fi
    #get parameters
    size=${1}
    shift
    string=$*
    #Complete string if necessary
    to_display=$(${PRINTF} "%-${size}s" "${string}")
    #cut string if necessary
    ${ECHO} "${to_display:0:${size}}"
}

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
        local inode_file1=$(getInodeOfFile "${1}")
        local inode_file2=$(getInodeOfFile "${2}")
        #Inodes are the same?
        if [ ${inode_file1} = ${inode_file2} ] ; then            \
            return 0
        fi
    fi
    return 1
}
${ECHO} "WARNING: This script will make hard links between files that are identical"
${ECHO} "         in order to save storage in archived directories."
${ECHO} "         Please use only in backup dir where files are NEVER MODIFIED!!!"
${ECHO} "         This script may also loose rights and owners of deduplicated files."

#arguments cannot be empty ==> die
if [ -z "${1}" ]; then
    die "FATAL ERROR: Bad number of arguments in main"
fi
targetDir=${1}

#if areFilesHardlinked test/01-hl.mp3 "test/01 - Michel Berger & Luc Plamondon - Ouverture.mp3" ; then
#    echo hard
#fi
#if areFilesHardlinked IMG_3609.JPG "IMG_3609 (&)-.JPG" ; then
#    echo hard
#fi

#clean temp files
${RM} -rf ${DB_DIR} ${DEDUP_INSTRUCTIONS}
${MKDIR} -p ${DB_DIR}

#===========================================================================
# STEP 1: Build a database of files classified by their sizes
#===========================================================================
#for every file su
${FIND} "${targetDir}" | while read file; do
    # do something with $file
    if [ -f "${file}" ]; then
        #Build a database of files classified by their sizes
        ${ECHO} "${file}" >> ${DB_DIR}/$(getSizeOfFile "${file}").txt
    fi
done

#===========================================================================
# STEP 2: For each different files with the same size, build a sub-database
#         of files classified by their MD5SUM
#===========================================================================
${FIND} "${DB_DIR}" -type f | while read dbfile_size; do
    # do something with $file
    nbFile=0
    referenceMD5sum=""
    ${CAT} "${dbfile_size}" | while read file; do
        if [ ${nbFile} == 0 ]; then
            #set the first listed file as referenceFile
            referenceFile=${file}
        else
            #file compared to referenceFile
            if !(areFilesHardlinked "${referenceFile}" "${file}") ; then
                if [ "${referenceMD5sum}" == "" ]; then
                    referenceMD5sum=$(${MD5SUM} "${referenceFile}" | ${CUT} -f1 -d " ")
                    size_dir=${DB_DIR}/$(getSizeOfFile "${referenceFile}")
                    ${MKDIR} -p ${size_dir}
                    formated_inode=$(echoWithFixedsize 25 $(getInodeOfFile "${referenceFile}"))
                    ${ECHO} "${formated_inode}${referenceFile}" >> ${size_dir}/${referenceMD5sum}.txt
                fi
                fileMD5sum=$(${MD5SUM} "${file}" | ${CUT} -f1 -d " ")
                formated_inode=$(echoWithFixedsize 25 $(getInodeOfFile "${file}"))
                ${ECHO} "${formated_inode}${file}" >> ${size_dir}/${fileMD5sum}.txt
            fi
        fi
        ((nbFile++))
    done
done

#===========================================================================
# STEP 3: For each files with the same MD5SUM, make hard link between them.
#===========================================================================
${FIND} "${DB_DIR}" -type d | while read dbdir_md5sum; do
    #suppress root dir
    if [ "${dbdir_md5sum}" != "${DB_DIR}" ]; then
        #For all md5 files
        ${FIND} "${dbdir_md5sum}" -type f | while read md5file; do
            ${CAT} ${md5file} | ${SORT} | ${UNIQ} -w 25 | ${CUT} -c 26- > ${md5file}.uniq
            nbFile=0
            ${CAT} "${md5file}.uniq" | while read file; do
                if [ ${nbFile} == 0 ]; then
                    referenceFile="${file}"
                else
                    ${ECHO} rm -f \"${file}\" >> ${DEDUP_INSTRUCTIONS}
                    ${ECHO} cp -al \"${referenceFile}\" \"${file}\" >> ${DEDUP_INSTRUCTIONS}
                fi
                ((nbFile++))
            done
        done
    fi
done

cat ${DEDUP_INSTRUCTIONS}
