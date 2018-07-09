#!/bin/bash

## Version beta 0.1 - 03-2018 ##

####Script permettant de migrer un serveur Se3 de wheezy en se4-fs sous strech  ####
### Auteur : Franck Molle franck.molle@sambaedu.org

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m\c"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m"     # Gris
COLINFO="\033[0;36m\c"	# Cyan
COLPARTIE="\033[1;34m\c"	# Bleu

erreur()
{
	echo -e "$COLERREUR"
	echo "ERREUR!"
	echo -e "$1"
	echo -e "$COLTXT"
	
}

errexit()
{
	DEBIAN_PRIORITY="high"
	DEBIAN_FRONTEND="dialog" 
	export  DEBIAN_PRIORITY
	export  DEBIAN_FRONTEND
	exit 1
}

function check_whiptail()
{
if [ -z "$(which whiptail)" ];then
apt-get install whiptail -y 
fi
}


function show_title() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"

WELCOME_TITLE="Migration vers SE4-FS"

$dialog_box --backtitle "$BACKTITLE" --title "Migration vers SE4-FS" \
--menu "Bienvenue, choisissez l'action à effectuer" 15 80 7  \
"1" "Lancement de la migration du SE3 Wheezy vers SE4-FS Stretch" \
"2" "Téléchargement des paquets dans le cache uniquement" \
"3" "Sortie du programme sans mofification" \
2>$tempfile

choice=`cat $tempfile`
[ "$?" != "0" ] && exit 0
case $choice in
        1)
        ;;
        2)
        download_packages
		exit 0
        ;;
        3)
        exit 0
        ;;
        *) exit 0
        ;;
        esac
}




# Affichage de la partie actuelle
function show_part()
{
echo -e "$COLTXT"
echo -e "$COLPARTIE"
echo "--------"
echo "$1"
echo "--------"
echo -e "$COLTXT"
# sleep 1
}

function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}

# Poursuivre ou quitter en erreur
function poursuivre()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
                echo -e "$COLTXT"
                echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
                read -t 40 REPONSE
                if [ -z "$REPONSE" ]; then
                        REPONSE="o"
                fi
        done

        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
                erreur "Abandon!"
        fi
}
line_test()
{
echo -e "$COLINFO"
echo "Test de la connexion internet wget http://wawadeb.crdp.ac-caen.fr/index.html"
echo -e "$COLTXT"
if ( ! wget -q --output-document=/dev/null 'http://wawadeb.crdp.ac-caen.fr/index.html') ; then
	erreur "Votre connexion internet ou la configuration du proxy ne semble pas fonctionnelle !!" 
	exit 1
else
	echo "Connexion Ok :)"
fi
}

gensource_distrib()
{
distrib_name="$1"
echo -e "$COLINFO"
echo "Mise a jour des dépots $distrib_name"
echo -e "$COLTXT"
rm -f /etc/apt/sources.list.d/*
 
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ $distrib_name main non-free contrib

# Security Updates:
deb http://security.debian.org/ $distrib_name/updates main contrib non-free

# $distrib_name-updates
deb http://ftp.fr.debian.org/debian/ $distrib_name-updates main contrib non-free

# $distrib_name-backports
#deb http://ftp.fr.debian.org/debian/ $distrib_name-backports main
END
apt-get -q update $option_update
unset distrib_name
}

gensourcese3()
{
cat >/etc/apt/sources.list.d/se3.list <<END
#sources pour se3
deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3XP

#### Sources testing desactivee en prod ####
#deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3testing

#### Sources backports smb41  ####
deb http://wawadeb.crdp.ac-caen.fr/debian wheezybackports smb41
END
apt-get -q update
}

gensourcese3jessie()
{
cat >/etc/apt/sources.list.d/se3.list <<END
#sources pour se3
deb http://wawadeb.crdp.ac-caen.fr/debian jessie se3

#### Sources testing desactivee en prod ####
deb http://wawadeb.crdp.ac-caen.fr/debian jessie se3testing

END
apt-get -q update
}

gensourcese4()
{
cat >/etc/apt/sources.list.d/se4.list <<END
# sources pour se4
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4
# sources pour se4testing
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4testing
END
apt-get -q update
}

#date
LADATE=$(date +%d-%m-%Y)
chemin_migr="/root/migration_wheezy2stretch"
mkdir -p $chemin_migr
fichier_log="$chemin_migr/migration-$LADATE.log"
touch $fichier_log
BPC_SCRIPT="/etc/init.d/backuppc"
BPC_PID="/var/run/backuppc/BackupPC.pid"

mail_report()
{

[ -e /etc/ssmtp/ssmtp.conf ] && MAIL_ADMIN=$(cat /etc/ssmtp/ssmtp.conf | grep root | cut -d= -f2)
if [ ! -z "$MAIL_ADMIN" ]; then
    REPORT=$(cat $fichier_log)
    #On envoie un mail aÂ  l'admin
    echo "$REPORT"  | mail -s "[SE3] Rapport de migration $0" $MAIL_ADMIN
fi
}

screen_test()
{
SCREENOK=$(ps ax | grep screen | grep -v grep)

if [ -z "$SCREENOK" ]; then
    echo "Pas de session screen en cours....Il est conseille de l'utiliser lors de la migration"
    echo "Voulez vous continuez (o/N) ? "
    read REPLY
    if [ "$REPLY" != "O" ] &&  [ "$REPLY" != "o" ] && [ -n $REPLY ]; then
                    erreur "Abandon !"
                    exit 1
    fi
fi
}

show_help()
{
echo "Script de migration de Wheezy vers Stretch
A lancer sans option ou avec les options suivantes 
-d|--download : prépare la migration sans la lancer en téléchargeant uniquement les paquets nécessaires

--no-update	: ne pas vérifier la mise à  jour du script de migration sur le serveur central mais utiliser la version locale

--debug	: lance le script en outrepassant les tests de taille et de place libre des partitions. A NE PAS UTILISER EN PRODUCTION

-h|--help		: cette aide
"
}


debian_check()
{
# On teste la version de debian
 
if  ! egrep -q "^7.0" /etc/debian_version;  then
    if egrep -q "^9." /etc/debian_version; then
        echo "Votre serveur est deja en version Debian Stretch"
        echo "Vous pouvez continuer si vous souhaitez terminer une migration precedente"
        echo "Le script se positionnera automatiquement au bon endroit"
        poursuivre
    else
        echo "Votre serveur n'est pas en version Debian Wheezy."
        echo "Operation annulee !"
        exit 1
    fi
else
	DIST="wheezy"
fi
}

packages_dl() 
{
echo -e "$COLINFO"
echo "Téléchargement des paquets nécessaires à la migration"
echo -e "$COLTXT"
sleep 1
apt-get dist-upgrade -d -y --allow-unauthenticated
echo -e "$COLINFO"
echo "terminé !!"
echo -e "$COLTXT"
echo "Taille du cache actuel : $(du -sh /var/cache/apt/archives/ |  awk '{print $1}')"
touch "$chemin_migr/download_only"
}

system_check_place()
{
echo -e "$COLPARTIE"
echo "Preparation et tests du systeme" | tee -a $fichier_log
echo -e "$COLTXT"

libre_root=$(($(stat -f --format="%a*%S/1048576" /))) 
libre_var=$(($(stat -f --format="%a*%S/1048576" /var))) 

if [ "$libre_root" -lt 1500 ]; then
    echo "Espace insuffisant sur / : $libre_root Mo"
    if [ "$DEBUG" = "yes" ]; then
        echo "mode debug actif"
        poursuivre
    else
        exit 1
    fi
fi

# On teste si on a de la place pour faire la maj
PARTROOT=`df -x rootfs | grep "/\$" | sed -e "s/ .*//"`
PARTROOT_SIZE=$(fdisk -s $PARTROOT)
rm -f /root/dead.letter

if [ "$PARTROOT_SIZE" -le 3500000 ]; then
    erreur "La partition racine fait moins de 3.5Go, c'est insuffisant pour passer en Stretch" | tee -a $fichier_log
    if [ "$DEBUG" = "yes" ]; then
            echo "mode debug actif"
            poursuivre
    else
            exit 1
    fi
fi

if [ "$replica_status" == "" -o "$replica_status" == "0" ]; then
    echo "Serveur ldap en standalone ---> OK"
else
    ERREUR "Le serveur ldap soit etre en standalone (pas de replication ldap) !!!\nModifiez cette valeur et relancez le script" | tee -a $fichier_log
    exit 1
fi

[ "$DEBUG" != "yes" ] && [ ! -e "$chemin_migr/download_only" ] && apt-get clean && echo "Suppression du cache effectué"

if [ "$libre_var" -lt 1700 ];then
    echo "Espace insuffisant sur /var : $libre_var Mo"
    
    if [ "$DEBUG" = "yes" ]; then
            echo "mode debug actif"
            poursuivre
    else
            exit 1
    fi
fi
}

upgrade_se3wheezy()
{
echo "Maj si besoin de debian-archive-keyring"
apt-get install debian-archive-keyring --allow-unauthenticated
SE3_CANDIDAT=$(apt-cache policy se3 | grep "Candidat" | awk '{print $2}')
SE3_INSTALL=$(apt-cache policy se3 | grep "Install" | awk '{print $2}')
#[ "$SE3_CANDIDAT" != "$SE3_INSTALL" ] && ERREUR "Il semble que votre serveur se3 n'est pas a jour\nMettez votre serveur a jour puis relancez le script de migration" && exit 1

echo -e "$COLPARTIE"
echo "Mise a jour des paquets SE3 avant migration"
echo -e "$COLTXT"
/usr/share/se3/scripts/install_se3-module.sh se3 | grep -v "pre>" | tee -a $fichier_log
    if [ "$?" != "0" ]; then
        erreur "Une erreur s'est produite lors de la mise à  jour des modules\nIl est conseille de couper la migration"
	poursuivre
    fi
touch $chemin_migr/upgrade_se3wheezy
}

backuppc_check_mount()
{
echo -e "$COLINFO"
echo "Test de montage sur Backuppc"
echo -e "$COLTXT"
df -h | grep backuppc && umount /var/lib/backuppc
if [ ! -z "$(df -h | grep /var/lib/backuppc)" ]; then 
    erreur "Il semble qu'une ressource soit montee sur /var/lib/backuppc. Il faut la demonter puis relancer"
    exit 1
else
    [ -e $bpc_script ] && $bpc_script stop
    [ ! -h /var/lib/backuppc ] && rm -rf /var/lib/backuppc/*
fi
}

backuppc_check_run()
{
rm -f /etc/init.d/backuppc.ori 
if [ -e "$bpc_script" ]; then
    echo -e "$COLINFO"
    echo "Test bon fonctionnenment backuppc et Suppression en cas de besoin"
    echo -e "$COLTXT"
    if [ ! -e "$BPC_PID" ]; then
        $bpc_script start 
        if [ "$?" != "0" ]; then
            apt-get remove backuppc --purge -y
            rm -f /etc/apache2se/sites-enabled/backuppc.conf
        else
            $bpc_script stop
        fi
    else
        $bpc_script stop
    fi
fi
}


maj_slapd_wheezy()
{
if [ "$DIST" = "wheezy" ]; then
	echo -e "$COLINFO"
	echo "Mise à  jour slapd et consors vers leur dernière version stable"
	echo -e "$COLTXT"
	
	# modifier ldap-utils libldap-2.4-2 ??????
	
	
	apt-get install ldap-utils libldap-2.4-2 slapd -y --allow-unauthenticated
# 	aptitude install slapd -y --> aptitude sucks and can desinstall se3 !!
	# purges trace slapd backup 
	rm -rf /var/backups/slapd*
	rm -rf /var/backups/${ldap_base_dn}*
	SLAPD_VERSION=$(dpkg -s slapd | grep Version |cut -d" " -f2)
	PATHSAVLDAP="/var/backups/$SLAPD_VERSION"
	mkdir -p $PATHSAVLDAP
	ldapsearch -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw > "$PATHSAVLDAP/${ldap_base_dn}.ldif"
fi
}

prim_packages_jessie()
{
echo -e "$COLPARTIE"
echo "Migration en jessie - installations des paquets prioritaires" | tee -a $fichier_log
echo -e "$COLTXT"
poursuivre
[ -z "$LC_ALL" ] && LC_ALL=C && export LC_ALL=C 
[ -z "$LANGUAGE" ] && export LANGUAGE=fr_FR:fr:en_GB:en  
[ -z "$LANG" ] && export LANG=fr_FR@euro 
# Creation du source.list de la distrib
gensource_distrib jessie
# On se lance
if [ "$?" != "0" ]; then
    erreur "une erreur s'est produite lors de la mise a jour des paquets disponibles. reglez le probleme et relancez le script"
    gensource_distrib wheezy
    errexit
fi
apt-get install debian-archive-keyring --allow-unauthenticated | tee -a $fichier_log
apt-get -qq update 
backuppc_check_run
aptitude install libc6 locales  -y < /dev/tty | tee -a $fichier_log
if [ "$?" != "0" ]; then
    mv /etc/apt/sources.list_save_migration /etc/apt/sources.list 
    erreur "Une erreur s'est produite lors de la mise a jour des paquets lib6 et locales. Reglez le probleme et relancez le script"
    errexit
fi
echo -e "$COLINFO"
echo "mise a jour de lib6  et locales ---> OK" | tee -a $fichier_log
echo -e "$COLTXT"
sleep 3
touch $chemin_migr/prim_packages_jessie-ok

}

dist_upgrade_jessie()
{
echo -e "$COLPARTIE"
echo "Migration en Jessie - installation des paquets restants" 
echo -e "$COLTXT"
poursuivre
echo -e "$COLINFO"
echo "migration du systeme lancee.....ça risque d'être long ;)" 
echo -e "$COLTXT"
   
echo "Dpkg::Options {\"--force-confold\";}" > /etc/apt/apt.conf	
# echo "Dpkg::Options {\"--force-confnew\";}" > /etc/apt/apt.conf
gensource_distrib jessie
if [ "$?" != "0" ]; then
    erreur "Une erreur s'est produite lors de la mise a jour des paquets disponibles. Reglez le probleme et relancez le script" 
    errexit
fi
# DEBIAN_FRONTEND="non-interactive" 
apt-get dist-upgrade $option_apt  < /dev/tty | tee -a $fichier_log

if [ "$?" != "0" ]; then
	echo -e "$COLERREUR Une erreur s'est produite lors de la migration vers Jessie"
    echo "En fonction du probleme, vous pouvez choisir de poursuivre tout de meme ou bien d'abandonner afin de terminer la migration manuellement"
    #/usr/share/se3/scripts/install_se3-module.sh se3
    echo -e "$COLTXT"
    echo "Voulez vous continuez (o/N) ? "
    read REPLY
    if [ "$REPLY" != "O" ] &&  [ "$REPLY" != "o" ] && [ -n $REPLY ]; then
                    erreur "Abandon !"
                    GENSOURCESE3
                    errexit
    fi
fi
touch $chemin_migr/dist_upgrade_jessie
echo "migration du systeme OK" | tee -a $fichier_log
}

kernel_update()
{
echo -e "$COLINFO"
echo "Mise à jour du noyau linux" 
echo -e "$COLTXT"

# update noyau wheezy
arch="686"
[ "$(arch)" != "i686" ] && arch="amd64"

apt-get install linux-image-$arch firmware-linux-nonfree  -y | tee -a $fichier_log
}

slapdconfig_renew()
{
echo -e "$COLINFO"
echo "Réécriture du fichier /etc/default/slapd pour utiliser slapd.conf au lieu de cn=config" 
echo -e "$COLTXT"
# Retour Slapd.conf
service slapd stop
#sed -i "s/#SLAPD_CONF=/SLAPD_CONF=\"\/etc\/ldap\/slapd.conf\"/g" /etc/default/slapd
echo 'SLAPD_CONF="/etc/ldap/slapd.conf"
SLAPD_USER="openldap"
SLAPD_GROUP="openldap"
SLAPD_PIDFILE=
SLAPD_SERVICES="ldap:/// ldapi:///"
SLAPD_SENTINEL_FILE=/etc/ldap/noslapd
SLAPD_OPTIONS=""
' > /etc/default/slapd

# [ grep  ] || sed -i "s/SLAPD_CONF=/SLAPD_CONF=\"\/etc\/ldap\/slapd.conf\"/g" /etc/default/slapd
cp $chemin_migr/slapd.conf /etc/ldap/slapd.conf
chown openldap:openldap /etc/ldap/slapd.conf
sleep 2
service slapd start
sleep 3
}

nscd_off()
{
echo -e "$COLINFO"
echo "Arrêt de nscd - nscd sucks !" | tee -a $fichier_log
echo -e "$COLTXT"
### Modif à faire ###
# nscd sucks !
if [ -e /etc/init.d/nscd  ]; then
	insserv -r nscd
	service nscd stop
fi
}


prim_packages_stretch()
{
echo -e "$COLPARTIE"
echo "Migration en stretch - installations des paquets prioritaires" | tee -a $fichier_log
echo -e "$COLTXT"
poursuivre
[ -z "$LC_ALL" ] && LC_ALL=C && export LC_ALL=C 
[ -z "$LANGUAGE" ] && export LANGUAGE=fr_FR:fr:en_GB:en  
[ -z "$LANG" ] && export LANG=fr_FR@euro 
# Creation du source.list de la distrib
gensource_distrib stretch
# On se lance
if [ "$?" != "0" ]; then
    erreur "une erreur s'est produite lors de la mise a jour des paquets disponibles. reglez le probleme et relancez le script"
    gensource_distrib wheezy
    errexit
fi
apt-get install debian-archive-keyring --allow-unauthenticated | tee -a $fichier_log
apt-get -qq update 
aptitude install libc6 locales  -y < /dev/tty | tee -a $fichier_log
if [ "$?" != "0" ]; then
    mv /etc/apt/sources.list_save_migration /etc/apt/sources.list 
    erreur "Une erreur s'est produite lors de la mise a jour des paquets lib6 et locales. Reglez le probleme et relancez le script"
    errexit
fi
echo -e "$COLINFO"
echo "mise a jour de lib6  et locales ---> OK" | tee -a $fichier_log
echo -e "$COLTXT"
sleep 3
touch $chemin_migr/prim_packages_stretch-ok

}

dist_upgrade_stretch()
{
echo -e "$COLPARTIE"
echo "Migration en Strech - installation des paquets restants" 
echo -e "$COLTXT"
poursuivre
echo -e "$COLINFO"
echo "migration du systeme lancee.....ça risque d'être long ;)" 
echo -e "$COLTXT"
   
echo "Dpkg::Options {\"--force-confold\";}" > /etc/apt/apt.conf	
# echo "Dpkg::Options {\"--force-confnew\";}" > /etc/apt/apt.conf
gensource_distrib stretch
if [ "$?" != "0" ]; then
    erreur "Une erreur s'est produite lors de la mise a jour des paquets disponibles. Reglez le probleme et relancez le script" 
    errexit
fi
# DEBIAN_FRONTEND="non-interactive" 
apt-get dist-upgrade $option_apt  < /dev/tty | tee -a $fichier_log

if [ "$?" != "0" ]; then
	echo -e "$COLERREUR Une erreur s'est produite lors de la migration vers Jessie"
    echo "En fonction du probleme, vous pouvez choisir de poursuivre tout de meme ou bien d'abandonner afin de terminer la migration manuellement"
    #/usr/share/se3/scripts/install_se3-module.sh se3
    echo -e "$COLTXT"
    echo "Voulez vous continuez (o/N) ? "
    read REPLY
    if [ "$REPLY" != "O" ] &&  [ "$REPLY" != "o" ] && [ -n $REPLY ]; then
                    erreur "Abandon !"
                    GENSOURCESE3
                    errexit
    fi
fi
touch $chemin_migr/dist_upgrade_stretch
echo "migration du systeme OK" | tee -a $fichier_log
}

download_packages()
{
    echo -e "$COLINFO"
    echo "Pré-téléchargement des paquets uniquement"
    echo -e "$COLTXT"
    upgrade_se3wheezy
    system_check_place
    gensource_distrib jessie
    packages_dl
    gensource_distrib strech
    packages_dl
    gensource_distrib wheezy
    exit 0
}


# recup params particuliers si besoin
while :; do
	case $1 in
		-h|-\?|--help)
		show_help
		exit
		;;
      
		--no-update)
		touch /root/nodl
		;;
  
		--debug)
		touch /root/debug
		;;
  
		--)
		shift
		break
		;;
     
		-?*)
		printf 'Attention : option inconnue ignorée: %s\n' "$1" >&2
		;;
  
		*)
		break
		esac
 		shift
done

# debut du script



# Variables :
dialog_box="$(which whiptail)"

option_apt="-y"
PERMSE3_OPTION="--light"
DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY

NODL="no"
DEBUG="yes"
# option_update="-o Acquire::Check-Valid-Until=false"

bpc_script="/etc/init.d/backuppc"

tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
tempfile2=`tempfile 2>/dev/null` || tempfile=/tmp/inst2$$

#init des params
source /usr/share/se3/includes/config.inc.sh -cml
source /usr/share/se3/includes/functions.inc.sh


#########################################  

[ -e /root/debug ] && DEBUG="yes"
[ -e /root/nodl ] && NODL="yes"


if [ -e /etc/apt/listchanges.conf ]; then
	if [ "$DEBUG" = "yes" ]; then
		sed -i "s|^frontend=.*|frontend=pager|" /etc/apt/listchanges.conf
	else
		sed -i "s|^frontend=.*|frontend=mail|" /etc/apt/listchanges.conf
	fi
fi
show_title
line_test
screen_test


#Lancement de la migration Jessie

# test du system
system_check_place

if [ ! -e $chemin_migr/upgrade_se3wheezy ]; then
    gensource_distrib wheezy
    upgrade_se3wheezy
    backuppc_check_mount
    maj_slapd_wheezy
fi

if [ ! -e $chemin_migr/prim_packages_jessie ]; then
    prim_packages_jessie
fi

if [ ! -e $chemin_migr/dist_upgrade_jessie ]; then
    dist_upgrade_jessie
fi

service mysql restart


if [ ! -e $chemin_migr/prim_packages_stretch ]; then
    prim_packages_stretch
fi

if [ ! -e $chemin_migr/dist_upgrade_stretch ]; then
    dist_upgrade_stretch
fi



show_part "Nettoyage de fichiers obsolètes sur /home/profiles" | tee -a $fichier_log


# modif base sql
mysql -e "UPDATE se3db.params SET value = 'stretch' WHERE value = 'wheezy';" 
# mysql -e "UPDATE se3db.params SET value = '2.5' WHERE value = '2.4';" 


show_part "nettoyage du cache et des paquets inutiles"

apt-get autoremove -y
apt-get clean



echo -e "$COLINFO"
echo "Termine !!!"
echo -e "$COLTXT"

[ -e /etc/ssmtp/ssmtp.conf ] && MAIL_REPORT

rm -f /etc/apt/apt.conf
DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND

exit 0