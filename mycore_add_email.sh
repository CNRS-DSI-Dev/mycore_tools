#!/bin/bash
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION
# Ce script permet de renseigner les emails des comptes locaux qui n'ont pas ce champs renseigné.

## PREREQUIS
# le client mysql doit être installé
# le script doit avoir accès à la base de donnée

## VARIABLES

# Destinataires (séparer par un espace si besoin de valoriser plusieurs email)
admins="XXX"
# Adresse expediteur
expadd="XXX"
# Nom expediteur
expname="XXX"
# Sujet du mail
SUBJECT="My CoRe - Ajout d'adresse email aux comptes locaux"
# Instance BDD
instance="XXX"
# Utilisateur BDD
db_user="XXX"
# Mot de passe BDD
db_passwd="XXX"
# Adresse du serveur BDD
db_host="XXX"
# Port du serveur BDD
db_port="XXX"
# Url du Service
service="XXX"

# Récupération en base des utilisateurs ayant l'adresse email de renseigné et donc issu d'une création via Janus
echo "SELECT userid FROM oc_preferences WHERE (configkey = 'email') ORDER BY  oc_preferences.userid ASC;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > usr_janus
# Récupération de tous les utilisateurs
echo "SELECT uid FROM oc_users WHERE 1 ORDER BY  oc_users.uid ASC;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > all_usr
# Filtre la différence entre les 2 listes et le rajoute au corps du message
cat all_usr usr_janus | sort | uniq -u > local_users
printf "Liste des comptes à renseigner :\n" > mail_content
for i in $( < local_users)
	do
	echo "INSERT INTO oc_preferences (userid, appid, configkey, configvalue) VALUES ('$i', 'settings', 'email', '$i');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
	echo "INSERT INTO oc_preferences (userid, appid, configkey, configvalue) VALUES ('$i', 'settings', 'IsLocal', '1');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
	printf "$i\n" >> mail_content
	done
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
#envoi du mail
cat mail_content | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $admins

