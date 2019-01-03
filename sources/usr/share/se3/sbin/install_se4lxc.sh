#!/bin/bash
# Projet SambaEdu - distribué selon la licence GPL
##### Permet l'installation et la conf d'un container LXC se4-AD#####
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
# write_se4ad_config  Fonction écriture fichier de conf /etc/sambaedu/se4ad.config et se4fs
# write_se4fs_config
# Fonction export des fichiers tdb et smb.conf --> export_smb_files()
# Fonction export des fichiers --> dhcp export_dhcp()
# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif --> export_ldap_files()
# Fonction export des fichiers  sql --> export_sql_files()
# Fonction export des fichiers   --> export_cups_config()
# Recherche de sid en doublon  --> search_duplicate_sid()

function usage() 
{
echo "Script intéractif permettant l'installation et la configuration d'un container LXC se4-AD"
}

if [ "$1" = "--help" -o "$1" = "-h" ]
then
	usage
	echo "Usage : pas d'option"
	exit
fi

function show_title() {
BACKTITLE="Projet Sambaédu - https://www.sambaedu.org/"

WELCOME_TITLE="Installeur de container LXC pour SE4-AD"
WELCOME_TEXT="Bienvenue dans l'installation du container LXC SE4 Active directory.

SambaEdu est un projet libre sous licence GPL vivant de la collaboration active des différents contributeurs issus de différentes académies

Ce programme installera un container LXC Debian Stretch et y déposera tous les fichiers d'export nécessaires à la migration vers AD.

Une fois la machine LXC installée, il suffira de la démarrer afin de poursuivre son installation et sa configuration de façon automatique."

$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 20 70
}

# Installation package LXC 1.1 backport
function install_lxc_package()
{
show_part "Installation  et configuration de LXC"

# echo "Vérification de l'existence des backports dans le sources.list"
url_depot_backport="deb http://ftp.fr.debian.org/debian/ wheezy-backports main"
grep -q "^$url_depot_backport" /etc/apt/sources.list || echo "$url_depot_backport" >> /etc/apt/sources.list
show_info "Mise à jour des dépots...."
# apt-get autoremove 
apt-get -q update

show_info "Installation de LXC version backportée"
echo -e "${COLCMD}"
apt-get install bridge-utils
apt-get install -t wheezy-backports lxc
echo -e "${COLTXT}"
grep -q cgroup /etc/fstab || echo "cgroup  /sys/fs/cgroup  cgroup  defaults  0   0" >> /etc/fstab
mount -a
sleep 3
}

# fonction config du lan
function write_host_lan()
{
if [ ! -e "${interfaces_file}_sav_install_lxc" ]; then
    show_info "Passage de eth0 en br0 pour installer le pont nécessaire à LXC"
    sleep 2
    echo
    SETMYSQL dhcp_iface $bcard
    SETMYSQL ecard $bcard
    show_info "Modification de $interfaces_file"
        cp -v $interfaces_file ${interfaces_file}_sav_install_lxc 

    cat > /etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto br0
iface br0 inet static
bridge_ports $ecard
bridge_fd 0
address $se3ip
netmask $se3mask
network $se3network
broadcast $se3bcast
gateway $se3gw
END

    chmod 644 $interfaces_file

    # Redémarrage de l'interface réseau
    [ -z "$bcard" ] && bcard="br0"
    show_info "Redémarrage de l'interface réseau..."
    echo -e "$COLCMD"
    /etc/init.d/networking stop
    /etc/init.d/networking start
    echo -e "$COLTXT\c"
    ifup $bcard
fi
}

# Fonction de preconfig du container --> move to libs-common.sh
function preconf_se4ad_lxc()
{
se4ad_lxc_lan_title="Configuration réseau du container LXC SE4"

REPONSE=""
details="no"
se4ad_ip="$(echo "$se3ip"  | cut -d . -f1-3)."
se4mask="$se3mask"
se4network="$se3network"
se4bcast="$se3bcast"
se4gw="$se3gw"
while [ "$REPONSE" != "yes" ]
do
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'IP du container SE4" 15 70 $se4ad_ip 2>$tempfile || erreur "Annulation"
	se4ad_ip=$(cat $tempfile)
	
	if [ "$details" != "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir le Masque sous réseau" 15 70 $se3mask 2>$tempfile || erreur "Annulation"
		se4mask=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 15 70 $se3network 2>$tempfile || erreur "Annulation"
		se4network=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de broadcast" 15 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se4bcast=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 15 70 $se3gw 2>$tempfile || erreur "Annulation"
		se4gw=$(cat $tempfile)
	fi
	details="yes"
	
	se4ad_lxc_name_title="Nom du container SE4"
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_name_title" --inputbox "Saisir le Nom du container SE4" 15 70 se4ad 2>$tempfile || erreur "Annulation"
	se4name=$(cat $tempfile)
	
	choice_domain_title="Important - nom de domaine AD"
	choice_domain_text="Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc important.
Il est décomposé en deux parties : le nom de domaine samba suivi de son suffixe, séparés par un point.

Exemple de domaine AD : clg-dupontel.belville.ac-dijon.fr 
* le domaine samba sera clg-dupontel 
* le suffixe sera belville.ac-acad.fr 

Note : 
* le domaine samba ne doit en aucun cas dépasser 15 caractères
* Les domaines du type sambaedu.lan ou etab.local sont déconseillés en production par l'équipe samba"

	domain="$(hostname -d)"
	$dialog_box --backtitle "$BACKTITLE" --title "$choice_domain_title" --inputbox "$choice_domain_text" 20 80 $domain 2>$tempfile
	domain="$(cat $tempfile)"		
	samba_domain=$(echo "$domain" | cut -d"." -f1)
	suffix_domain=$(echo "$domain" | sed -n "s/$samba_domain\.//p")
	
	confirm_title="Récapitulatif de la configuration prévue"
	confirm_txt="IP :         $se4ad_ip
Masque :     $se4ad_mask
Réseau :     $se4ad_network
Broadcast :  $se4ad_bcast
Passerelle : $se4ad_gw

Nom :        $se4ad_name

Nom de domaine AD saisi : $domain
Nom de domaine samba :    $samba_domain

Confirmer l'enregistrement de cette configuration ?"
		
		if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 20 60) then
			REPONSE="yes"
		else
			REPONSE="no"
		fi	
done

#~ poursuivre
echo -e "$COLTXT"
}

# Fonction écriture du fichier de conf LXC
function write_lxc_conf {

show_part "Installation du container $se4ad_name"


if [ -e "usr/share/se3/sbin/lxc-mac-generator" ]; then
	show_info "Génération de l'adresse MAC de la machine LXC"
	se4mac="$(usr/share/se3/sbin/lxc-mac-generator)"
else
	se4mac="00:FF:AA:00:00:01"
	show_info "Adresse MAC de la machine LXC fixée à $se4mac"
fi
cat > /var/lib/lxc/$se4ad_name.config <<END
lxc.network.type = veth
lxc.network.flags = up

# Ceci est l’interface définit plus haut dans le fichier interface de l’hôte :
lxc.network.link = br0
lxc.network.name = eth0
lxc.network.hwaddr = $se4mac
lxc.network.ipv4 = $se4ad_ip

# Définissez la passerelle pour avoir un accès à Internet
lxc.network.ipv4.gateway = $se4ad_gw

# demarrage auto
lxc.start.auto = 1
lxc.start.delay = 5
END
}

# Fonction installation de la machine LXC se4ad
function install_se4ad_lxc()
{
show_part "Installation de la machine LXC se4ad"
if [ -e "$dir_config/lxc/template/lxc-debianse4" ]; then
	show_info "Copie du template $dir_config/lxc/template/lxc-debianse4"
	cp -v $dir_config/lxc/template/lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
else
	show_info "Récupération du template lxc-debianse4"
	wget -nv $url_sambaedu_config/etc/sambaedu/lxc/template/lxc-debianse4
	mv lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
fi
chmod +x /usr/share/lxc/templates/lxc-debianse4
if [ ! -e  /usr/share/debootstrap/scripts/stretch ]; then
	show_info "création de /usr/share/debootstrap/scripts/stretch"
	cd /usr/share/debootstrap/scripts/ 
	ln -s sid stretch
	cd - >/dev/null
fi
if lxc-ls | grep -q $se4ad_name
then
    show_info "$se4ad_name existe déjà...suppression du container"
#     lxc-stop -k -n $se4ad_name
    lxc-destroy -f -n $se4ad_name
fi

show_info "Lancement de lxc-create - Patience !!"
echo -e "$COLCMD"
lxc-create -n $se4ad_name -t debianse4 -f /var/lib/lxc/$se4ad_name.config
echo -e "$COLTXT"
}

# fonction ecriture du lan LXC
function write_lxc_lan()
{
interfaces_file_lxc="/var/lib/lxc/$se4ad_name/rootfs/etc/network/interfaces"
show_info "Modification de $interfaces_file_lxc"
cat > $interfaces_file_lxc <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto eth0
iface eth0 inet static
address $se4ad_ip
netmask $se4ad_mask
network $se4ad_network
broadcast $se4ad_bcast
gateway $se4ad_gw
END

chmod 644 $interfaces_file_lxc

}

 
# Fonction personalisation .profile 
function write_lxc_profile
{
lxc_profile="/var/lib/lxc/$se4ad_name/rootfs/root/.profile"

if [ -e "$dir_preseed/.profile" ]; then
    show_info "Copie du .profile sur le container"
    echo -e "$COLCMD"
    cp -v $dir_preseed/.profile $lxc_profile
    echo -e "$COLTXT"
else
    show_info "Récupération du fichier bashrc"
    echo -e "$COLCMD"
    wget -nv $url_sambaedu_config/var/www/install/.profile
    mv -v profile $lxc_profile
    echo -e "$COLTXT"
fi
}

# Fonction personalisation .bashrc 
function write_lxc_bashrc
{
lxc_bashrc="/var/lib/lxc/$se4ad_name/rootfs/root/.bashrc"
if [ -e "$dir_preseed/.bashrc" ]; then
	show_info "Copie de .bashrc"
	echo -e "$COLCMD"
	cp -v $dir_preseed/.bashrc $lxc_bashrc
	echo -e "$COLTXT"
else
	show_info "Récupération du fichier bashrc"
	echo -e "$COLCMD"
	wget -nv $url_sambaedu_config/etc/sambaedu/.bashrc
	mv -v bashrc $lxc_bashrc
	echo -e "$COLTXT"
fi
chmod 644 $lxc_bashrc
}

# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif
function export_ldap_files()
{
conf_slapd="/etc/ldap/slapd.conf"
show_info "Export de la conf ldap et de ldapse3.ldif vers $dir_export"
echo -e "$COLCMD"
cp -v $conf_slapd $dir_export/
ldapsearch -xLLL -D "$adminRdn,$ldap_base_dn" -w $adminPw > $dir_export/ldapse3.ldif
schema_dir="/etc/ldap/schema"
cp -v $schema_dir/ltsp.schema $schema_dir/samba.schema $schema_dir/printer.schema $dir_export/
cp -v /var/lib/ldap/DB_CONFIG $dir_export/
cp -v /etc/ldap/slapd.pem $dir_export/
}

# Fonction copie des fichiers de conf @LXC/etc/sambaedu
function cp_config_to_lxc()
{
dir_config_lxc="/var/lib/lxc/$se4ad_name/rootfs/etc/sambaedu"
mkdir -p $dir_config_lxc
echo "Création de l'archive $se4ad_config_tgz d'export des données et copie sur la machine LXC"
cd $dir_config
echo -e "$COLCMD"
tar -czf $se4ad_config_tgz export_se4ad
cp -v $se4ad_config_tgz $dir_config_lxc/
# echo "copie de $se4ad_config_tgz sur la machine LXC"
# 
# cp -av  $se4ad_config_tgz $dir_config_lxc/
cd - >/dev/null
echo -e "$COLTXT"
sleep 2
}

function cp_timezone_to_lxc()
{
show_info "Copie du fichier timezone sur la machine LXC"
timezone_file_lxc="/var/lib/lxc/$se4ad_name/rootfs/etc/timezone"
cp /etc/timezone $timezone_file_lxc
}

function patch_config_to_lxc()
{
config_file_lxc="/var/lib/lxc/$se4ad_name/config"
show_info "Modification du fichier $config_file_lxc pour démarrage automatique du container"
cat >>$config_file_lxc <<END
# demarrage auto
lxc.start.auto = 1
lxc.start.delay = 5
END
}

# Fonction copie install_phase2 @LXC  
function write_se4ad_install
{
dir_root_lxc="/var/lib/lxc/$se4ad_name/rootfs/root"
if [ -e "$dir_preseed/$script_phase2" ]; then
	show_info "Copie de $script_phase2"
	echo -e "$COLCMD"
	cp -v $dir_preseed/$script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
else
	show_info "Récupération de $script_phase2"
	echo -e "$COLCMD"
	wget -nv $url_sambaedu_config/var/www/install/se4ad/$script_phase2
	mv $script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
fi
chmod +x $dir_root_lxc/$script_phase2
}

# copie des clés ssh présente sur le serveur principal sur le container
function write_ssh_keys
{
ssh_keys_host="/root/.ssh/authorized_keys"
ssh_keys_lxc_path="/var/lib/lxc/$se4ad_name/rootfs/root/.ssh"
if [ -e "$ssh_keys_host" ];then
	show_info "Copie du fichier des clés SSH $ssh_keys_host"
	mkdir -p "$ssh_keys_lxc_path"
	echo -e "$COLCMD"
	cp -v "$ssh_keys_host" "$ssh_keys_lxc_path/"
	
fi

}

# Fonction génération des fichiers hosts @ LXC
function write_lxc_hosts_conf()
{
lxc_hosts_file="/var/lib/lxc/$se4ad_name/rootfs/etc/hosts"
show_info "Génération de $lxc_hosts_file"
echo -e "$COLTXT"

cat >$lxc_hosts_file <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4ad_ip	se4ad.$domain	se4ad
END

lxc_hostname_file="/var/lib/lxc/$se4ad_name/rootfs/etc/hosts"
show_info "Génération de $lxc_hostname_file"
echo -e "$COLTXT"

cat >$lxc_hostname_file <<END
se4ad
END
}

# Lancement du container en arrière plan
function launch_se4ad() {
show_part "Lancement de $se4ad_name en arrière plan"
echo -e "$COLCMD"
lxc-start -d -n $se4ad_name 
if [ "$?" != "0" ]; then
	echo -e "$COLERREUR"
	echo "Attention "
	echo -e "Erreur lors du lancement de $se4ad_name !"
	echo -e "$COLTXT"
	echo "Appuyez sur entrée pour continuer"
else
	show_info "$se4ad_name Lancée avec succès !!"
	sleep 3
fi
}

# Affichage message de fin
function display_end_message() {
display_end_title="Container $se4ad_name installé"	
	
display_end_txt="Installation terminée !!

Les différents paramètres sont consultables dans $se4ad_config 

La machine LXC a été lancée en arrière plan. 

Afin de poursuivre l'installation, il vous suffit de vous y connecter avec la commande
lxc-console -n $se4ad_name 
/!\ Mot de passe root : \"se4ad\"

Une fois connecté root, un nouveau script d'installation se lancera sur le container afin de finaliser sa configuration"

$dialog_box --backtitle "$BACKTITLE" --title "$display_end_title" --msgbox "$display_end_txt" 20 70


echo -e "$COLTITRE"
echo "L'installation de $se4ad_name est terminée.
Pour se connecter : 
lxc-console -n $se4ad_name 
/!\ Mot de passe root : \"se4ad\""
echo -e "$COLTXT"
}
clear

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
bcard="br0"
nameserver="$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2| head -n 1)"
se4ad_config_tgz="se4ad.config.tgz"
# preseed_se4fs="yes"


show_title
show_part "Recupération des données depuis la BDD et initialisation des variables"
check_whiptail
search_duplicate_sid
settime
conf_network
install_lxc_package
write_host_lan
preconf_se4ad lxc
write_lxc_conf
install_se4ad_lxc
show_part "Post-installation du container : Mise en place des fichiers nécessaires à la phase 2 de l'installation"
write_lxc_lan
write_lxc_profile
write_lxc_bashrc
export_smb_files
write_se4ad_config
export_ldap_files
cp_config_to_lxc
cp_timezone_to_lxc
patch_config_to_lxc
write_se4ad_install
write_lxc_hosts_conf
write_ssh_keys
launch_se4ad
display_end_message
# echo "Appuyez sur ENTREE "
exit 0
