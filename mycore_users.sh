#!/bin/bash

## PREAMBULE
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION
# Script dedié à tracer les utilisateurs locaux créés. Un email sera envoyé en renseignant les comptes créés, par qui et quand.
# Il permet également de lister les comptes inactifs depuis une durée donnée et de lister les groupes vides.
# Il permet également de lister les comptes n'ayant pas le quota par défaut.
# Il permet également de lister tous les utilisateurs avec leurs groupes d'appartenance, leurs quota et leur dernière date de connexion
# Il permet également de lister les migrations en cours.
# Il permet également de lister les requêtes de restauration en cours.
# Il permet également de Supprimer les utilisateurs non connecté depuis x jours

## PREREQUIS
# mutt doit être installé
# le client mysql doit être installé
# le script doit avoir accès à la base de donnée

## VARIABLES

# Destinataires (séparer par un espace si besoin de valoriser plusieurs email)
admins="XXX"
# Adresse expediteur
expadd="XXX"
# Nom expediteur
expname="XXX"
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
# Nombre de jours d'innactivité des comptes
old_days="XXX"
# Nombre de jours au bout duquel le compte sera succeptible d'être supprimé
expiration="XXX"
# Quota par défaut
default_quota=""
# Chemin de Owncloud
ownclouddir="XXX"
# Options disponibles : grp_null,local_usr,old_usr,non_def_quota,list_usr|list_migr|list_resto|del_old_usr
command=$1
# Nom du compte apache
apache_user="XXX"

# Commande de listing des users locaux
        if [[ $command == "local_usr" ]]
        then
		# Récupération en base des utilisateurs ayant l'adresse email de renseigné et donc issu d'une création via Janus
		echo "SELECT userid FROM oc_preferences WHERE (configkey = 'email') ORDER BY  oc_preferences.userid ASC;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > usr_janus
		# Récupération de tous les utilisateurs
		echo "SELECT uid FROM oc_users WHERE 1 ORDER BY  oc_users.uid ASC;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > all_usr
		# Filtre la différence entre les 2 listes et le rajoute au corps du message
		cat all_usr usr_janus | sort | uniq -u > mail_content
		# sujet du mail
		SUBJECT="My CoRe - Liste des utilisateurs locaux"

# Commande de listing des groupes vides
        elif [[ $command == "grp_null" ]]
	then
		#liste les groupes vides
		echo "SELECT * FROM oc_groups LEFT JOIN oc_group_user ON oc_groups.gid = oc_group_user.gid WHERE oc_group_user.uid IS NULL ;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance|awk -F " "  '{print $1}' > mail_content
               	# sujet du mail
               	SUBJECT="My CoRe - Liste des groupes vides"

# Commande de listing des utilisateurs n'ayant pas le quota par défaut
        elif [[ $command == "non_def_quota" ]]
        then
                # on récupère en base les utilisateurs et leur quota personnalisé
                echo "SELECT userid, configvalue FROM  oc_preferences WHERE (configkey =  'quota');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance > mail_content
                # sujet du mail
                SUBJECT="My CoRe - Liste des comptes n'ayant pas un quota par défaut"


# Commande de listing des users non connectés depuis x jours
        elif [[ $command == "old_usr" ]]
        then
		# date de référence en timestamp
		ref_date=`date --date "$old_days days ago" +%s`
		# commande MySQL
		echo "SELECT userid FROM oc_preferences WHERE ((configvalue < $ref_date) AND (configkey =  'lastLogin'));"| mysql -h $db_host -u $db_user -p$db_passwd $instance > mail_content	
		for i in $( < mail_content)
			do
			# Envoie des mails aux utilisateurs si le compte est une adresse email
		        if [[ $i =~ "@" ]]
	                then
	                mailto=$i
			subject="My CoRe - Compte non utilisé"
			echo -e "Bonjour,\n\nVous disposez du compte "$i" sur le service My CoRe, "$service". Ce compte n'a pas été utilisé depuis "$old_days" jours.\nCe compte va être supprimé dans "$expiration" jours sans nouvelle connexion de votre part sur le service.\n\nSi besoin d'information complémentaire sur ce message, merci de contacter votre support régional de proximité : http://www.offres-de-services-unites.net/contacts.html\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme\n---------------------" | mail -s "$subject sur $service" -r "$EXP" $mailto
			fi
		done
		SUBJECT="My CoRe - Liste des utilisateurs ne s'étant pas connectés depuis $old_days jours"

# Commande de suppression des users non connectés depuis x jours
        elif [[ $command == "del_old_usr" ]]
        then
		# Entête de mail
		echo -e "Liste des comptes sur $service.\n" > mail_content
                # date de référence en timestamp
                ref_date=`date --date "$expiration days ago" +%s`
                # commande MySQL
                echo "SELECT userid FROM oc_preferences WHERE ((configvalue < $ref_date) AND (configkey =  'lastLogin'));"| mysql -h $db_host -u $db_user -p$db_passwd $instance >> mail_content
		echo -e "\n" >> mail_content
                for i in $( < mail_content)
                        do
                        # Envoie des mails aux utilisateurs si le compte est une adresse email
                        if [[ $i =~ "@" ]]
                        	then
				mailto=$i
				echo -e "Bonjour,\n\nVous disposez du compte "$i" sur le service My CoRe, "$service". Ce compte n'a pas été utilisé depuis "$expiration" jours.\nCe compte va être supprimé.\n\nSi vous avez besoin d'information complémentaire sur ce message, merci de contacter votre support régional de proximité : http://www.offres-de-services-unites.net/contacts.html\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme\n---------------------" | mail -s "$subject sur $service" -r "$expname<$expadd>" $mailto
				# Test si le compte est un compte admin
				if [[ ! -n `echo "SELECT uid FROM oc_group_user WHERE (gid = 'admin') && (uid = '$i') "| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names` ]]
                        		then
					echo "Suppression du compte $i." >> mail_content
                        		su $apache_user -s $ownclouddir/occ user:delete $i >> mail_content
					else
					echo "Le compte $i est un compte admin." >> mail_content
				fi
                        	else
				echo "Le compte $i n'étant pas une adresse email, il n'a pas été supprimé." >> mail_content
			fi
                done
                SUBJECT="My CoRe - Suppression des utilisateurs ne s'étant pas connectés depuis $expiration jours"

# Commande de listing des users
        elif [[ $command == "list_usr" ]]
        then
                #récupération du quota par défaut
                default_quota=`echo "SELECT configvalue FROM oc_appconfig WHERE configkey = 'default_quota';"| mysql -h $db_host -u $db_user -p$db_passwd $instance --skip-column-names`
		#récupère les groupes, quota et date de dernière connexion de chaque utilisateurs en bdd
                echo "SELECT uid, GROUP_CONCAT(DISTINCT gid separator '|') AS groups, IFNULL(ocp1.configvalue,'$default_quota') AS quota, FROM_UNIXTIME(ocp2.configvalue) AS lastlogin FROM oc_group_user LEFT JOIN oc_preferences ocp1 ON ocp1.userid = oc_group_user.uid AND ocp1.configkey = 'quota' AND ocp1.appid = 'files'\nLEFT JOIN oc_preferences ocp2 ON ocp2.userid = oc_group_user.uid  AND ocp2.configkey = 'lastLogin' AND ocp2.appid = 'login' GROUP BY uid"| mysql -h $db_host -u $db_user -p$db_passwd $instance | grep -v PAGER > list_usr.csv 

                # sujet du mail
                SUBJECT="My CoRe - Liste des utilisateurs"
		# Renseignement de l'expediteur
		printf "set realname=\"$expname\"\nset from=\"$expadd\"\nset use_from" > exp.txt
		# Contenu du mail
		echo -e "Bonjour,\n\nVeuillez trouver ci-joint, la liste de tous les utilisateurs.\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme\n---------------------\n" > mail_content
		# pied de mail
		echo -e "\n"$0" "$1" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> mail_content
		printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
		# Envoi du mail
		cat mail_content | mutt -s "$SUBJECT sur $service" -a list_usr.csv -F "exp.txt" -- $admins
		#logguer la date d'execution, le script et me nombre de lignes traitées
		echo $actual_date "- execution de "$0" "$1 |logger
		exit 0

# Commande de listing des migrations d'utilisateurs
        elif [[ $command == "list_migr" ]]
        then
                # sujet du mail
                SUBJECT="My CoRe - Liste des migrations en cours"
                # Renseignement de l'expediteur
                printf "set realname=\"$expname\"\nset from=\"$expadd\"\nset use_from" > exp.txt
                # Contenu du mail
                sudo -u apache $ownclouddir/occ user_files_migrate:migrate --list > mail_content
                # pied de mail
                echo -e "\n"$0" "$1" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> mail_content
		printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
                # Envoi du mail
                cat mail_content | mutt -s "$SUBJECT sur $service" -F "exp.txt" -- $admins
                #logguer la date d'execution, le script et me nombre de lignes traitées
                echo $actual_date "- execution de "$0" "$1 |logger
                exit 0

	elif [[ $command == "list_resto" ]]
        then
                # sujet du mail
                SUBJECT="My CoRe - Liste des requêtes de restauration en cours"
                # Renseignement de l'expediteur
                printf "set realname=\"$expname\"\nset from=\"$expadd\"\nset use_from" > exp.txt
                # Contenu du mail
		sudo -u apache $ownclouddir/occ user_files_restore:list > mail_content
                # pied de mail
                echo -e "\n"$0" "$1" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> mail_content
		printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
                # Envoi du mail
                cat mail_content | mutt -s "$SUBJECT sur $service" -F "exp.txt" -- $admins
                #logguer la date d'execution, le script et me nombre de lignes traitées
                echo $actual_date "- execution de "$0" "$1 |logger
                exit 0
	
	else
		# Usage
		echo "usage: "$0" grp_null|local_usr|old_usr|non_def_quota|list_usr|list_migr|list_resto|del_old_usr"
		exit 0
	fi



# pied de mail
echo -e "\n"$0" "$1" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> mail_content
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content

# envoi du mail
cat mail_content | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $admins
