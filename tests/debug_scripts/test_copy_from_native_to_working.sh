currentDir=$(pwd)
cd ../../
VERBOSE_INFO=true

#Include global functions
. "$(dirname "${0}")/lib/inc_lib.sh"
. "$(dirname "${0}")/lib/inc_lib_backup.sh"

setup() {
  readonly TARGET_DIR=$(mktemp -d) #création d'un dossier de destination temporaire
  cp -ar tests/backup_dir/* "${TARGET_DIR}/"
  my_working_dir="${TARGET_DIR}/team_test_working_copy"
  my_native_dir="${TARGET_DIR}/team_test_native"
  my_backup_dir="${TARGET_DIR}/team_test_backup_copy"
  my_exclude_file="${TARGET_DIR}/exclude_file.txt"
}
# Fonction lancée APRÈS chaque test unitaire
teardown() {
  rm -rf "${TARGET_DIR}" #Effacer le dossier de destination temporaire
}

setup
echo "Test of : copy_from_native_to_working_copy $my_native_dir $my_working_dir $my_exclude_file"
if copy_from_native_to_working_copy $my_native_dir $my_working_dir $my_exclude_file; then
    echo "Succes"
else
	echo "error"
fi
teardown
cd $currentDir
