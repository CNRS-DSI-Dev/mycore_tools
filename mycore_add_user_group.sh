#!/bin/bash
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION
# Ce script permet un ajout massif d'utilisateurs dans des groupes via un fichier csv en paramètre

## PREREQUIS
# le client mysql doit être installé
# le script doit avoir accès à la base de donnée


## VARIABLES

# Destinataires (séparer par un espace si besoin de valoriser plusieurs email)
#admins="mycore.moe@dsi.cnrs.fr"
admins="xxx"
# Adresse expediteur
expadd="xxx"
# Nom expediteur
expname="xxx"
# Sujet du mail
SUBJECT="xxx"
# Instance BDD
instance="xxx"
# Utilisateur BDD
db_user="xxx"
# Mot de passe BDD
db_passwd="xxx"
# Adresse du serveur BDD
db_host="xxx"
# Port du serveur BDD
db_port="xxx"
# Url du Service
service="xxx"
# Chemin de Owncloud
liste_csv="$1"

#usage
if [[ ! -n $1 ]]
	then
	echo "usage : <path>/mycore_add_user_group.sh <csv_file>"
	exit 1
fi

# Début de mail
printf "Bonjour,\n" > mail_content
echo -e "\nExécution de "$0" le "`date '+%d %B %Y'`" sur $HOSTNAME." >> mail_content
# Lit les lignes du csv et les traite une par une
while IFS=$' \t\n' read auid agid
do
	#teste si l'utilisateur existe
	if [[ -n `echo "SELECT uid FROM oc_users WHERE uid = '$auid'"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names` ]]
        	then
		#teste si le groupe existe
		if [[ -n `echo "SELECT gid FROM oc_groups WHERE gid = '$agid'"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names` ]]
			then
			#teste si l'utilisateur est déjà dans le groupe
			if [[ ! -n `echo "SELECT gid FROM oc_group_user WHERE (gid = '$agid') && (uid = '$auid') "| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names`  ]]
				then
				#insère l'utilsateur dans le groupe
				echo "INSERT INTO $instance.oc_group_user (gid, uid) VALUES ('$agid', '$auid');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
				# Précise si l'utilisateur a été ajouté ou s'il y a eu un problème.
				if [[ $? = "0" ]]
	                	then
				printf "\nAjout de $auid dans $agid." >> mail_content
				else
				printf "\nL'utilisateur $auid n'a pas pu être ajouté dans $agid." >> mail_content
				fi
				else
				#L'utilisateur était déjà dans le groupe
				printf "\nL'utilisateur $auid existe déjà dans $agid." >> mail_content
			fi
		else
		#Le groupe n'existe pas
		printf "\nLe groupe $agid n'existe pas." >> mail_content
		fi
	else
	#L'utilisateur n'existe pas
	printf "\nL'utilisateur $auid n'existe pas." >> mail_content	
	fi
done < $liste_csv
#pied de mail
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
#envoi du mail
cat mail_content | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $admins
