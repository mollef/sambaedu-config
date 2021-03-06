#!/bin/bash
# installation Se4-FS phase 2
# version pour Stretch - franck molle
# version 0.3 - 12-2019 

# ---------- Début des fonctions ----------#
# # Fonction permettant de quitter en cas d'erreur 
function quit_on_choice()
{
echo -e "$COLERREUR"
echo "Arrêt du script !"
echo -e "$1"
echo -e "$COLTXT"
exit 1
}

# Affichage de la partie actuelle
function show_part()
{
echo ""
echo -e "$COLPARTIE"
echo -e "--------"
echo "$1"
echo -e "-------- $COLTXT"
# sleep 1
}

# Affichage d'une info
function show_info()
{
echo -e "$COLINFO"
echo -e "$1 $COLTXT"
# sleep 1
}

function dev_debug() {
if [ -n "$devel" ]; then
    mkdir -p /root/.ssh/
    ssh_keyser="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMQ6Nd0Kg+L8200pR2CxUVHBtmjQ2xAX2zqArqV45horU8qopf6AYEew0oKanK3GzY2nrs5g2SYbxqs656YKa/OkTslSc5MR/Nndm9/J1CUsurTlo+VwXJ/x1qoLBmGc/9mZjdlNVKIPwkuHMKUch+XmsWF92GYEpTA1D5ZmfuTxP0GMTpjbuPhas96q+omSubzfzpH7gLUX/afRHfpyOcYWdzNID+xdmML/a3DMtuCatsHKO94Pv4mxpPeAXpJdE262DPXPz2ZIoWSqPz8dQ6C3v7/YW1lImUdOah1Fwwei4jMK338ymo6huR/DheCMa6DEWd/OZK4FW2KccxjXvHALn/QCHWCw0UMQnSVpmFZyV4MqB6YvvQ6u0h9xxWIvloX+sjlFCn71hLgH7tYsj4iBqoStN9KrpKC9ZMYreDezCngnJ87FzAr/nVREAYOEmtfLN37Xww3Vr8mZ8/bBhU1rqfLIaDVKGAfnbFdN6lOJpt2AX07F4vLsF0CpPl4QsVaow44UV0JKSdYXu2okcM80pnVnVmzZEoYOReltW53r1bIZmDvbxBa/CbNzGKwxZgaMSjH63yX1SUBnUmtPDQthA7fK8xhQ1rLUpkUJWDpgLdC2zv2jsKlHf5fJirSnCtuvq6ux1QTXs+bkTz5bbMmsWt9McJMgQzWJNf63o8jw== GitLab"
    grep -q "$ssh_keyser" /root/.ssh/authorized_keys || echo $ssh_keyser >> /root/.ssh/authorized_keys 
fi
}

# Fonction permettant de poser la question s'il faut poursuivre ou quitter
function poursuivre()
{
echo
REPONSE=""
while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
do
    echo -e "$COLTXT"
    echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXL}) $COLSAISIE"
    read -t 40 REPONSE
    echo -e "$COLTXT"
    if [ -z "$REPONSE" ]; then
            REPONSE="o"
    fi
done

if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
        quit_on_choice "Abandon!"
fi
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
    poursuivre
fi
}

# Fonction permettant de quitter en cas d'erreur 
# no @params 
function quit_on_error()
{
if [ "$?" != "0" ]; then
    echo -e "$COLERREUR"
    echo "$1"
    echo "Attention "
    echo -e "la dernière commande a envoyé une erreur critique pour la suite !\nImpossible de poursuivre"
    echo -e "$COLTXT"
    exit 1
fi
}
# Fonction génération du sources.list stretch FR
function gensourcelist()
{
[ -z "$mirror_name" ] && mirror_name="deb.debian.org"
cat >/etc/apt/sources.list <<END
deb http://$mirror_name/debian stretch main non-free contrib

deb http://security.debian.org/debian-security stretch/updates main contrib non-free

# stretch-updates, previously known as 'volatile'
deb http://deb.debian.org/debian stretch-updates main contrib non-free
END
apt-get -q update
}

# Fonction génération du sources.list SE4
function gensourcese4()
{

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

# Fonction génération conf réseau
gen_network()
{

dialog_box="dialog"
se4fs_lan_title="Modification de la configuration réseau"	
se4fs_ecard="$(ls /sys/class/net/ | grep -v lo | head -n 1)"
se4fs_ip="$(ifconfig $se4fs_ecard | grep "inet " | awk '{ print $2}')"
se4fs_mask="$(ifconfig $se4fs_ecard | grep "inet " | awk '{ print $4}')"
se4fs_network="$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")"
se4fs_bcast="$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")"
se4fs_gw="$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")"


REPONSE=""
while [ "$REPONSE" != "yes" ]
do
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Confirmer le nom de la carte réseau à configurer" 15 70 $se4fs_ecard 2>$tempfile || erreur "Annulation"
    se4fs_ecard=$(cat $tempfile)
    
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'IP du SE4-AD souhaitée" 15 70 $se4fs_ip 2>$tempfile || erreur "Annulation"
    se4fs_ip=$(cat $tempfile)

    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir le Masque sous réseau" 15 70 $se4fs_mask 2>$tempfile || erreur "Annulation"
    se4fs_mask=$(cat $tempfile)
    
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 15 70 $se4fs_network 2>$tempfile || erreur "Annulation"
    se4fs_network=$(cat $tempfile)
    
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de broadcast" 15 70 $se4fs_bcast 2>$tempfile || erreur "Annulation"
    se4fs_bcast=$(cat $tempfile)
    
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 15 70 $se4fs_gw 2>$tempfile || erreur "Annulation"
    se4fs_gw=$(cat $tempfile)

    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse du serveur DNS" 15 70 $se4fs_gw 2>$tempfile || erreur "Annulation"
    se4fs_dns=$(cat $tempfile)
    
    confirm_title="Nouvelle configuration réseau"
    confirm_txt="La configuration sera la suivante 

Carte réseau à configurer :   $se4fs_ecard    
Adresse IP du serveur SE3 :   $se4fs_ip
Adresse réseau de base :      $se4fs_network
Adresse de Broadcast :        $se4fs_bcast
Adresse IP de la Passerelle : $se4fs_gw
Adresse IP du Serveur DNS   : $se4fs_dns
	
Poursuivre avec ces modifications ?"	
	
    if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 15 70) then
        REPONSE="yes"
        cat >/etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto $se4fs_ecard
iface $se4fs_ecard inet static
        address $se4fs_ip
        netmask $se4fs_mask
        network $se4fs_network
        broadcast $se4fs_bcast
        gateway $se4fs_gw
END
    sed "s/nameserver.*/nameserver $se4fs_dns/" -i /etc/resolv.conf
    
    else
            REPONSE="no"
    fi
done
    confirm_title="Redémarrage nécessaire"
    confirm_txt="La machine doit redémarrer afin de prendre en compte les nouveaux paramètres. Rédémarrer immédiatement ?"
    if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 15 70) then
        echo "reboot dans 5s"
        sleep 5 && reboot
    else
        echo "Annulation du reboot - sortie du script"
        exit 1
    fi
}

# Fonction Affichage du titre et choix dy type d'installation
function show_title()
{

clear
# 
# echo -e "$COLTITRE"
# echo "--------------------------------------------------------------------------------"
# echo "----------- Installation de SambaEdu4-FS sur la machine.----------------"
# echo "--------------------------------------------------------------------------------"
# echo -e "$COLTXT"
# echo "Appuyez sur Entree pour continuer"
# read dummy


BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"

WELCOME_TITLE="Installeur de samba Edu 4 - serveur File System"
WELCOME_TEXT="Bienvenue sur l'installation du serveur de fichiers SambaEdu 4.

SambaEdu est un projet libre sous licence GPL vivant de la collaboration active des différents contributeurs issus de différentes académies

Ce programme installera les paquets nécessaires au serveur SE4-FS 

Contact : 
Franck.molle@sambaedu.org : Maintenance de l'installeur"

dialog  --ok-label Ok --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 25 70
#
}


# Fonction recupération des paramètres via fichier de conf ou tgz
function recup_params() {

echo -e "$COLINFO"
if [ -e "$se4fs_config" ] ; then
 	show_info "$se4fs_config est bien present sur la machine - initialisation des paramètres"
	source $se4fs_config
else
	show_info "$se4fs_config ne se trouve pas sur la machine"
	se4fs_ip="$(ifconfig eth0 | grep "inet " | awk '{ print $2}')"
fi
}

# Mise en place du proxy

function set_proxy() {
profile_file="/etc/profile"
wgetrc_file="/etc/wgetrc"
# nettoyage
sed -i 's/http_proxy=.*\n//' $profile_file
sed -i 's/https_proxy=.*\n//' $profile_file
sed -i 's/ftp_proxy=.*\n//' $profile_file
sed -i 's/.*http_proxy.*\n//' $profile_file
sed -i 's/^http_proxy = .*\n//' $wgetrc_file
sed -i 's/^https_proxy = .*\n//' $wgetrc_file
# mise en place

if [ -n "$proxy_config" ]; then
echo "http_proxy=\"http://$proxy_config\"" >> $profile_file
echo "https_proxy=\"http://$proxy_config\"" >> $profile_file
echo "ftp_proxy=\"http://$proxy_config\"" >> $profile_file
echo "export http_proxy https_proxy ftp_proxy" >> $profile_file
echo "http_proxy = http://$proxy_config" >> $wgetrc_file
echo "https_proxy = http://$proxy_config" >> $wgetrc_file
# relecture
http_proxy="http://$proxy_config"
https_proxy="http://$proxy_config"
ftp_proxy="http://$proxy_config"
export http_proxy https_proxy ftp_proxy
fi
}

# Fonction affichage du menu principal
function show_menu()
{
while :; do
dialog --backtitle "$BACKTITLE" --title "Installeur de samba Edu 4 - serveur File System" \
--menu "Choisissez l'action à effectuer" 15 90 7  \
"1" "Installation classique" \
"2" "Téléchargement des paquets uniquement (utile pour préparer un modèle de VM)" \
"3" "Configuration du réseau uniquement (en cas de changement d'IP)" \
2>$tempfile

    choice=`cat $tempfile`
    [ "$?" != "0" ] && exit 0
    case $choice in
            1)
            break
            ;;
            2)
            download_packages
            download_packages_se4
            continue
            ;;
            3)
            show_info "Fonction non fonctionnelle for the moment, envoyez-moi un mel ;)" 
            sleep 5
#             conf_network
            continue
            ;;
            *) exit 0
            ;;
            esac
done
}

# Fonction installation des paquets de base
function installbase()
{
show_info "Mise à jour des dépots et upgrade si necessaire, quelques mn de patience..."
echo -e "$COLCMD"
# tput reset
apt-get -qq update
apt-get upgrade --quiet --assume-yes

show_info "installation des paquets prioritaires ssh, vim, wget, etc..."
echo -e "$COLCMD"
prim_packages="ssh vim wget nano iputils-ping bind9-host libldap-2.4-2 ldap-utils makepasswd haveged ssmtp"
apt-get install --quiet --assume-yes $prim_packages
echo -e "$COLTXT"
}

# Fonction génération des fichiers /etc/hosts et /etc/hostname
function write_hostconf()
{
cat >/etc/hosts <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
#$se4fs_ip	$se4fs_name.$domain	$se4fs_name
END

cat >/etc/hostname <<END
$se4fs_name
END
}

function download_packages() { 
if [ "$download" = "yes" ] || [ ! -e /root/dl_ok ]; then
# 	show_title
# 	test_ecard
	show_part "Pré-téléchargement des paquets principaux nécessaire à l'installation"
	installbase
	show_info "Téléchargement de samba 4.5" 
	echo -e "$COLCMD"
	apt-get install $samba_packages -d -y
	echo -e "$COLCMD"
	echo "Phase de Téléchargement terminée"
	echo -e "$COLTXT"
fi
}

function download_packages_se4() {
gensourcese4
show_info "Téléchargement des paquets SambaEdu & Cie"
apt-get install sambaedu -d -y
rm -f /etc/apt/sources.list.d/se4.list
show_info "Update des sources"
apt-get -qq update 
}

# Fonction installation de samba 4.5 (pour le moment)
function installsamba()
{
show_info "Installation de samba 4.5" 
echo -e "$COLCMD"
apt-get install $samba_packages -y
# /etc/init.d/samba stop
# /etc/init.d/smbd stop
# /etc/init.d/nmbd stop
# /etc/init.d/winbind stop
echo -e "$COLTXT"

}


# Fonction permettant la mise à l'heure du serveur 
function set_time()
{
echo -e "$COLPARTIE"
echo "Type de configuration Ldap et mise a l'heure"
echo -e "$COLTXT"


echo -e "$COLINFO"

if [ -n "$GATEWAY" ]; then
	echo "Tentative de Mise à l'heure automatique du serveur sur $GATEWAY..."
	ntpdate -b $GATEWAY
	if [ "$?" = "0" ]; then
		heureok="yes"
	fi
fi

if [ "$heureok" != "yes" ];then

	echo "Mise à l'heure automatique du serveur sur internet..."
	echo -e "$COLCMD\c"
	ntpdate -b fr.pool.ntp.org
	if [ "$?" != "0" ]; then
		echo -e "${COLERREUR}"
		echo "ERREUR: mise à l'heure par internet impossible"
		echo -e "${COLTXL}Vous devez donc vérifier par vous même que celle-ci est à l'heure"
		echo -e "le serveur indique le$COLINFO $(date +%c)"
		echo -e "${COLTXL}Ces renseignements sont-ils corrects ? (${COLCHOIX}O/n${COLTXL}) $COLSAISIE\c"
		read rep
		[ "$rep" = "n" ] && echo -e "${COLERREUR}Mettez votre serveur à l'heure avant de relancer l'installation$COLTXT" && exit 1
	fi
fi
}


# Fonction permettant de se connecter ssh root sur se4-FS
function Permit_ssh_by_password()
{
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

/usr/sbin/service ssh restart
}

function check_ad_access()
{
echo -e "$COLPARTIE"
echo -e "Test de connexion sur le serveur AD : $se4ad_ip"
echo -e "$COLCMD"
ping -c 3 $se4ad_ip
check_error
echo -e "$COLINFO"
echo "Tentative de connexion ssh sur l'AD et copie de la clé ssh si besoin"
echo -e "$COLCMD"
ssh-keyscan -H $se4ad_ip >> ~/.ssh/known_hosts
ssh-copy-id -i $dir_config/id_rsa.pub root@$se4ad_ip
scp -i $dir_config/id_rsa @$se4ad_ip:/root/se4fs.conf /root/
check_error
if [ -e /root/se4fs.conf ]; then
cat /root/se4fs.conf >> $se4fs_config
fi
echo -e "$COLTXT"


}

# Fonction permettant de changer le pass root
function install_se_packages()
{
show_part "Installation des paquets SambaEdu"
poursuivre
export DEBIAN_FRONTEND="dialog"
export DEBIAN_PRIORITY="high"
echo -e "$COLCMD"
apt-get install -y sambaedu-config 
apt-get install -y sambaedu 
apt-get install -y sambaedu-client-windows 
echo -e "$COLTXT"
}

function disable_ipv6()
{
if ! grep -q "#disable_ipv6" /etc/sysctl.conf; then
echo "#disable_ipv6
# désactivation de ipv6 pour toutes les interfaces
net.ipv6.conf.all.disable_ipv6 = 1

# désactivation de l’auto configuration pour toutes les interfaces
net.ipv6.conf.all.autoconf = 0

# désactivation de ipv6 pour les nouvelles interfaces (ex:si ajout de carte réseau)
net.ipv6.conf.default.disable_ipv6 = 1

# désactivation de l’auto configuration pour les nouvelles interfaces
net.ipv6.conf.default.autoconf = 0
" >> /etc/sysctl.conf
sysctl -p
fi
}

function restart_php()
{
echo -e "$COLPARTIE"
echo "Remise en route du service php7-fpm"
echo -e "$COLCMD"
/etc/init.d/php7.0-fpm stop
sleep 3
/etc/init.d/php7.0-fpm start
echo -e "$COLTXT"
}

# Fonction permettant de changer le pass root
function change_pass_root()
{	
TEST_PASS="none"
echo -e "$COLPARTIE"
echo -e "Mise en place du mot de passe Root"
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte super-utilisateur root"
echo -e "$COLTXT"

passwd
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO"
        echo "Mot de passe root changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"
}

#### 				---------- Fin des fonctions ---------------####

# vt220 sucks !
[ "$TERM" = "vt220" ] && TERM="linux"

#Variables :

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m\c"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m\c"     # Gris avec coupure
COLTXL="\033[0;37m"     # Gris 
COLINFO="\033[0;36m\c"	# Cyan
COLPARTIE="\n\033[1;34m\c"	# Bleu
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert


### Mode devel pour le moment sur on !###
devel="yes"
dev_debug

samba_packages="samba winbind libnss-winbind krb5-user smbclient"
export DEBIAN_FRONTEND=noninteractive
dir_config="/etc/sambaedu"
nameserver=$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2)
se4fs_config="$dir_config/sambaedu.conf"

echo -e "$COLPARTIE"
echo "Prise en compte des valeurs de $se4fs_config"
echo -e "$COLTXT"

#### Variables suivantes init via Fichier de conf ####
# ip du se4fs --> $se4fs_ip" 
# Nom de domaine samba du SE4-FS --> $samba_domain" 
# Nom de domaine complet - realm du SE4-FS --> $domain" 
# Adresse IP de l'annuaire LDAP à migrer en FS --> $se3ip" 
# Nom du domaine samba actuel --> $se3_domain"  
# Nom netbios du serveur se3 actuel--> $netbios_name" 
# Adresse du serveur DNS --> $nameserver" 
# Pass admin LDAP --> $adminPw" 
# base dn LDAP ancienne --> $ldap_base_dn



tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
tempfile2=`tempfile 2>/dev/null` || tempfile=/tmp/inst2$$
# trap "rm -f $tempfile ; rm -f $tempfile2" 0 1 2 5 15

while :; do
	case $1 in
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

show_title
recup_params
set_proxy
show_menu


# A voir pour modifier ou récupérer depuis sambaedu.config 
[ -z "$samba_domain" ] && samba_domain="sambaedu4"
[ -z "$domain" ] && domain="sambaedu4.lan"


samba_domain_up="$(echo "$samba_domain" | tr [:lower:] [:upper:])"
domain_up="$(echo "$domain" | tr [:lower:] [:upper:])"
sambadomaine_old="$(echo $se3_domain| tr [:lower:] [:upper:])"
sambadomaine_new="$samba_domain_up"

gensourcelist
download_packages
haveged
poursuivre

dev_debug

echo -e "$COLPARTIE"

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY

# LADATE="$(date +%d-%m-%Y)"
# fichier_log="/etc/se3/install-stretch-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

write_hostconf
disable_ipv6
installsamba
Permit_ssh_by_password

echo "Génération des sources SE4"
gensourcese4

check_ad_access

install_se_packages

restart_php

change_pass_root

echo -e "$COLTITRE"
# echo "L'installation est terminée. Bonne utilisation de SambaEdu4-FS ! :)"
echo "Installation de base SE4-FS stretch terminée :)"
echo -e "$COLTXT"

# script_absolute_path=$(readlink -f "$0")
# [ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_se4fs_phase2.sh ] && mv /root/install_se4fs_phase2.sh  /root/install_phase2.done
. /etc/profile

unset DEBIAN_FRONTEND
exit 0

