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

@test "inc_lib_backup.sh : get_last_timestamp" {
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


@test "inc_lib_backup.sh : copy_from_native_to_working_copy" {
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
  [ "${lines[6]%% * bytes  received *}"  = "sent" ] #sent 523 bytes  received 41 bytes  920.00 bytes/sec
  [ "${lines[7]%% is *}"  = "total size" ] #"total size is 27  speedup is 0.06"
  [ "${#lines[@]}"  = "8" ]
  [ "$(cat "${my_working_dir}/fichier crée dans native.txt")" = "changed" ]
}
