#!/bin/sh

#------ Commandes utilisées par ce script ----
readonly WHICH=/usr/bin/which

#Do not change these 3 lines
readonly DIRNAME=$(${WHICH} dirname)
readonly SCRIPT_PATH=$(${DIRNAME} "${0}")
#readonly SERVICE=$(${WHICH} service)

#readonly SERVICE_CRON_RESTART="${SERVICE} cron restart"

readonly CRON_LOG_FILE=${SCRIPT_PATH}/cronlog.txt
readonly DATE_LOG_FILE=___date_of_backup___.txt
