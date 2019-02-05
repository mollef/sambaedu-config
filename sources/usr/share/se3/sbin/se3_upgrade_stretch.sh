#!/bin/bash
# Projet SambaEdu - distribué selon la licence GPL
####Script permettant de migrer un serveur Se3 de wheezy en se4-fs sous stretch  ####
### Auteur : Franck Molle franck.molle@sambaedu.org
## Version 0.3 - 12-2018 ##

# Lecture des fonctions communes
source /usr/share/se3/sbin/libs-common.sh

# check_whiptail --> test présence 
# erreur --> sort en erreur avec le message
# poursuivre_ou_corriger --> explicite
# poursuivre --> poursuivre oui pas
# show_part --> afficher message couleur partie
# show_info --> Affichage d'une info
# conf_network --> configuration du réseau
# write_sambaedu_conf  Fonction écriture fichier de conf /etc/sambaedu/se4ad.config et se4fs
# write_se4fs_config
# Fonction export des fichiers tdb et smb.conf --> export_smb_files()
# Fonction export des fichiers --> dhcp export_dhcp()
# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif --> export_ldap_files()
# Fonction export des fichiers  sql --> export_sql_files()
# Fonction export des fichiers   --> export_cups_config()
# Recherche de sid en doublon  --> search_duplicate_sid()

function show_title() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"
WELCOME_TITLE="Migration vers SE4-FS"
WELCOME_TEXT="Bienvenue dans le script de migration SAMBAEDU 4.

SambaEdu est un projet libre sous licence GPL vivant de la collaboration active des différents contributeurs issus de différentes académies

Ce programme va migrer votre serveur actuel SE3 Wheezy vers SE4FS sous Debian Stretch. A noter qu'un reboot est nécessaire une fois la machine en Jessie.

A ce stade, il faudra donc relancer le script afin de poursuivre correctement la migration Stretch.

Attention : Vous devez disposer d'un SE4-AD en container ou machine virtuelle qui sera utilisé par SE4-FS"
$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 21 75
}

errexit()
{
	DEBIAN_PRIORITY="high"
	DEBIAN_FRONTEND="dialog" 
	export  DEBIAN_PRIORITY
	export  DEBIAN_FRONTEND
	exit 1
}

function show_menu() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"
WELCOME_TITLE="Migration vers SE4-FS"

$dialog_box --backtitle "$BACKTITLE" --title "Migration vers SE4-FS" \
--menu "Bienvenue, choisissez l'action à effectuer" 14 80 5  \
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

line_test()
{
show_info "Test de la connexion internet wget http://wawadeb.crdp.ac-caen.fr/index.html"
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
apt-get -qq update $option_update
check_error
}


function gensource_distrib()
{
distrib_name="$1"
show_info "Mise à jour des sources $distrib_name"
[ "$devel" != "yes" ] && rm -f /etc/apt/sources.list.d/*
if [ "$distrib_name" = "jessie" ];then
    mirror_debian="deb.debian.org"
else
    mirror_debian="$mirror_name"
fi
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://$mirror_debian/debian $distrib_name main non-free contrib

# Security Updates:
deb http://security.debian.org/debian-security $distrib_name/updates main contrib non-free

# $distrib_name-updates
deb http://ftp.fr.debian.org/debian/ $distrib_name-updates main contrib non-free

# $distrib_name-backports
#deb http://ftp.fr.debian.org/debian/ $distrib_name-backports main
END
apt-get -q update $option_update
check_error
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
apt-get -qq update
check_error
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
apt-get -qq update
check_error
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
show_info "Téléchargement des paquets nécessaires à la migration"
echo -e "$COLCMD"
apt-get dist-upgrade -d -y --allow-unauthenticated
echo -e "$COLTXT"
show_info "terminé !!\nTaille du cache actuel : $(du -sh /var/cache/apt/archives/ |  awk '{print $1}')"
touch "$chemin_migr/download_only"
}

function preconf_se4fs()
{
se4fs_title="Configuration de SE4FS"
REPONSE=""
details="no"
se4fs_ip="$se3ip"
se4fs_name="se4fs"
# 

while [ "$REPONSE" != "yes" ]
do
    if [ -e "$se4ad_config" ]; then
        source $se4ad_config
        confirm_txt="Le fichier $se4ad_config a été pris en compte.
Vous pouvez simplement confirmer les valeurs si elles conviennent. Dans le cas contraire, vous pourrez les modifier.

Ip du serveur se4AD :   $se4ad_ip    
Nom du serveur se4AD :  $se4ad_name
Nom de domaine AD :     $domain
Nom de domaine Samba :  $samba_domain

Confirmer l'enregistrement de cette configuration ?"

        if ($dialog_box --backtitle "$BACKTITLE" --title "$se4fs_title" --yesno "$confirm_txt" 20 60) then
            REPONSE="yes"
            break
        else
            details="yes"
        fi	
    fi
    se4fs_name="se4fs"
    samba_domain_check="no"
    if [ "$details" != "no" ]; then
	$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir ou confirmer l'IP du SE4-AD" 12 70 $se4ad_ip 2>$tempfile || erreur "Annulation"
        se4fs_ip=$(cat $tempfile)
	se4ad_name_title="Nom du SE4-AD"
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_name_title" --inputbox "Saisir ou confirmer le Nom de la machine SE4-AD" 12 70 $se4ad_name 2>$tempfile || erreur "Annulation"
        se4ad_name=$(cat $tempfile)
        choice_domain_title="Important - Nom de domaine AD"
        choice_domain_text="Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc important.
Il est composé de plusieurs parties : le nom de domaine samba suivi de son suffixe, séparés par un point.

Exemple de domaine AD : \"diderot.org\"
* le domaine samba serait \"diderot\" et le suffixe \".org\"

ATTENTION : 
* Le domaine samba actuel \"$se3_domain\" doit être CONSERVÉ pour permettre une migration AUTOMATIQUE des clients Windows sur le domaine AD. Le suffixe \"$domain\" peut quant à lui être modifié selon les besoins.
* le domaine samba ne doit en aucun cas dépasser 15 caractères.
* Les domaines AD du type sambaedu.lan ou etab.local sont à proscrire"
 	domain="$(hostname -d)"
	while [ "$samba_domain_check" != "ok" ]
	do
            color="color15"
            NEWT_COLORS="window=,$color border=black,$color textbox=black,$color" $dialog_box --backtitle "$BACKTITLE" --title "$choice_domain_title" --inputbox "$choice_domain_text" 23 80 $se3_domain.$domain 2>$tempfile || erreur "Annulation"
            domain="$(cat $tempfile)"		
            samba_domain="$(echo "$domain" | cut -d"." -f1)"
            samba_domain_size="${#samba_domain}"
            if [ $samba_domain_size -gt 15 ]; then
            NEWT_COLORS='                                                                                                                         
 window=,red
 border=white,red
 textbox=white,red
 button=black,white' whiptail --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --msgbox "Erreur : $samba_domain dépasse 15 caractères, merci de modifier votre saisie" 13 70
            continue
            else
                samba_domain_check="ok"
            fi
        done
    fi
    details="yes"
    confirm_title="Récapitulatif de la configuration prévue"
    confirm_txt="
Ip du serveur se4AD :     $se4ad_ip
Nom du serveur se4AD :    $se4ad_name

Nom de domaine AD saisi : $domain
Nom de domaine samba :    $samba_domain

Confirmer l'enregistrement de cette configuration ?"
    if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 18 60) then
            REPONSE="yes"
    else
            REPONSE="no"
    fi	
done
}

function system_check()
{
show_part "Preparation et tests du systeme" | tee -a $fichier_log
libre_root=$(($(stat -f --format="%a*%S/1048576" /))) 
libre_var=$(($(stat -f --format="%a*%S/1048576" /var))) 

if [ "$libre_root" -lt 800 ]; then
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

if [ "$PARTROOT_SIZE" -le 2500000 ]; then
    erreur "La partition racine fait moins de 2.5Go, c'est insuffisant pour passer en Stretch" | tee -a $fichier_log
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
show_part "Mise a jour du paquet SE3 $distrib"
service apache2se stop
service apache2 stop
apt-get install se3 -y --force-yes 
    if [ "$?" != "0" ]; then
        erreur "Une erreur s'est produite lors de la mise à jour des paquets Se3\nIl est conseille de couper la migration"
	poursuivre
    fi

apt-get autoremove --purge -y
touch $chemin_migr/upgrade_se3${distrib}
}

function backuppc_check_mount()
{
show_info "Test de montage sur Backuppc"
df -h | grep backuppc && umount /var/lib/backuppc
if [ ! -z "$(df -h | grep /var/lib/backuppc)" ]; then 
    erreur "Il semble qu'une ressource soit montee sur /var/lib/backuppc. Il faut la demonter puis relancer"
    exit 1
else
    [ -e $bpc_script ] && $bpc_script stop
    [ ! -h /var/lib/backuppc ] && rm -rf /var/lib/backuppc/*
fi
}

function backuppc_uninstall()
{
rm -f /etc/init.d/backuppc.ori 
if [ -e "$bpc_script" ]; then
    show_info "Suppression de backuppc"
    $bpc_script stop
    apt-get remove backuppc --purge -y
    rm -f /etc/apache2se/sites-enabled/backuppc.conf
fi
}

function lxc_bridge_disable()
{
interfaces_file="/etc/network/interfaces" 
BR0_TITLE="Pont réseau br0 et container SE4AD"
BR0_TEXT="Le pont réseau qui a été mis en place pour le container doit être désactivé durant le passage en strech. 
Il sera réactivé à l'issue de la migration.

Attention : La machine devra rebooter pour appliquer cette modification"
if [ -e "${interfaces_file}_sav_install_lxc" ]; then
    if ($dialog_box  --backtitle "$BACKTITLE" --title "$BR0_TITLE" --yesno "$BR0_TEXT" 15 75) then
        ecard="$(grep ^bridge_ports ${interfaces_file}_sav_install_lxc | cut -d" " -f 2)"
        [ -z "$ecard" ] && ecard="eth0"
        show_info "Arrêt de se4ad"
        sleep 2
        lxc-stop -n se4ad
        SETMYSQL dhcp_iface $ecard
        SETMYSQL ecard $ecard
        show_info "Modification de $interfaces_file"
        [ ! -e "${interfaces_file}_br0" ] && cp -v $interfaces_file ${interfaces_file}_br0 
        mv -v ${interfaces_file}_sav_install_lxc $interfaces_file
        show_info "Redémarrage de l'interface réseau $ecard..."
        echo -e "$COLCMD"
        /etc/init.d/networking stop
        /etc/init.d/networking start
        echo -e "$COLTXT\c"
        brctl delif br0 $ecard ; ifconfig br0 down ; brctl delbr br0
    reboot && exit 0
    else
        erreur "Arrêt"
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

function clean_se3_modules(){
show_part "Suppression des modules se3 obsolètes"
backuppc_check_mount
backuppc_uninstall
for package in se3-pla se3-internet
do
    if  dpkg -l | grep -q $package
    then
        show_info "Suppression de $package"
        apt-get remove $package --purge -y 
        apt-get autoremove --purge -y
    fi
    
done

apache2_dir="/etc/apache2"
apt-get remove se3-pla phpldapadmin --purge

}

function clean_pre_jessie(){ 
show_part "Suppression de paquets et de scripts SE3 - certains seront réinstallés post-migration"
show_info "Nettoyage des scripts se3 et des paquets inutiles" | tee -a $fichier_log
echo -e "$COLCMD"
apt-get autoremove --purge -y
for package in apache2 apache2.2-bin apache2.2-common rlinetd apt-listchanges wine wine32 libc6:i386 samba samba-common mysql-server-5.5 ntpdate backuppc nut nut-client nut-server cups cups-client cups-server-common cups-common
do
    if  dpkg -l | grep -q $package
    then
        show_info "Suppression de $package"
        apt-get remove $package --purge -y 
        apt-get autoremove --purge -y
    fi
    
done
echo -e "$COLTXT"
# apt-get remove libc6:i386 slapd samba samba-common mysql-server-5.5 ntpdate backuppc nut nut-client nut-server --purge -y
apt-get autoremove --purge -y
show_info "Nettoyage des scripts se3 et des diversions"
for divert in $(dpkg-divert --list | grep "par se3" | cut -d" " -f3)
do
    dpkg-divert --remove $divert
done
rm -f /etc/samba/smb.conf
rm -rf /usr/share/se3/scripts /usr/share/se3/scripts-alertes/ /usr/share/se3/shares/ /usr/share/se3/data/
show_info "Suppression de l'utilisateur www-se3"
userdel www-se3
touch $chemin_migr/clean_pre_jessie
}

function dist_upgrade()
{
local distrib="$1"
show_part "Migration en $distrib"
echo -e "$COLCMD"
apt-get autoremove --purge -y
echo -e "$COLTXT"
[ -z "$LC_ALL" ] && LC_ALL=C && export LC_ALL=C 
[ -z "$LANGUAGE" ] && export LANGUAGE=fr_FR:fr:en_GB:en  
[ -z "$LANG" ] && export LANG=fr_FR@euro 
# Creation du source.list de la distrib
gensource_distrib $distrib
# On se lance
apt-get install debian-archive-keyring --allow-unauthenticated | tee -a $fichier_log
aptitude install libc6 locales  -y < /dev/tty | tee -a $fichier_log
if [ "$?" != "0" ]; then
    erreur "Une erreur s'est produite lors de la mise a jour des paquets lib6 et locales. Reglez le probleme et relancez le script"
    errexit
fi
show_info "mise a jour de lib6  et locales ---> OK" | tee -a $fichier_log
sleep 1
touch $chemin_migr/prim_packages_$distrib-ok

show_info "Installation des paquets $distrib restants, patience ;)" 
   
echo "Dpkg::Options {\"--force-confold\";}" > /etc/apt/apt.conf	
# echo "Dpkg::Options {\"--force-confnew\";}" > /etc/apt/apt.conf
# DEBIAN_FRONTEND="non-interactive" 
apt-get dist-upgrade $option_apt  < /dev/tty | tee -a $fichier_log

if [ "$?" != "0" ]; then
    echo -e "$COLERREUR Une erreur s'est produite lors de la migration vers $distrib."
    echo "En fonction du probleme, vous pouvez choisir de poursuivre tout de meme ou bien d'abandonner afin de terminer la migration manuellement."
    #/usr/share/se3/scripts/install_se3-module.sh se3
    echo -e "$COLTXT"
    echo "Voulez vous continuez (o/N) ? "
    read REPLY
    if [ "$REPLY" != "O" ] &&  [ "$REPLY" != "o" ] && [ -n $REPLY ]; then
        erreur "Abandon !"
        errexit
    fi
fi
touch $chemin_migr/dist_upgrade_$distrib
show_info "Migration du systeme vers $distrib ok !!" | tee -a $fichier_log
show_info "Nettoyage des paquets obsolètes"
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

function clean_post_jessie()
{
show_part "Redémarrage de la machine"
show_info "Un reboot est nécessaire avant de pousuivre avec la migration Stretch." 
show_info "Le script sera relancé une fois identifé root...
Reboot dans 10s !"
for counter in 10 9 8 7 6 5 4 3 2 1
do
    echo -e "$counter..\c"
    sleep 1
done
touch $chemin_migr/reboot_post_jessie
cat >/root/.profile <<END
if [ -f /usr/share/se3/sbin/se3_upgrade_stretch.sh ]; then
    . /usr/share/se3/sbin/se3_upgrade_stretch.sh 
fi
END
reboot
exit 0
}

function show_title_post_reboot() {
WELCOME_TITLE="Migration vers SE4-FS"
WELCOME_TEXT="Bienvenue dans le script de migration SAMBAEDU 4.

Phase finale : Migration en stretch.

Attention : Vous devez disposer d'un SE4-AD en container ou machine virtuelle qui sera utilisé par SE4-FS"
$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 15 75
}


function clean_post_stretch {
show_part "Post installation Stretch"
show_info "Installation du paquet Dialog"
apt-get install dialog -y
show_info "nettoyage des paquets inutiles"
apt-get autoremove -y --purge
# apt-get clean

rm -f /etc/apt/apt.conf
DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND

cp $dir_preseed/profile_se4fs /root/.profile
cp $dir_preseed/install_se4fs_phase2.sh /root/
show_part "Redémarrage de la machine"
show_info "Le script final d'installation de SE4FS sera lancé une fois identifé root...
Reboot dans 10s !"
for counter in 10 9 8 7 6 5 4 3 2 1
do
    echo -e "$counter..\c"
    sleep 1
done
reboot
exit 0
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
dir_preseed="/var/www/diconf"
se4ad_config="$dir_export/se4ad.config"
se4fs_config="$dir_config/sambaedu.conf"
se4fs_config_clients="$dir_config/clients.conf"
interfaces_file="/etc/network/interfaces"

#init des params
source /etc/se3/config_c.cache.sh  
source /etc/se3/config_l.cache.sh 
source /etc/se3/config_m.cache.sh
# source /usr/share/se3/includes/config.inc.sh -cml
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
preseed_se4fs="yes"

clear

if [ ! -e $chemin_migr/reboot_post_jessie ]; then
    show_title
    check_whiptail
    check_arch
    show_menu
    # lxc_bridge_disable
    conf_network
    line_test
    screen_test
    cp_ssh_key
    #Lancement de la migration Jessie
    # test du system
    system_check
    preconf_se4fs
    mirror_choice
    write_se4fs_config
else
    show_title_post_reboot
    source $se4fs_config 
fi

if [ ! -e $chemin_migr/upgrade_se3wheezy ]; then
    gensource_wheezy
    upgrade_se3_packages wheezy
    backuppc_check_mount
    maj_slapd_wheezy
fi

if [ ! -e $chemin_migr/clean_pre_jessie ]; then

    export_ldap_files
    import_ldap_files
    clean_se3_modules
    gensourcese3jessie
    upgrade_se3_packages jessie
    poursuivre
    clean_pre_jessie
    poursuivre
fi

if [ ! -e $chemin_migr/dist_upgrade_jessie ]; then
    dist_upgrade jessie
    write_hostconf
    clean_post_jessie
    
fi

if [ ! -e $chemin_migr/dist_upgrade_stretch ]; then
    dist_upgrade stretch
fi

clean_post_stretch

# gensourcese4
# install_se4
# show_part "Terminé :) - Bonne utilisation de SambaEdu 4 !!!"
apt-get install dialog -y

# [ -e /etc/ssmtp/ssmtp.conf ] && MAIL_REPORT
#  
exit 0