#!/bin/bash

## Version beta 0.2 - 12-2018 ##

####Script permettant de migrer un serveur Se3 de wheezy en se4-fs sous stretch  ####
### Auteur : Franck Molle franck.molle@sambaedu.org

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m\c"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m\c"     # Gris
COLINFO="\033[0;36m\c"	# Cyan
COLPARTIE="\033[1;34m\c"	# Bleu


function show_title() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"

WELCOME_TITLE="Migration vers SE4-FS"
WELCOME_TEXT="Bienvenue dans le script de migration SAMBAEDU 4.

Ce programme va migrer votre serveur actuel SE3 Wheezy vers SE4FS sous Debian Stretch.

Attention : Vous devez disposer d'un SE4-AD en container ou machine virtuelle qui sera utilisé par SE4-FS"

$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 18 75
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

# Affichage de la partie actuelle
function show_info()
{
echo -e "$COLTXT"
echo -e "$COLINFO"
echo "$1"
echo -e "$COLTXT"
# sleep 1
}

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

function quit_on_choice()
{
echo -e "$COLERREUR"
echo "Arrêt du script !"
echo -e "$1"
echo -e "$COLTXT"
exit 1
}

function cp_ssh_key() {
mkdir -p /root/.ssh/

if [ -e "$dir_config/authorized_keys" ]; then
    mv  "$dir_config/authorized_keys" /root/.ssh/ 
fi

if [ -n "$devel" ]; then
    
    ssh_keyser="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMQ6Nd0Kg+L8200pR2CxUVHBtmjQ2xAX2zqArqV45horU8qopf6AYEew0oKanK3GzY2nrs5g2SYbxqs656YKa/OkTslSc5MR/Nndm9/J1CUsurTlo+VwXJ/x1qoLBmGc/9mZjdlNVKIPwkuHMKUch+XmsWF92GYEpTA1D5ZmfuTxP0GMTpjbuPhas96q+omSubzfzpH7gLUX/afRHfpyOcYWdzNID+xdmML/a3DMtuCatsHKO94Pv4mxpPeAXpJdE262DPXPz2ZIoWSqPz8dQ6C3v7/YW1lImUdOah1Fwwei4jMK338ymo6huR/DheCMa6DEWd/OZK4FW2KccxjXvHALn/QCHWCw0UMQnSVpmFZyV4MqB6YvvQ6u0h9xxWIvloX+sjlFCn71hLgH7tYsj4iBqoStN9KrpKC9ZMYreDezCngnJ87FzAr/nVREAYOEmtfLN37Xww3Vr8mZ8/bBhU1rqfLIaDVKGAfnbFdN6lOJpt2AX07F4vLsF0CpPl4QsVaow44UV0JKSdYXu2okcM80pnVnVmzZEoYOReltW53r1bIZmDvbxBa/CbNzGKwxZgaMSjH63yX1SUBnUmtPDQthA7fK8xhQ1rLUpkUJWDpgLdC2zv2jsKlHf5fJirSnCtuvq6ux1QTXs+bkTz5bbMmsWt9McJMgQzWJNf63o8jw== GitLab"
    grep -q "$ssh_keyser" /root/.ssh/authorized_keys || echo $ssh_keyser >> /root/.ssh/authorized_keys 
fi
}

# Fonction permettant de poser la question s'il faut poursuivre ou quitter
function go_on()
{
REPONSE=""
while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
do
    echo -e "$COLTXT"
    echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXL}) $COLSAISIE"
    read -t 40 REPONSE
#     echo -e "$COLTXT"
    if [ -z "$REPONSE" ]; then
            REPONSE="o"
    fi
done

if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
        quit_on_choice "Abandon!"
fi
}


function check_whiptail()
{
if [ -z "$(which whiptail)" ];then
apt-get install whiptail -y 
fi
}

function check_arch() {
if [ "$(arch)" != "x86_64" ] ;then
NEWT_COLORS='                                                                                                                         
 window=,red
 border=white,red
 textbox=white,red
 button=black,white' whiptail --backtitle "$(arch) non pris en charge" --title "$se4fs_partman_title" --msgbox "Erreur : Seule l'Architecture AMD64 est supportée par SambaEdu 4" 13 70
    exit 1
fi
}



function show_menu() {
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

function mirror_choice() {
mirror_name_title="Miroir Debian à utiliser pour l'installation"
	$dialog_box --backtitle "$BACKTITLE" --title "$mirror_name_title" --inputbox "Confirmer le nom du miroir à utiliser ou bien saisir l'adresse de votre miroir local si vous en avez un" 15 70 deb.debian.org 2>$tempfile || erreur "Annulation"
	mirror_name=$(cat $tempfile)
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

# Fonction de verification d'erreur
function check_error()
{
if [ "$?" != "0" ]; then
    echo -e "$COLERREUR"
    echo "Attention "
    echo -e "la dernière commande a envoyé une erreur !"
    echo -e "$1"
    echo -e "$COLTXT"
    go_on
fi
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

function gensource_wheezy()
{
show_info "Mise à jour des sources Wheezy"
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ wheezy main non-free contrib

# Security Updates:
deb http://security.debian.org/ wheezy/updates main contrib non-free

# wheezy-updates
deb http://ftp.fr.debian.org/debian/ wheezy-updates main contrib non-free
END
apt-get -q update $option_update
}


function gensource_distrib()
{
distrib_name="$1"
show_info "Mise à jour des sources $distrib_name"
rm -f /etc/apt/sources.list.d/*
if [ "$distrib_name" = "jessie" ];then
    mirror_name="deb.debian.org"
fi
  
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://$mirror_name/debian $distrib_name main non-free contrib

# Security Updates:
deb http://security.debian.org/debian-security $distrib_name/updates main contrib non-free

# $distrib_name-updates
deb http://ftp.fr.debian.org/debian/ $distrib_name-updates main contrib non-free

# $distrib_name-backports
#deb http://ftp.fr.debian.org/debian/ $distrib_name-backports main
END
apt-get -q update $option_update
unset distrib_name
}

function gensourcese3()
{
show_info "Mise à jour des sources SE3 Wheezy"
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

function gensourcese3jessie()
{
show_info "Mise à jour des sources SE3 Jessie"
cat >/etc/apt/sources.list.d/se3.list <<END
#sources pour se3
deb http://wawadeb.crdp.ac-caen.fr/debian jessie se3

#### Sources testing desactivee en prod ####
deb http://wawadeb.crdp.ac-caen.fr/debian jessie se3testing

END
apt-get -q update
}

function gensourcese4()
{
show_info "Mise à jour des sources SE4 Stretch"
cat >/etc/apt/sources.list.d/se4.list <<END
# sources pour se4
# temporairement on est sur SE4XP
#deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4

#### Sources testing seront desactivees en prod ####
#deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4testing

deb [trusted=yes] http://wawadeb.crdp.ac-caen.fr/debian stretch se4XP 
END
apt-get -q update
}

function mail_report()
{

[ -e /etc/ssmtp/ssmtp.conf ] && MAIL_ADMIN=$(cat /etc/ssmtp/ssmtp.conf | grep root | cut -d= -f2)
if [ ! -z "$MAIL_ADMIN" ]; then
    REPORT=$(cat $fichier_log)
    #On envoie un mail aÂ  l'admin
    echo "$REPORT"  | mail -s "[SE3] Rapport de migration $0" $MAIL_ADMIN
fi
}

function screen_test()
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

function show_help()
{
echo "Script de migration de Wheezy vers Stretch
A lancer sans option ou avec les options suivantes 
-d|--download : prépare la migration sans la lancer en téléchargeant uniquement les paquets nécessaires

--no-update	: ne pas vérifier la mise à  jour du script de migration sur le serveur central mais utiliser la version locale

--debug	: lance le script en outrepassant les tests de taille et de place libre des partitions. A NE PAS UTILISER EN PRODUCTION

-h|--help		: cette aide
"
}


function debian_check()
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

function packages_dl() 
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

function system_check()
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
    echo "replication ldap .... Le serveur sera placé en standalone pour la migration"
#     ERREUR "Le serveur ldap soit etre en standalone (pas de replication ldap) !!!\nModifiez cette valeur et relancez le script" | tee -a $fichier_log
    CHANGEMYSQL replica_ip ""
    CHANGEMYSQL replica_status "0"
    CHANGEMYSQL ldap_server "$se3ip"

	echo "Annuaire replace en mode annuaire local"
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

function upgrade_se3_packages()
{
local distrib="$1"
echo "Maj si besoin de debian-archive-keyring"
apt-get install debian-archive-keyring --allow-unauthenticated
SE3_CANDIDAT=$(apt-cache policy se3 | grep "Candidat" | awk '{print $2}')
SE3_INSTALL=$(apt-cache policy se3 | grep "Install" | awk '{print $2}')
#[ "$SE3_CANDIDAT" != "$SE3_INSTALL" ] && ERREUR "Il semble que votre serveur se3 n'est pas a jour\nMettez votre serveur a jour puis relancez le script de migration" && exit 1

show_part "Mise a jour des paquets SE3 $distrib"

if [ "$distrib" = "wheezy" ]; then
    /usr/share/se3/scripts/install_se3-module.sh se3 | grep -v "pre>" | tee -a $fichier_log
else
    apt-get install se3 -y
    if [ "$?" != "0" ]; then
        erreur "Une erreur s'est produite lors de la mise à jour des paquets Se3\nIl est conseille de couper la migration"
	poursuivre
    fi
fi
touch $chemin_migr/upgrade_se3${distrib}
}

function backuppc_check_mount()
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

function backuppc_check_run()
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


function maj_slapd_wheezy()
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



# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif
function export_ldap_files()
{
echo -e "$COLINFO"
echo "Ajout du mapping de groupe sur Le groupe Administratifs avant export"
echo -e "$COLCMD"
net groupmap add ntgroup=Administratifs unixgroup=Administratifs type=domain comment="Administratifs du domaine"
echo -e "$COLTXT"

conf_slapd="/etc/ldap/slapd.conf"
echo -e "$COLINFO"
echo "Export de la conf ldap et de ldapse3.ldif vers $dir_export"
echo -e "$COLTXT"
cp $conf_slapd $dir_export/
ldapsearch -xLLL -D "$adminRdn,$ldap_base_dn" -w $adminPw > $dir_export/ldapse3.ldif
schema_dir="/etc/ldap/schema"
cp $schema_dir/ltsp.schema $schema_dir/samba.schema $schema_dir/printer.schema $dir_export/
cp /var/lib/ldap/DB_CONFIG $dir_export/
cp /etc/ldap/slapd.pem $dir_export/
}

function import_ldap_files()
{
/usr/share/se3/scripts/mkSlapdConf.sh
/etc/init.d/slapd stop
sleep 1
rm -f /var/lib/ldap/* 
# cp $dir_export/DB_CONFIG  /var/lib/ldap/
cat > /var/lib/ldap/DB_CONFIG <<END
set_cachesize 	0	41943040	0
set_flags       DB_TXN_NOSYNC
set_lg_bsize	524288
set_lk_max_objects      10000
set_lk_max_locks        10000
set_lk_max_lockers      10000
set_flags DB_LOG_AUTOREMOVE
END
slapadd -l $dir_export/ldapse3.ldif
check_error
chown -R openldap:openldap /var/lib/ldap/
chown -R openldap:openldap /etc/ldap

echo -e "$COLINFO"
echo "Lancement de slapd" 
echo -e "$COLCMD"
/etc/init.d/slapd start
sleep 1
}

function prim_packages_jessie()
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

function dist_upgrade_jessie()
{
show_part "Migration en Jessie - installation des paquets restants" 
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

function kernel_update()
{
echo -e "$COLINFO"
echo "Mise à jour du noyau linux" 
echo -e "$COLTXT"

# update noyau wheezy
arch="686"
[ "$(arch)" != "i686" ] && arch="amd64"

apt-get install linux-image-$arch firmware-linux-nonfree  -y | tee -a $fichier_log
}

function slapdconfig_renew()
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

function clean_pre_jessie(){ 
echo -e "$COLINFO"
echo "Nettoyage des scripts se3 et des paquets inutiles" | tee -a $fichier_log
echo -e "$COLTXT"
apt-get remove apt-listchanges --purge -y
apt-get remove wine wine32 libc6:i386 slapd samba samba-common mysql-server-5.5 ntpdate backuppc nut nut-client nut-server --purge -y
apt-get autoremove --purge -y
rm -f /etc/samba/smb.conf
rm -rf /usr/share/se3/sbin /usr/share/se3/scripts /usr/share/se3/scripts-alertes/ /usr/share/se3/shares/ /usr/share/se3/data/
touch $chemin_migr/clean_pre_jessie
}

function prim_packages_stretch()
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

function dist_upgrade_stretch()
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

function download_packages()
{
    echo -e "$COLINFO"
    echo "Pré-téléchargement des paquets uniquement"
    echo -e "$COLTXT"
    mirror_choice
    upgrade_se3_packages wheezy
    system_check
    gensource_distrib jessie
    packages_dl
    gensource_distrib stretch
    packages_dl
    gensource_wheezy
    exit 0
}

function clean_post_stretch {
show_part "nettoyage du cache et des paquets inutiles"
apt-get autoremove -y --purge
apt-get clean

rm -f /etc/apt/apt.conf
DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND
}

function install_se4 {
show_part "Installation des paquets SambaEdu 4 FS"
apt-get install sambaedu -y
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
devel="yes"
# option_update="-o Acquire::Check-Valid-Until=false"


#date
LADATE=$(date +%d-%m-%Y)
chemin_migr="/root/migration_wheezy2stretch"
mkdir -p $chemin_migr
fichier_log="$chemin_migr/migration-$LADATE.log"
touch $fichier_log
BPC_PID="/var/run/backuppc/BackupPC.pid"
bpc_script="/etc/init.d/backuppc"
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
tempfile2=`tempfile 2>/dev/null` || tempfile=/tmp/inst2$$
dir_config="/etc/sambaedu"
dir_export="/etc/sambaedu/export_se4ad"
mkdir -p "$dir_export"

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
check_whiptail
check_arch
show_menu
line_test
screen_test
mirror_choice
cp_ssh_key
#Lancement de la migration Jessie

# test du system
system_check

if [ ! -e $chemin_migr/upgrade_se3wheezy ]; then
    gensource_wheezy
    upgrade_se3_packages wheezy
    backuppc_check_mount
    maj_slapd_wheezy
fi


if [ ! -e $chemin_migr/clean_pre_jessie ]; then
    export_ldap_files
    import_ldap_files
    gensourcese3jessie
    upgrade_se3_packages jessie
    clean_pre_jessie
    
fi

if [ ! -e $chemin_migr/dist_upgrade_jessie ]; then
    prim_packages_jessie
    dist_upgrade_jessie
fi

if [ ! -e $chemin_migr/dist_upgrade_stretch ]; then
    prim_packages_stretch
    dist_upgrade_stretch
fi

clean_post_stretch
gensourcese4
install_se4
show_part "Terminé :) - Bonne utilisation de SambaEdu 4 !!!"

# [ -e /etc/ssmtp/ssmtp.conf ] && MAIL_REPORT

exit 0