#!/bin/bash
#génère un script de transfert d'un dossier backup_copy


set -euo pipefail
OLD_BACKUP_DIR="/home-old/user/backup_portable/backup_copy"
NEW_BACKUP_DIR="/home/user/backup_portable/backup_copy"
DIRLIST="day-1 day-2 day-3 day-4 day-5 day-6 week-1 week-2 week-3 week-4 month-01 month-02 month-03 month-04 month-05 month-06 month-07 month-08 month-09 month-10 month-11 year-01 year-02 year-03 year-04"

echo "#!/bin/bash" > script.sh
((count=1)) || true
for dir in ${DIRLIST}; do
    if (( count > 1 )); then
        echo "cp -al ${NEW_BACKUP_DIR}/${former_dir}/ ${NEW_BACKUP_DIR}/${dir}/" >> script.sh
        echo "rsync -av --delete --force --delete-excluded ${OLD_BACKUP_DIR}/${dir}/ ${NEW_BACKUP_DIR}/${dir}/" >> script.sh
    else
        echo "rsync -av --delete --force --delete-excluded ${OLD_BACKUP_DIR}/${dir}/ ${NEW_BACKUP_DIR}/${dir}" >> script.sh
    fi
    ((count++)) || true
    former_dir=$dir
done