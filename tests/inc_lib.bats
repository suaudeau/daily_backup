# Script bats-code (syntaxe bash)

# Fonction lancée AVANT chaque test unitaire
setup() {
  readonly TARGET_DIR=$(mktemp -d) #création d'un dossier de destination temporaire
  mkdir "${TARGET_DIR}/nom aux carractères spéciaux"
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

@test "inc_lib.sh : isDirectory" {
  #Include global functions
  . "../lib/inc_lib.sh"
  
  run isDirectory herve@gargas:ufr/
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
}

@test "inc_lib.sh : getPathAndCheckInstall" {
  #Include global functions
  . "../lib/inc_lib.sh"

  run getPathAndCheckInstall bash
  printlines
  [ "${lines[0]}"  = "/bin/bash" ]
  [ "${#lines[@]}"  = "1" ]

}

@test "inc_lib.sh : getPathAndCheckInstall2" {
  #Include global functions
  . "../lib/inc_lib.sh"

  run getPathAndCheckInstall
  printlines
  [ "${status}" -eq 0 ] # Pas d'erreur
  [ "${lines[0]}"  = "FATAL ERROR: Use function getPathAndCheckInstall with an argument" ]
  [ "${#lines[@]}"  = "1" ] 

}

@test "inc_lib.sh : getPathAndCheckInstall3" {
  #Include global functions
  . "../lib/inc_lib.sh"

  run getPathAndCheckInstall programme_non_installe
  printlines
  [ "${lines[0]}"  = "FATAL ERROR: programme_non_installe is not installed" ]
  [ "${#lines[@]}"  = "1" ] 
}
