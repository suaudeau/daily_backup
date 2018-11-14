# Script bats-code (syntaxe bash)

# Fonction lancée AVANT chaque test unitaire
setup() {
  readonly TARGET_DIR=$(mktemp -d) #création d'un dossier de destination temporaire
  cp -ar backup_dir/* "${TARGET_DIR}/"
  my_working_dir="${TARGET_DIR}/team_test_working_copy"
  my_native_dir="${TARGET_DIR}/team_test_native"
  my_backup_dir="${TARGET_DIR}/team_test_backup_copy"
  my_exclude_file="${TARGET_DIR}/exclude_file.txt"
}

# Fonction lancée APRÈS chaque test unitaire
teardown() {
  rm -rf "${TARGET_DIR}" #Effacer le dossier de destination temporaire
}

# Pour debug : pour imprimer la sortie au format de test
printlines() {
  num=0
  for line in "${lines[@]}"; do
    echo "[ \"\${lines[$num]}\"  = \"${line}\" ]"
    num=$((num + 1))
  done
}

#===  FUNCTION  ================================================================
#         NAME:  get_last_timestamp
#  DESCRIPTION:  récupère le timestamp de la dernière sauvegarde
#        USAGE:  get_last_timestamp backup_or_working_dir
# PARAMETER  1:  backup_or_working_dir : chemin du backup directory ou working directory
# RETURN VALUE:  timestamp présent dans le fichier ___date_of_backup___.txt ou ___date_of_update___.txt
#===============================================================================
get_last_timestampzzz() {
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

@test "inc_lib.sh : get_last_timestamp" {
  #Include global functions
  . "../lib/inc_lib.sh"
  . "../lib/inc_lib_backup.sh"

  run get_last_timestamp ${my_working_dir}
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "1542168167" ]
  [ "${#lines[@]}"  = "1" ]

  run get_last_timestamp ${my_backup_dir}
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "1541823241" ]
  [ "${#lines[@]}"  = "1" ]
  
  run get_last_timestamp
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
  
  run get_last_timestamp "dossier invalide"
  [ "${status}" -eq 255 ]
  [ "${#lines[@]}"  = "0" ]
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
copy_from_native_to_working_copyzzz() {
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


@test "inc_lib.sh : copy_from_native_to_working_copy" {
  #Include global functions
  . "../lib/inc_lib.sh"
  . "../lib/inc_lib_backup.sh"

  run copy_from_native_to_working_copy
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]

  [ "$(cat "${my_native_dir}/fichier crée dans native.txt")" = "original" ]
  run copy_from_native_to_working_copy "${my_native_dir}" "${my_working_dir}" "${my_exclude_file}"
  cat "${my_working_dir}/fichier crée dans native.txt"
  printlines
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "Copie des nouveaux fichiers de \"${my_native_dir}\" vers \"${my_working_dir}\"." ]
  [ "${lines[1]}"  = "sending incremental file list" ]
  [ "${lines[2]}"  = "./" ]
  [ "${lines[3]}"  = "fichier_exclu~" ]
  [ "${lines[4]}"  = "nouveau fichier crée dans native.txt" ]
  [ "${lines[5]}"  = "dossier n°1 crée dans native/" ]
  [ "${lines[6]%%  received *}"  = "sent 523 bytes" ] #sent 523 bytes  received 41 bytes  920.00 bytes/sec
  [ "${lines[7]%% is *}"  = "total size" ] #"total size is 27  speedup is 0.06"
  [ "${#lines[@]}"  = "8" ]
  [ "$(cat "${my_working_dir}/fichier crée dans native.txt")" = "changed" ]
}
