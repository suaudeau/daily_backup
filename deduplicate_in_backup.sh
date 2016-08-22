#!/bin/bash

#----------------------------------------------------------------------
#  Preliminary actions
#----------------------------------------------------------------------
#------ Commandes utilisées par ce script ----
readonly WHICH=/usr/bin/which

die() { echo "$@" 1>&2 ; exit 1; }

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
readonly CUT=$(getPathAndCheckInstall cut)
readonly ECHO=$(getPathAndCheckInstall echo)
readonly MKDIR=$(getPathAndCheckInstall mkdir)
readonly RM=$(getPathAndCheckInstall rm)
readonly MKTEMP=$(getPathAndCheckInstall mktemp)

readonly STAT=$(getPathAndCheckInstall stat)
readonly FIND=$(getPathAndCheckInstall find)
readonly MD5SUM=$(getPathAndCheckInstall md5sum)
readonly UNIQ=$(getPathAndCheckInstall uniq)
readonly WC=$(getPathAndCheckInstall wc)
readonly SORT=$(getPathAndCheckInstall sort)
readonly PRINTF=$(getPathAndCheckInstall printf)
readonly CUT=$(getPathAndCheckInstall cut)

readonly DB_DIR=$(${MKTEMP} -d --suffix=".dedup")
readonly DEDUP_INSTRUCTIONS=$(${MKTEMP} --suffix=".deduplicate_instructions.sh")

#Simple functions:
#-----------------
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
#  DESCRIPTION:  Test if two files are hard linked
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

#===========================================================================
# STEP 1: Display warning and get parameters
#===========================================================================
${ECHO} "==========================================================================="
${ECHO} "WARNING: This script will generate a scipt to  hard links between files that are identical"
${ECHO} "         in order to save storage in archived directories."
${ECHO} "         Please use only in backup dir where files are NEVER MODIFIED!!!"
${ECHO} "         This script may also loose rights and owners of deduplicated files."
${ECHO} "==========================================================================="

#arguments cannot be empty ==> die
if [ -z "${1}" ]; then
    die "FATAL ERROR: Bad number of arguments in main"
fi
targetDir=${1}

#clean temp files
${RM} -rf ${DB_DIR} ${DEDUP_INSTRUCTIONS}
${MKDIR} -p ${DB_DIR}

#===========================================================================
# STEP 2: Build a database of files classified by their sizes
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
# STEP 3: For each different files with the same size, build a sub-database
#         of files classified by their MD5SUM
#===========================================================================
#Read each db file for files with the same size
${FIND} "${DB_DIR}" -type f | while read dbfile_size; do
    nbFile=0
    referenceMD5sum=""
    # For each same size file writen in this DB.
    ${CAT} "${dbfile_size}" | while read file; do
        if [ ${nbFile} == 0 ]; then
            #set the first listed file as referenceFile
            referenceFile=${file}
        else
            #file compared to referenceFile
            if !(areFilesHardlinked "${referenceFile}" "${file}") ; then
                if [ "${referenceMD5sum}" == "" ]; then
                    #Md5sum referenceFile if not done before
                    referenceMD5sum=$(${MD5SUM} "${referenceFile}" | ${CUT} -f1 -d " ")
                    size_dir=${DB_DIR}/$(getSizeOfFile "${referenceFile}")
                    ${MKDIR} -p ${size_dir}
                    formated_inode=$(echoWithFixedsize 25 $(getInodeOfFile "${referenceFile}"))
                    ${ECHO} "${formated_inode}${referenceFile}" >> ${size_dir}/${referenceMD5sum}.txt
                fi
                #Md5sum current file
                fileMD5sum=$(${MD5SUM} "${file}" | ${CUT} -f1 -d " ")
                formated_inode=$(echoWithFixedsize 25 $(getInodeOfFile "${file}"))
                ${ECHO} "${formated_inode}${file}" >> ${size_dir}/${fileMD5sum}.txt
            fi
        fi
        ((nbFile++))
    done
done

#===========================================================================
# STEP 4: For each files with the same MD5SUM, make hard link between them.
#===========================================================================
${FIND} "${DB_DIR}" -type d | while read dbdir_md5sum; do
    #suppress root dir
    if [ "${dbdir_md5sum}" != "${DB_DIR}" ]; then
        #For all md5 files
        ${FIND} "${dbdir_md5sum}" -type f | while read md5file; do
            #Suppress lines with the same inode and then suppress inode info
            ${CAT} ${md5file} | ${SORT} | ${UNIQ} -w 25 | ${CUT} -c 26- > ${md5file}.uniq
            nbFile=0
            #For each files identical with different inodes
            ${CAT} "${md5file}.uniq" | while read file; do
                if [ ${nbFile} == 0 ]; then
                    referenceFile="${file}"
                else
                    #Generate instructions
                    ${ECHO} rm -f \"${file}\" >> ${DEDUP_INSTRUCTIONS}
                    ${ECHO} cp -al \"${referenceFile}\" \"${file}\" >> ${DEDUP_INSTRUCTIONS}
                fi
                ((nbFile++))
            done
        done
    fi
done

#===========================================================================
# STEP 5: Display instructions
#===========================================================================
${ECHO}
${ECHO} "Here a the instructions to deduplicate:"
${ECHO} "----------------------------------------------------------"

cat ${DEDUP_INSTRUCTIONS}
${RM} -rf ${DB_DIR}
${ECHO} "----------------------------------------------------------"
${ECHO} "You can launch these instructions with following command:"
${ECHO} . ${DEDUP_INSTRUCTIONS}
