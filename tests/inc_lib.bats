# Script bats-code (syntaxe bash)

# Fonction lancée AVANT chaque test unitaire
setup() {
  readonly TARGET_DIR=$(mktemp -d) #création d'un dossier de destination temporaire
  mkdir "${TARGET_DIR}/nom aux carractères spéciaux"
  
  REMOTE_TEST_USER="herve"
  REMOTE_TEST_SERVER="gargas"
  REMOTE_TEST_EXISTING_DIR="ufr/"
  REMOTE_TEST_WORKING_DIR="./"
  REMOTE_TEST_URI_EXISTING_DIR="${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER}:${REMOTE_TEST_EXISTING_DIR}"
  REMOTE_TEST_URI_WORKING_DIR="${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER}:${REMOTE_TEST_WORKING_DIR}"
}

# Fonction lancée APRÈS chaque test unitaire
teardown() {
  rm -rf "${TARGET_DIR}" #Effacer le dossier de destination temporaire
  ssh ${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER} rm -rf "${REMOTE_TEST_WORKING_DIR}/tmp.test"
  ssh ${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER} rm -rf "${REMOTE_TEST_WORKING_DIR}/tmp.test3"
}

# Pour debug : pour imprimer la sortie au format de test
printlines() {
  num=0
  for line in "${lines[@]}"; do
    echo "[ \"\${lines[$num]}\"  = \"${line}\" ]"
    num=$((num + 1))
  done
}

@test "inc_lib.sh : getPathAndCheckInstall" {
  #Include global functions
  . "../lib/inc_lib.sh"

  run getPathAndCheckInstall bash
  printlines
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "/bin/bash" ]
  [ "${#lines[@]}"  = "1" ]

  # BUG: Ne fonctionnent pas:
  
  #run getPathAndCheckInstall programme_non_installe
  #printlines
  #[ "${lines[0]}"  = "FATAL ERROR: programme_non_installe is not installed" ]
  #[ "${#lines[@]}"  = "1" ] 
  
  #run getPathAndCheckInstall
  #printlines
  #[ "${status}" -eq 0 ] # Pas d'erreur
  #[ "${lines[0]}"  = "FATAL ERROR: Use function getPathAndCheckInstall with an argument" ]
  #[ "${#lines[@]}"  = "1" ] 
}

@test "inc_lib.sh : verbose_info" {
  #Include global functions
  . "../lib/inc_lib.sh"

  run verbose_info "VERBOSE_INFO non défini"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]

  VERBOSE_INFO="true"
  run verbose_info "VERBOSE_INFO true"
  printlines
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "VERBOSE_INFO true" ]
  [ "${#lines[@]}"  = "1" ]

  VERBOSE_INFO="false"
  run verbose_info "VERBOSE_INFO false"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]

  VERBOSE_INFO="other"
  run verbose_info "VERBOSE_INFO other"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
}


@test "inc_lib.sh : isDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  run isDirectory "${REMOTE_TEST_URI_EXISTING_DIR}"
  printlines
  # Pas d'erreur de retour : la valeur de "exit" est 0 
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  
  run isDirectory herve@gargas:repertoire_inexistant/
  printlines && echo ${status}
  [ "${status}" -eq 1 ] #erreur
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  
  run isDirectory "${TARGET_DIR}"
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran

  run isDirectory "${TARGET_DIR}/fichier_inexistant"
  [ "${status}" -eq 1 ] #erreur
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  
  run isDirectory "${TARGET_DIR}/nom aux carractères spéciaux"
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran

  run isDirectory "${TARGET_DIR}/nom aux carractères spéciaux inexistant"
  [ "${status}" -eq 1 ] #erreur
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  
#BUG
  #run isDirectory 
  #printlines && echo ${status}
  #[ "${status}" -eq 1 ] #erreur
  #[ "${lines[0]}"  = "FATAL ERROR: Bad number of arguments in function isDirectory" ]
  #[ "${#lines[@]}"  = "1" ] 

}

@test "inc_lib.sh : createDirectory remote" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  testdir="${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER}:${REMOTE_TEST_WORKING_DIR}/tmp.test"
  #test préalable
  run isDirectory "${testdir}"
  [ "${status}" -eq 1 ] #erreur
  #test
  run createDirectory "${testdir}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  #test ultérieur
  run isDirectory "${testdir}"
  [ "${status}" -eq 0 ] 
}

@test "inc_lib.sh : createDirectory local" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  testdir="${TARGET_DIR}/tmp.test/tmp.test"
  #test préalable
  run isDirectory "${testdir}"
  [ "${status}" -eq 1 ] #erreur
  #test
  run createDirectory "${testdir}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  #test ultérieur
  run isDirectory "${testdir}"
  [ "${status}" -eq 0 ] 
  
  #Si le repertoire existe déjà
  run createDirectory "${testdir}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran

  #Si le repertoire est impossible à créer
  run createDirectory "/proc/cpu/dossierdebile/dossier"
  echo "--------------${#lines[@]}---"
  printlines
  [ "${status}" -eq 1 ] #erreur
  [ "${lines[0]}"  = "/bin/mkdir: impossible de créer le répertoire «/proc/cpu»: Aucun fichier ou dossier de ce type" ]
  [ "${#lines[@]}"  = "1" ] 
}

#@test "inc_lib.sh : createDirectory bad number of arguments" {

#BUG
  #Include global functions
  #. "../lib/inc_lib.sh"
  
  #run createDirectory
  #printlines && echo ${status}
  #[ "${status}" -eq 1 ] #erreur
  #[ "${lines[0]}"  = "FATAL ERROR: Bad number of arguments in function createDirectory" ]
  #[ "${#lines[@]}"  = "1" ] 
# }

@test "inc_lib.sh : updateDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  testdir="${TARGET_DIR}/tmp.test/tmp.test"
  testdir2="${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER}:${REMOTE_TEST_WORKING_DIR}/tmp.test"
  testdir3="${REMOTE_TEST_USER}@${REMOTE_TEST_SERVER}:${REMOTE_TEST_WORKING_DIR}/tmp.test3"

  #test préalable
  run createDirectory "${testdir}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  #preparation
  run createDirectory "${testdir2}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  run createDirectory "${testdir3}"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ] #rien n'est écrit sur l'écran
  touch "${TARGET_DIR}/tmp.test/tmp.test/Mon fichier test"
  mkdir "${TARGET_DIR}/tmp.test/tmp.test/Mon dossier test"

  #Premier test
  run updateDirectory "${testdir}" "${testdir2}" /dev/null
  printlines
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "sending incremental file list" ]
  decalage=0
  if [ "${lines[1]}"  = "./" ]; then #Ligne optionnelle
    decalage=1
  fi
  [ "${lines[$((1+decalage))]}"  = "Mon fichier test" ]
  [ "${lines[$((2+decalage))]}"  = "Mon dossier test/" ]
  [ "${lines[$((3+decalage))]%% * bytes  received *}"  = "sent" ] #sent 49 bytes  received 11 bytes  120.00 bytes/sec
  [ "${lines[$((4+decalage))]}"  = "total size is 0  speedup is 0.00" ]
  [ "${#lines[@]}"  = "$((5+decalage))" ]
  #test ultérieur
  run isDirectory "${testdir2}/Mon dossier test"
  [ "${status}" -eq 0 ] 

  #Second test
  echo "------- Second test -------"
  run updateDirectory "${testdir2}" "${testdir3}" /dev/null
  printlines
 [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "sending incremental file list" ]
  decalage=0
  if [ "${lines[1]}"  = "./" ]; then #Ligne optionnelle
    decalage=1
  fi
  [ "${lines[$((1+decalage))]}"  = "Mon fichier test" ]
  [ "${lines[$((2+decalage))]}"  = "Mon dossier test/" ]
  [ "${lines[$((3+decalage))]%% * bytes  received *}"  = "sent" ] #sent 49 bytes  received 11 bytes  120.00 bytes/sec
  [ "${lines[$((4+decalage))]}"  = "total size is 0  speedup is 0.00" ]
  [ "${#lines[@]}"  = "$((5+decalage))" ]
  #test ultérieur
  run isDirectory "${testdir3}/Mon dossier test"
  [ "${status}" -eq 0 ]
}

@test "inc_lib.sh : moveLocalDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  run moveLocalDirectory "${TARGET_DIR}" "/tmp/nouveau dossier"
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
  #test ultérieur
  [ ! -d "${TARGET_DIR}" ]
  [ -d "/tmp/nouveau dossier" ]
  [ -d "/tmp/nouveau dossier" ]
}

@test "inc_lib.sh : deleteLocalDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  run deleteLocalDirectory "${TARGET_DIR}" 
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
  #test ultérieur
  [ ! -d "${TARGET_DIR}" ]
  run deleteLocalDirectory "/tmp/dossier inexistant" 
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
}

@test "inc_lib.sh : deleteLocalFile" {
  #Include global functions
  . "../lib/inc_lib.sh"
 
  touch "${TARGET_DIR}/mon fichier" 
  [ -f "${TARGET_DIR}/mon fichier" ]
  run deleteLocalFile "${TARGET_DIR}/mon fichier" 
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
  [ ! -f "${TARGET_DIR}/mon fichier" ]
}

@test "inc_lib.sh : replaceLocalDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
 
  mkdir "${TARGET_DIR}/dossier remplaçant" 
  mkdir "${TARGET_DIR}/dossier remplacé" 
  touch "${TARGET_DIR}/dossier remplacé/mon fichier" 
  [ -d "${TARGET_DIR}/dossier remplaçant"  ]
  [ -f "${TARGET_DIR}/dossier remplacé/mon fichier" ]
  run replaceLocalDirectory "${TARGET_DIR}/dossier remplaçant" "${TARGET_DIR}/dossier remplacé" 
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "0" ]
  [ ! -f "${TARGET_DIR}/dossier remplacé/mon fichier" ]
}
