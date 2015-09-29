#!/bin/bash
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION
# Ce script permet de rendre des utilisateurs admin de groupe à travers un fichier csv en paramètre. 

## PREREQUIS
# le client mysql doit être installé
# le script doit avoir accès à la base de donnée

# Le format du fichier csv doit être du type :
# user1 group1
# user1 group2
# user2 group3
# ...


## VARIABLES

# Destinataires (séparer par un espace si besoin de valoriser plusieurs email)
admins="XXX"
# Adresse expediteur
expadd="XXX"
# Nom expediteur
expname="XXX"
# Sujet du mail
SUBJECT="My CoRe - Ajout massif d'admins de groupe"
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
liste_csv="$1"

#usage
if [[ ! -n $1 ]]
	then
	echo "usage : <path>/mycore_add_admin_group.sh <csv_file>"
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
			#teste si l'utilisateur est déjà admin du groupe
			if [[ ! -n `echo "SELECT gid FROM oc_group_admin WHERE (gid = '$agid') && (uid = '$auid') "| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names`  ]]
				then
				#teste si l'utilisateur est dans le groupe
				if [[ ! -n `echo "SELECT gid FROM oc_group_user WHERE (gid = '$agid') && (uid = '$auid') "| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names`  ]]
					then
					#ajout de l'utilisateur dans le groupe
					echo "INSERT INTO $instance.oc_group_user (gid, uid) VALUES ('$agid', '$auid');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
				fi
				#Met l'utilsateur en tant qu'admin du groupe
				echo "INSERT INTO $instance.oc_group_admin (gid, uid) VALUES ('$agid', '$auid');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
				# Précise si l'utilisateur a été ajouté ou s'il y a eu un problème.
				if [[ $? = "0" ]]
	                	then
				printf "\nAjout de $auid admin de $agid." >> mail_content
				else
				printf "\nL'utilisateur $auid n'a pas pu être ajouté en tant qu'admin de $agid." >> mail_content
				fi
				else
				#L'utilisateur était déjà dans le groupe
				printf "\nL'utilisateur $auid est déjà admin de $agid." >> mail_content
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
