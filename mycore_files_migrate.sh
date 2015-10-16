#!/bin/bash

## PREAMBULE
# Ce script est un exemple de faisabilité pour une demande du CNRS dans le cadre du projet My CoRe. Il doit être adapté et configuré pour une utilisation en production par le prestataire, et ne doit pas être considéré comme utilisable tel quel sans expertise préalable dessus

## DESCRIPTION
# Le script permet de lancer les migrations en attente via l'application user_file_migrate.

## PREREQUIS
# Installer et activer user_files_migrate

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 13/10/2015

# chargement des variables
. ./mycore_vars.sh
# Sujet du mail
mailsubject="My CoRe - Migration de compte"

# commande exécutée
command=$0
LOCK_FILE="$tmpdir/migration.lock"
LOG_FILE="$logdir/`date +%Y%m%d`_migration.log"

#
# Functions
#
        function removeLock {
                debug=`/bin/rm ${LOCK_FILE} 2>&1`
                if [[ $? -ge "1" ]]
                then
                        # TODO Cmd fail + log
                        writeLog "FAIL removeLock : $debug"
                        exit 2
                fi

        }

#
# Check du verrou
#
        if [[ -f ${LOCK_FILE} ]]
        then
                exit
        else
                touch ${LOCK_FILE}
        fi


# CONTENU

#Initialisation du corps du message
> $temporarymailfile
echo "Lancement de la migration le `date '+%d %B %Y à %T'`." >> $temporarymailfile
sudo -u apache $ownclouddir/occ user_files_migrate:migrate >> $temporarymailfile
echo "Migration terminée le `date '+%d %B %Y à %T'`." >> $temporarymailfile
removeLock
# pied de mail
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> $temporarymailfile
mail -s "$mailsubject" -b $admins -r "$mailfrom" -Sreplyto=$expadd $mailto < $temporarymailfile

