#!/bin/bash
# Projet SambaEdu - distribué selon la licence GPL
##### Script principal du paquet sambaedu-config - Permet le lancement des différents scripts d'installation ou migration 
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
# Fonction export des fichiers tdb et smb.conf --> export_smb_files()
# Fonction export des fichiers --> dhcp export_dhcp()
# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif --> export_ldap_files()
# Fonction export des fichiers  sql --> export_sql_files()
# Fonction export des fichiers   --> export_cups_config()
# Recherche de sid en doublon  --> search_duplicate_sid()

function usage() 
{
echo "Script permettant La configuration et l'installation de SE4'"
}

if [ "$1" = "--help" -o "$1" = "-h" ]
then
	usage
	echo "Usage : pas d'option"
	exit
fi

function show_title() {
BACKTITLE="Projet SambaÉdu - https://www.sambaedu.org"

WELCOME_TITLE="Menu principal de Sambaedu-config"
WELCOME_TEXT="Bienvenue dans l'outil de configuration de SambaEdu 4.

SambaEdu est un projet libre sous licence GPL vivant de la collaboration active des différents contributeurs issus de différentes académies.

Ce programme vous permettra de lancer les différents outils en vue d'une installation ou d'une migration automatisée de Sambaedu 4."

$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 18 70
}

function show_menu() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"
# while "$loop" != "end"; do
    $dialog_box --backtitle "$BACKTITLE" --title "Installation ou migration SambaEdu 4" \
--menu "Bienvenue, choisissez l'action à effectuer" 15 80 7  \
"1" "Générer des fichiers d'installation automatiques preseed SE4AD / SE4FS" \
"2" "Installer un annuaire SE4-AD dans un container LXC Debian Stretch " \
"3" "Migrer cette machine SE3 vers SE4FS. Nécessite un SE4AD déjà fonctionnel" \
"4" "Sortir du programme sans mofification" \
2>$tempfile

    choice=`cat $tempfile`
    [ "$?" != "0" ] && exit 0
    case $choice in
            1)
            $se3sbin/gen_se4preseed.sh
            exit 0
            ;;
            2)
            $se3sbin/install_se4lxc.sh
            exit 0
            ;;
            3)
            $se3sbin/se3_upgrade_stretch.sh
            exit 0
            ;;
            4)
            exit 0
            ;;
            *) exit 0
            ;;
    esac
# done
        
}


## recuperation des variables necessaires pour interoger mysql ###
source /etc/se3/config_c.cache.sh
source /etc/se3/config_m.cache.sh
source /etc/se3/config_l.cache.sh
source /usr/share/se3/includes/functions.inc.sh 

# Variables :
dialog_box="$(which whiptail)"
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
tempfile2=`tempfile 2>/dev/null` || tempfile=/tmp/inst2$$
# url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/se4/master/sources/sambaedu-config"
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources"
interfaces_file="/etc/network/interfaces" 


dir_config="/etc/sambaedu"
dir_export="/etc/sambaedu/export_se4ad"
dir_preseed="/var/www/diconf"

mkdir -p "$dir_export"

se4ad_config="$dir_export/se4ad.config"
script_phase2="install_se4ad_phase2.sh"
lxc_arch="$(arch)"
ecard="br0"
nameserver="$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2| head -n 1)"
se4ad_config_tgz="se4ad.config.tgz"
se4fs_config="$dir_config/sambaedu.conf"
se4fs_config_clients="$dir_config/clients.conf"
preseed_se4fs="yes"
se3sbin="/usr/share/se3/sbin/"
devel="yes"
check_whiptail
cp_ssh_key
show_title
show_menu


exit 0


