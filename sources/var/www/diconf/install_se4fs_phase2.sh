#!/bin/bash
# installation Se4-AD phase 2
# version pour Stretch - franck molle
# version 02 - 2018 


# # Fonction permettant de quitter en cas d'erreur 
function quit_on_choice()
{
echo -e "$COLERREUR"
echo "Arrêt du script !"
echo -e "$1"
echo -e "$COLTXT"
exit 1
}

function dev_debug() {
if [ -n "$devel" ]; then
    mkdir -p /root/.ssh/
    ssh_keyser="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMQ6Nd0Kg+L8200pR2CxUVHBtmjQ2xAX2zqArqV45horU8qopf6AYEew0oKanK3GzY2nrs5g2SYbxqs656YKa/OkTslSc5MR/Nndm9/J1CUsurTlo+VwXJ/x1qoLBmGc/9mZjdlNVKIPwkuHMKUch+XmsWF92GYEpTA1D5ZmfuTxP0GMTpjbuPhas96q+omSubzfzpH7gLUX/afRHfpyOcYWdzNID+xdmML/a3DMtuCatsHKO94Pv4mxpPeAXpJdE262DPXPz2ZIoWSqPz8dQ6C3v7/YW1lImUdOah1Fwwei4jMK338ymo6huR/DheCMa6DEWd/OZK4FW2KccxjXvHALn/QCHWCw0UMQnSVpmFZyV4MqB6YvvQ6u0h9xxWIvloX+sjlFCn71hLgH7tYsj4iBqoStN9KrpKC9ZMYreDezCngnJ87FzAr/nVREAYOEmtfLN37Xww3Vr8mZ8/bBhU1rqfLIaDVKGAfnbFdN6lOJpt2AX07F4vLsF0CpPl4QsVaow44UV0JKSdYXu2okcM80pnVnVmzZEoYOReltW53r1bIZmDvbxBa/CbNzGKwxZgaMSjH63yX1SUBnUmtPDQthA7fK8xhQ1rLUpkUJWDpgLdC2zv2jsKlHf5fJirSnCtuvq6ux1QTXs+bkTz5bbMmsWt9McJMgQzWJNf63o8jw== GitLab"
    grep -q "$ssh_keyser" /root/.ssh/authorized_keys || echo $ssh_keyser >> /root/.ssh/authorized_keys 
fi
}

# Fonction permettant de poser la question s'il faut poursuivre ou quitter
function go_on()
{
echo
REPONSE=""
while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
do
    echo -e "$COLTXT"
    echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXL}) $COLSAISIE"
    read REPONSE
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
    go_on
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
cat >/etc/apt/sources.list <<END
deb http://deb.debian.org/debian stretch main non-free contrib

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
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4

#### Sources testing seront desactivees en prod ####
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4testing


END
}

# Fonction génération conf réseau
gennetwork()
{
echo "saisir l'ip de la machine"
read NEW_SE3IP
echo "saisir le masque"
read NEW_NETMASK
echo "saisir l'adresse du réseau"
read NEW_NETWORK
echo "saisir l'adresse de brodcast"
read NEW_BROADCAST
echo "saisir l'adresse de la passerrelle"
read NEW_GATEWAY

echo -e "$COLINFO"
echo "Vous vous apprêtez à modifier les paramètres suivants:"
echo -e "IP:		$NEW_SE3IP"
echo -e "Masque:		$NEW_NETMASK"
echo -e "Réseau:		$NEW_NETWORK"
echo -e "Broadcast:	$NEW_BROADCAST"
echo -e "Passerelle:	$NEW_GATEWAY"

go_on

cat >/etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto eth0
iface eth0 inet static
        address $NEW_SE3IP
        netmask $NEW_NETMASK
        network $NEW_NETWORK
        broadcast $NEW_BROADCAST
        gateway $NEW_GATEWAY
END
}

# Fonction Affichage du titre et choix dy type d'installation
function show_title()
{

clear
# 
# echo -e "$COLTITRE"
# echo "--------------------------------------------------------------------------------"
# echo "----------- Installation de SambaEdu4-AD sur la machine.----------------"
# echo "--------------------------------------------------------------------------------"
# echo -e "$COLTXT"
# echo "Appuyez sur Entree pour continuer"
# read dummy


BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"

WELCOME_TITLE="Installeur de samba Edu 4 - serveur Active Directory"
WELCOME_TEXT="Bienvenue sur l'installation du serveur de fichiers SambaEdu 4.

SambaEdu est un projet libre sous licence GPL vivant de la collaboration active des différents contributeurs issus de différentes académies

Ce programme installera les paquets nécessaires au serveur SE4-FS 

Contact : 
Franck.molle@sambaedu.org : Maintenance de l'installeur"

dialog  --ok-label Ok --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 25 70
#

dialog --backtitle "$BACKTITLE" --title "Installeur de samba Edu 4 - serveur Active Directory" \
--menu "Choisissez l'action à effectuer" 15 90 7  \
"1" "Installation classique" \
"2" "Téléchargement des paquets uniquement (utile pour préparer un modèle de VM)" \
"3" "Configuration du réseau uniquement (en cas de changement d'IP)" \
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
        conf_network
		exit 0
        ;;
        *) exit 0
        ;;
        esac
}

# Fonction test carte réseau
function test_ecard()
{
ECARD=$(/sbin/ifconfig | grep eth | sort | head -n 1 | cut -d " " -f 1)
if [ -z "$ECARD" ]; then
  ECARD=$(/sbin/ifconfig -a | grep eth | sort | head -n 1 | cut -d " " -f 1)

	if [ -z "$ECARD" ]; then
		echo -e "$COLERREUR"
		echo "Aucune carte réseau n'a été détectée."
		echo "Il n'est pas souhaitable de poursuivre l'installation."
		echo -e "$COLTXT"
		echo -e "Voulez-vous ne pas tenir compte de cet avertissement (${COLCHOIX}1${COLTXL}),"
		echo -e "ou préférez-vous interrompre le script d'installation (${COLCHOIX}2${COLTXL})"
		echo -e "et corriger le problème avant de relancer ce script?"
		REPONSE=""
		while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
		do
			echo -e "${COLTXL}Votre choix: [${COLDEFAUT}2${COLTXL}] ${COLSAISIE}\c"
			read REPONSE
	
			if [ -z "$REPONSE" ]; then
				REPONSE=2
			fi
		done
		if [ "$REPONSE" = "2" ]; then
			echo -e "$COLINFO"
			echo "Pour résoudre ce problème, chargez le pilote approprié."
			echo "ou alors complétez le fichier /etc/modules.conf avec une ligne du type:"
			echo "   alias eth0 <nom_du_module>"
			echo -e "Il conviendra ensuite de rebooter pour prendre en compte le changement\nou de charger le module pour cette 'session' par 'modprobe <nom_du_module>"
			echo -e "Vous pourrez relancer ce script via la commande:\n   /var/cache/se3_install/install_se3.sh"
			echo -e "$COLTXT"
			exit 1
		fi
	else
	cp /etc/network/interfaces /etc/network/interfaces.orig
	sed -i "s/eth[0-9]/$ECARD/" /etc/network/interfaces
	ifup $ECARD
	fi

fi
}

# Fonction recupératoin des paramètres via fichier de conf ou tgz
function recup_params() {

if [ -e "/root/$se4ad_config_tgz" ]; then
	tar -xzf /root/$se4ad_config_tgz -C /etc/
elif [ -e "$dir_config/$se4ad_config_tgz" ] ;then
	tar -xzf $dir_config/$se4ad_config_tgz -C $dir_config/
fi

echo -e "$COLINFO"
if [ -e "$se4ad_config" ] ; then
 	echo "$se4ad_config est bien present sur la machine - initialisation des paramètres"
	source $se4ad_config 
	echo -e "$COLTXT"
else
	echo "$se4ad_config ne se trouve pas sur la machine"
	echo -e "$COLTXT"
	se4ad_ip="$(ifconfig eth0 | grep "inet " | awk '{ print $2}')"
fi
}

# Fonction installation des paquets de base
function installbase()
{
echo -e "$COLPARTIE"
echo "Mise à jour des dépots et upgrade si necessaire, quelques mn de patience..."
echo -e "$COLTXT"
# tput reset
apt-get -qq update
apt-get upgrade --quiet --assume-yes

echo -e "$COLPARTIE"
echo "installation ntpdate, vim, etc..."
echo -e "$COLTXT"
prim_packages="ssh ntpdate vim wget nano iputils-ping bind9-host libldap-2.4-2 ldap-utils makepasswd haveged"
apt-get install --quiet --assume-yes $prim_packages
}

# Fonction génération des fichiers /etc/hosts et /etc/hostname
function write_hostconf()
{
cat >/etc/hosts <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4fs_ip	$se4fs_name.$ad_domain	$se4fs_name
END

cat >/etc/hostname <<END
$se4fs_name
END
}

function download_packages() { 
if [ "$download" = "yes" ] || [ ! -e /root/dl_ok ]; then
# 	show_title
# 	test_ecard
	echo -e "$COLINFO"
	echo "Pré-téléchargement des paquets nécessaire à l'installation"
	echo -e "$COLTXT"
	installbase
	gensourcelist
	echo -e "$COLPARTIE"
	echo "Téléchargement de samba 4" 
	echo -e "$COLCMD"

	apt-get install $samba_packages -d -y
	echo -e "$COLCMD"
	echo "Phase de Téléchargement terminée"
	echo -e "$COLTXT"
fi
}

function conf_network {
echo -e "$COLINFO"
echo "Mofification de l'adressage IP"
echo -e "$COLTXT"
gennetwork
service networking restart
echo "Modification Ok" 
echo "Testez la connexion internet avant de relancer le script sans option afin de procéder à l'installation"
exit 0
}


# Fonction installation de samba 4.5 (pour le moment)
function installsamba()
{
echo -e "$COLINFO"
echo "Installation de samba 4.5" 
echo -e "$COLCMD"
apt-get install $samba_packages 
# /etc/init.d/samba stop
# /etc/init.d/smbd stop
# /etc/init.d/nmbd stop
# /etc/init.d/winbind stop
echo -e "$COLTXT"

}

# Fonction génération du fichier /etc/krb5.conf On peut aussi copier celui de /var/lib/samba
function write_krb5()
{
cat > /etc/krb5.conf <<END
[libdefaults]
 dns_lookup_realm = false
 dns_lookup_kdc = true
 default_realm = $ad_domain_up
END
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


# Fonction permettant de se connecter ssh root sur se4-AD
function Permit_ssh_by_password()
{
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

/usr/sbin/service ssh restart
}

# Fonction permettant de fixer le pass admin : Attention complexité requise
function check_pass_admin()
{
TEST_PASS="none"
cpt=1
echo -e "$COLPARTIE"
echo -e "Test de la connexion AD avec le mot de passe du compte Administrator"
while [ "$TEST_PASS" != "OK" ]
do
	
	
	echo -e "$COLCMD"
	echo -e "Entrez le mot de passe du compte Administrator AD pour le test de connexion" 
	echo -e "$COLTXT"
	read -r administrator_pass
	smbclient -L $se4ad_ip -U Administrator%$administrator_pass

	
# 	echo -e "Test de connexion smbclient avec le nouveau mot de passe....\c$COLTXT"
# 	sleep 5
# # 	smbclient -L localhost -U Administrator%"$administrator_pass"  >/tmp/smbclient_cnx
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        let cpt++
		if [ "$cpt" = 3 ];then
			echo -e "3 Tentatives infructueuses - Abandon" 
			echo -e "$COLTXT"
			break
		fi
    else
        TEST_PASS="OK"
        echo -e "$COLINFO"
        echo "Mot de passe Administrator correct :)"
        sleep 1
    fi
    
    
done
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
dir_export="/etc/sambaedu/export_se4ad"
se4ad_config="$dir_export/se4ad.config"
nameserver=$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2)
se3ldif="ldapse3.ldif"
se4ad_config_tgz="se4ad.config.tgz"

echo -e "$COLPARTIE"
echo "Prise en compte des valeurs de $se4ad_config"
echo -e "$COLTXT"

#### Variables suivantes init via Fichier de conf ####
# ip du se4ad --> $se4ad_ip" 
# Nom de domaine samba du SE4-AD --> $smb4_domain" 
# Suffixe du domaine --> $suffix_domain" 
# Nom de domaine complet - realm du SE4-AD --> $ad_domain" 
# Adresse IP de l'annuaire LDAP à migrer en AD --> $se3ip" 
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
		-d|--download)
		download_packages
		exit 0
		
		;;
		
		-n|--network)
		conf_network
		exit 0
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

show_title
recup_params



# A voir pour modifier ou récupérer depuis sambaedu.config 
[ -z "$smb4_domain" ] && smb4_domain="sambaedu4"
[ -z "$suffix_domain" ] && suffix_domain="lan"
ad_domain="$smb4_domain.$suffix_domain" 


smb4_domain_up="$(echo "$smb4_domain" | tr [:lower:] [:upper:])"
suffix_domain_up="$(echo "$suffix_domain" | tr [:lower:] [:upper:])"
ad_domain_up="$(echo "$ad_domain" | tr [:lower:] [:upper:])"
sambadomaine_old="$(echo $se3_domain| tr [:lower:] [:upper:])"
sambadomaine_new="$smb4_domain_up"

download_packages
haveged
ad_admin_pass=$(makepasswd --minchars=8)
go_on

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

reset_smb_ad_conf
installsamba
Permit_ssh_by_password

if [ -e "$dir_export/slapd.conf" ]; then 
	install_slapd
	clean_ldap
	extract_ldifs
	convert_smb_to_ad
	write_krb5
	write_smbconf
	write_resolvconf
	activate_smb_ad
	modif_ldb
	check_smb_ad
	change_pass_admin
	
else
	echo "$dir_export/slapd.conf non trouvé - L'installation se poursuivra sur un nouveau domaine sans import d'anciennes données"
	go_on
	provision_new_ad # Voir partie dns interne
	write_smbconf
	write_resolvconf
	activate_smb_ad
	check_smb_ad
	write_krb5
	
fi

change_policy_passwords

change_pass_root

echo -e "$COLTITRE"
echo "L'installation est terminée. Bonne utilisation de SambaEdu4-AD ! :)"
echo -e "$COLTXT"

# script_absolute_path=$(readlink -f "$0")
# [ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_se4ad_phase2.sh ] && mv /root/install_se4ad_phase2.sh  /root/install_phase2.done
. /etc/profile

unset DEBIAN_FRONTEND
exit 0

