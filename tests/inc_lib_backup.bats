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
  [ "$(cat "${my_working_dir}/nouveau fichier crée dans native.txt")" = "original" ]
  printlines
  [ "${status}" -eq 0 ]
  [ "${lines[0]}"  = "Copie des nouveaux fichiers de \"${my_native_dir}\" vers \"${my_working_dir}\"." ]
  [ "${lines[1]}"  = "sending incremental file list" ]
  decalage=0
  if [ "${lines[2]}"  = "./" ]; then #Ligne optionnelle
	decalage=1
  fi
  [ "${lines[$((2+decalage))]}"  = "nouveau fichier crée dans native.txt" ]
  if [ "${lines[$((3+decalage))]}"  = "dossier n°1 crée dans native/" ]; then
	decalage=$((decalage+1))
  fi
  [ "${lines[$((3+decalage))]%% * bytes  received *}"  = "sent" ] #sent 523 bytes  received 41 bytes  920.00 bytes/sec
  [ "${lines[$((4+decalage))]%% is *}"  = "total size" ] #"total size is 27  speedup is 0.06"
  [ "${#lines[@]}"  = "$((5+decalage))" ]
  [ "$(cat "${my_working_dir}/fichier crée dans native.txt")" = "changed" ]
}

@test "inc_lib_backup.sh : getTypeOfDailyJob" {
  #Include global functions
  . "../lib/inc_lib.sh"
  . "../lib/inc_lib_backup.sh"

  #1541996041 is a monday
  run getTypeOfDailyJob ${my_backup_dir} 1541996041
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "week" ]

  #10 seconds after
  run getTypeOfDailyJob ${my_backup_dir} 1541823251
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "none" ]

  #24 hours after (in sunday)
  run getTypeOfDailyJob ${my_backup_dir} 1541909641
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "day" ]

  #3 weeks after
  run getTypeOfDailyJob ${my_backup_dir} 1543637641
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "week" ]

  #No timestamp in dir (normaly "week")
  rm ${my_backup_dir}/day-1/___date_of_backup___.txt
  run getTypeOfDailyJob ${my_backup_dir} 1543637641
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "day" ]

}


@test "inc_lib_backup.sh : getTypeOfMonthlyJob" {
  #Include global functions
  . "../lib/inc_lib.sh"
  . "../lib/inc_lib_backup.sh"

  #(sam. 10 nov. 2018 05:14:01) + 3 weeks
  run getTypeOfMonthlyJob ${my_backup_dir} 1543637641
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "month" ]

  #(sam. 10 nov. 2018 05:14:01) + 2 weeks
  run getTypeOfMonthlyJob ${my_backup_dir} 1543032841
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "none" ]

  #(2019-01-01_+05:14:01)
  run getTypeOfMonthlyJob ${my_backup_dir} 1546316041
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "year" ]

  #(sam. 10 nov. 2018 05:14:01) + 365 days
  run getTypeOfMonthlyJob ${my_backup_dir} 1573359241
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "none" ]

  #(sam. 10 nov. 2018 05:14:01) + 366 days
  run getTypeOfMonthlyJob ${my_backup_dir} 1573445641
  printlines
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}"  = "1" ]
  [ "${lines[0]}"  = "year" ]
}
