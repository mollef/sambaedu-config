#!/bin/bash
#
##### Permet l'installation et la conf d'un container LXC se4-AD#####
#



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

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLPARTIE="\033[1;34m"  # Bleu

COLTXT="\033[0;37m"     # Gris
COLCHOIX="\033[1;33m"   # Jaune
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert

COLCMD="\033[1;37m"     # Blanc

COLERREUR="\033[1;31m"  # Rouge
COLINFO="\033[0;36m"    # Cyan

function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}

# Poursuivre ou corriger
function poursuivre_ou_corriger()
{
	REPONSE=""
	while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
	do
		if [ ! -z "$1" ]; then
			echo -e "$COLTXT"
			echo -e "Peut-on poursuivre (${COLCHOIX}1${COLTXT}) ou voulez-vous corriger (${COLCHOIX}2${COLTXT}) ? [${COLDEFAUT}${1}${COLTXT}] $COLSAISIE\c"
			read REPONSE

			if [ -z "$REPONSE" ]; then
				REPONSE="$1"
			fi
		else
			echo -e "$COLTXT"
			echo -e "Peut-on poursuivre (${COLCHOIX}1${COLTXT}) ou voulez-vous corriger (${COLCHOIX}2${COLTXT}) ? $COLSAISIE\c"
			read REPONSE
		fi
	done
}

# Poursuivre ou quitter en erreur
function POURSUIVRE()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
                echo -e "$COLTXT"
                echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
                read REPONSE
                if [ -z "$REPONSE" ]; then
                        REPONSE="o"
                fi
        done

        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
                ERREUR "Abandon!"
        fi
}

#Activation Debug
function debug() {
debug="1"
if [ "$debug" = "1" ]; then
set -x
POURSUIVRE
fi

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
sleep 2
}

# Choix du nom de domaine
function ask_for_domain()
{

echo -e "$COLINFO--- Important --- $COLTXT"
echo "Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc primordial"
echo "Le nom de domaine est décomposé en deux parties : le nom de domaine samba suivi de son suffixe"
echo "Exemple pour un domaine AD clg-dupontel-belville.ac-acad.fr" 
echo "le domaine samba sera clg-dupontel-belville et ac-acad.fr sera le suffixe"
echo "Attention : les domaines du type samba.lan ou etab.local sont déconseillés en production par l'équipe samba "
REPONSE="n"
while [ "$REPONSE" != "o" ]
do
ad_domain="$(hostname -d)"
	if [ "$REPONSE" = "n" ]; then
		echo -e "${COLTXT}Saisir votre nom de domaine complet $COLSAISIE [$ad_domain] \c"
		read ad_domain
		[ -z "$ad_domain" ] && ad_domain=$(hostname -d)
	fi

smb4_domain=$(echo "$ad_domain" | cut -d"." -f1)
suffix_domain=$(echo "$ad_domain" | sed -n "s/$smb4_domain\.//p")
	echo -e "$COLINFO"
	echo "Résumé :"
	echo -e "$COLTXT\c"
	echo "Nom de domaine AD saisi	-->  $ad_domain"
	echo "Nom de domaine samba	-->  $smb4_domain"
	echo "Suffixe du domain	-->  $suffix_domain"
	
	
	echo -e "$COLTXT"
	echo -e "Confirmer cette configuration ? (${COLCHOIX}o${COLTXT}/${COLCHOIX}n${COLTXT}) $COLSAISIE\c "
	read REPONSE
done
}

# confirmation de la conf du lan 
function conf_network()
{
show_part "Configuration du réseau local"	
se3network=$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")
se3bcast=$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")
se3gw=$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")


REPONSE=""
while [ "$REPONSE" != "o" ]
do
	if [ "$REPONSE" = "n" ]; then
		echo -e "${COLTXT}Adresse de base du réseau $COLSAISIE\c"
		read se3network
		echo -e "${COLTXT}Adresse de broadcast $COLSAISIE\c"
		read se3bcast
		echo -e "${COLTXT}Adresse de la passerelle $COLSAISIE\c"
		read se3gw
	fi

	echo -e "$COLINFO"
	echo "Configuration réseau actuelle détectée :"
	echo -e "$COLTXT\c"
	echo "Adresse IP du serveur :  $se3ip"
	echo "Adresse réseau de base : $se3network"
	echo "Adresse de Broadcast :   $se3bcast"
	echo "IP de la Passerelle :    $se3gw"
	
	
	echo -e "$COLTXT"
	echo -e "Confirmer cette configuration réseau ? (${COLCHOIX}o${COLTXT}/${COLCHOIX}n${COLTXT}) $COLSAISIE\c "
	read REPONSE
done
}

# Installation package LXC 1.1 backport
function install_lxc_package()
{
show_part "Installation  et configuration de LXC"

echo "Vérification de l'existence des backports dans le sources.list"
url_depot_backport="deb http://ftp.fr.debian.org/debian/ wheezy-backports main"
grep -q "^$url_depot_backport" /etc/apt/sources.list || echo "$url_depot_backpot" >> /etc/apt/sources.list
echo -e "${COLCMD}Mise à jour des dépots....${COLTXT}"
# apt-get autoremove 
apt-get -qq update

echo -e "${COLCMD}installation de LXC version backportée${COLTXT}"
apt-get install bridge-utils
apt-get install -t wheezy-backports lxc

grep -q cgroup /etc/fstab || echo "cgroup  /sys/fs/cgroup  cgroup  defaults  0   0" >> /etc/fstab
mount -a
}

# fonction config du lan
function write_host_lan()
{
echo -e "${COLINFO}Passage de eth0 en br0 pour installer le pont nécessaire à LXC${COLTXT}"
sleep 2
echo
SETMYSQL dhcp_iface $ecard
SETMYSQL ecard $ecard
echo -e "$COLINFO"
echo -e "Modification de $interfaces_file"
echo -e "$COLTXT"

cp $interfaces_file ${interfaces_file}_sav_install_lxc 

cat > /etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto br0
iface br0 inet static
bridge_ports eth0
bridge_fd 0
address $se3ip
netmask $se3mask
network $se3network
broadcast $se3bcast
gateway $se3gw
END

chmod 644 $interfaces_file

# Redémarrage de l'interface réseau
[ -z "$ecard" ] && ecard="br0"
echo -e "$COLCMD\c"
echo -e "Redémarrage de l'interface réseau...\c"
echo -e "$COLTXT"
/etc/init.d/networking stop
/etc/init.d/networking start
echo -e "$COLTXT\c"
ifup $ecard

}

# Fonction de preconfig du container
function preconf_se4ad_lxc()
{

echo -e $COLPARTIE
echo "--------"
echo "Partie 3 : Pré-configuration du container LXC SE4"
echo "--------"
echo -e "$COLTXT"

REPONSE=""
details="no"
while [ "$REPONSE" != "o" ]
do
	echo -e "${COLTXT}IP du container SE4 : $COLSAISIE\c"
	read se4ad_ip

	if [ "$details" != "no" ]; then
		echo -e "${COLTXT}Masque sous réseau: $COLSAISIE\c"
		read se3mask
		echo -e "${COLTXT}Adresse réseau $COLSAISIE\c"
		read se3network
		echo -e "${COLTXT}Adresse de broadcast $COLSAISIE\c"
		read s3bcast
		echo -e "${COLTXT}Adresse de la passerelle $COLSAISIE\c"
		read se3gw
	fi
	details="yes"
	
		
		echo -e "$COLINFO"
		echo "Configuration IP prévue pour le container :"
		echo -e "$COLTXT\c"
		echo "IP :         $se4ad_ip"
		echo "Masque :     $se3mask"
		echo "Réseau :     $se3network"
		echo "Broadcast :  $se3bcast"
		echo "Passerelle : $se3gw"
	
		echo -e "$COLTXT"
		echo -e "Confirmer la configuration pour le container ? (${COLCHOIX}o${COLTXT}/${COLCHOIX}n${COLTXT}) $COLSAISIE\c"
		read REPONSE
done
echo -e "${COLTXT}Nom du container SE4: [se4ad]$COLSAISIE \c"
read se4name
[ -z "$se4name" ] && se4name="se4ad"
POURSUIVRE
echo -e "$COLTXT"
}

# Fonction écriture du fichier de conf LXC
function write_lxc_conf {

show_part "Installation du container $se4name"


if [ -e "usr/share/se3/sbin/lxc_mac_generator" ]; then
	echo -e "$COLINFO"
	echo "Génération de l'adresse MAC de la machine LXC"
	echo -e "$COLTXT"
	se4mac="$(usr/share/se3/sbin/lxc_mac_generator)"
else
	se4mac="00:FF:AA:00:00:01"
	echo -e "$COLINFO"
	echo "Adresse MAC de la machine LXC fixée à $se4mac"
	echo -e "$COLTXT"
fi
cat > /var/lib/lxc/$se4name.config <<END
lxc.network.type = veth
lxc.network.flags = up

# Ceci est l’interface définit plus haut dans le fichier interface de l’hôte :
lxc.network.link = br0
lxc.network.name = eth0
lxc.network.hwaddr = $se4mac
lxc.network.ipv4 = $se4ad_ip

# Définissez la passerelle pour avoir un accès à Internet
lxc.network.ipv4.gateway = $se3gw

END
}

# Fonction installation de la machine LXC se4ad
function install_se4ad_lxc()
{
if [ -e "$dir_config/lxc/template/lxc-debianse4" ]; then
	echo -e "$COLINFO"
	echo "Copie du template $dir_config/lxc/template/lxc-debianse4"
	echo -e "$COLTXT"
	cp -v $dir_config/lxc/template/lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
else
	echo -e "$COLINFO"
	echo "Récupération du template lxc-debianse4"
	echo -e "$COLTXT"
	wget $url_sambaedu_config/lxc/template/lxc-debianse4
	mv lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
fi
chmod +x /usr/share/lxc/templates/lxc-debianse4
if [ ! -e  /usr/share/debootstrap/scripts/stretch ]; then
	echo -e "$COLINFO"
	echo "création de /usr/share/debootstrap/scripts/stretch"
	echo -e "$COLTXT"
	cd /usr/share/debootstrap/scripts/ 
	ln -s sid stretch
	cd -
fi
echo -e "$COLINFO"
echo "Lancement de lxc-create - Patience !!"
echo -e "$COLCMD"
lxc-create -n $se4name -t debianse4 -f /var/lib/lxc/$se4name.config
echo -e "$COLTXT"
}

# fonction ecriture du lan LXC
function write_lxc_lan()
{
interfaces_file_lxc="/var/lib/lxc/$se4name/rootfs/etc/network/interfaces"
echo -e "$COLINFO"
echo "Modification de $interfaces_file_lxc"
echo -e "$COLTXT"
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
netmask $se3mask
network $se3network
broadcast $se3bcast
gateway $se3gw
END

chmod 644 $interfaces_file_lxc

}

# Fonction personalisation .profile 
function write_lxc_profile
{
profile_lxc="/var/lib/lxc/$se4name/rootfs/root/.profile"
echo -e "$COLINFO"
echo "Génération de $profile_lxc"
echo -e "$COLTXT"
echo '# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n' > $profile_lxc
echo "
if [ -f /root/$script_phase2 ]; then
    . /root/$script_phase2  
fi

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
" >> $profile_lxc 
}

# Fonction personalisation .bashrc 
function write_lxc_bashrc
{
lxc_bashrc="/var/lib/lxc/$se4name/rootfs/root/.bashrc"
if [ -e "$dir_config/lxc/bashrc" ]; then
	echo -e "$COLINFO"
	echo "Copie de $dir_config/lxc/bashrc"
	echo -e "$COLCMD"
	cp -v $dir_config/lxc/bashrc $lxc_bashrc
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération du fichier bashrc"
	echo -e "$COLCMD"
	wget $url_sambaedu_config/lxc/bashrc
	mv -v bashrc $lxc_bashrc
	echo -e "$COLTXT"
fi
chmod 644 $lxc_bashrc
}

# Fonction écriture fichier de conf /etc/sambaedu/se4ad.config
function write_sambaedu_conf
{
if [ -e "$se4ad_config" ] ; then
	echo "$se4ad_config existe on en écrase le contenu"
fi
echo -e "$COLINFO"
#echo "Pas de fichier de conf $se4ad_config  -> On en crée un avec les params du se4ad"
echo -e "$COLTXT"
echo "## Adresse IP du futur SE4-AD ##" > $se4ad_config
echo "se4ad_ip=\"$se4ad_ip\"" >> $se4ad_config
echo "## Nom de domaine samba du SE4-AD ##" >> $se4ad_config
echo "smb4_domain=\"$smb4_domain\"" >>  $se4ad_config
echo "## Suffixe du domaine##" >> $se4ad_config
echo "suffix_domain=\"$suffix_domain\"" >>  $se4ad_config
echo "## Nom de domaine complet - realm du SE4-AD ##" >> $se4ad_config
echo "ad_domain=\"$ad_domain\"" >> $se4ad_config
echo "## Adresse IP de SE3 ##" >> $se4ad_config
echo "se3ip=\"$se3ip\"" >> $se4ad_config
echo "## Nom du domaine samba actuel" >> $se4ad_config
echo "se3_domain=\"$se3_domain\""  >> $se4ad_config
echo "##Nom netbios du serveur se3 actuel##" >> $se4ad_config
echo "netbios_name=\"$netbios_name\"" >> $se4ad_config
echo "##Adresse du serveur DNS##" >> $se4ad_config
echo "nameserver=\"$nameserver\"" >> $se4ad_config
echo "##Pass admin LDAP##" >> $se4ad_config
echo "adminPw=\"$adminPw\"" >> $se4ad_config
echo "##base dn LDAP##" >> $se4ad_config
echo "ldap_base_dn=\"$ldap_base_dn\"" >> $se4ad_config
echo "##Rdn admin LDAP##" >> $se4ad_config
echo "adminRdn=\"$adminRdn\"" >> $se4ad_config
echo "SID domaine actuel" >> $se4ad_config
echo "domainsid=\"$domainsid\"" >> $se4ad_config

chmod +x $se4ad_config
}

# Fonction export des fichiers tdb et smb.conf 
function export_smb_files()
{
echo -e "$COLINFO"
echo "Coupure du service Samba pour export des fichiers TDB"
echo -e "$COLTXT"
service samba stop
smb_dbdir_export="/etc/sambaedu/smb_export"
mkdir -p "$smb_dbdir_export"
echo -e "$COLINFO"
echo "Copie des fichiers TDB vers $smb_dbdir_export"
echo -e "$COLCMD"
tdb_smb_dir="/var/lib/samba"
pv_tdb_smb_dir="/var/lib/samba/private"
cp $pv_tdb_smb_dir/secrets.tdb $smb_dbdir_export/
cp $pv_tdb_smb_dir/schannel_store.tdb $smb_dbdir_export/
cp $pv_tdb_smb_dir/passdb.tdb $smb_dbdir_export/

cp $tdb_smb_dir/gencache_notrans.tdb $smb_dbdir_export/
cp $tdb_smb_dir/group_mapping.tdb $smb_dbdir_export/
cp $tdb_smb_dir/account_policy.tdb $smb_dbdir_export/

cp /etc/samba/smb.conf $dir_config/
}

# Fonction export des fichiers ldap 
function export_ldap_files()
{
conf_slapd="/etc/ldap/slapd.conf"
echo -e "$COLINFO"
echo "Export de la conf ldap et de ldapse3.ldif vers $dir_config"
echo -e "$COLTXT"
cp -v $conf_slapd $dir_config/
ldapsearch -xLLL -D "$adminRdn,$ldap_base_dn" -w $adminPw > $dir_config/ldapse3.ldif
schema_dir="/etc/ldap/schema"
cp -v $schema_dir/ltsp.schema $schema_dir/samba.schema $schema_dir/printer.schema $dir_config/
cp -v /var/lib/ldap/DB_CONFIG $dir_config/
cp -v /etc/ldap/slapd.pem $dir_config/

}

# Fonction copie des fichiers de conf @LXC/etc/sambaedu
function cp_config_to_lxc()
{
dir_config_lxc="/var/lib/lxc/$se4name/rootfs/etc"
# mkdir -p $dir_config_lxc
echo "copie de $dir_config sur la machine LXC"
echo -e "$COLCMD"
cp -av  $dir_config $dir_config_lxc/
echo -e "$COLTXT"
}

# Fonction copie install_phase2 @LXC  
function write_se4ad_install
{
dir_root_lxc="/var/lib/lxc/$se4name/rootfs/root"
if [ -e "$dir_config/lxc/$script_phase2" ]; then
	echo -e "$COLINFO"
	echo "Copie de $dir_config/lxc/$script_phase2"
	echo -e "$COLCMD"
	cp -v $dir_config/lxc/$script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération de $script_phase2"
	echo -e "$COLCMD"
	wget $url_sambaedu_config/lxc/$script_phase2
	mv -v $script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
fi
chmod +x $dir_root_lxc/$script_phase2
}

# Fonction génération des fichiers hosts @ LXC
function write_lxc_hosts_conf()
{
lxc_hosts_file="/var/lib/lxc/$se4name/rootfs/etc/hosts"
echo -e "$COLINFO"
echo "Génération de $lxc_hosts_file"
echo -e "$COLTXT"

cat >$lxc_hosts_file <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4ad_ip	se4ad.$ad_domain	se4ad
END

lxc_hostname_file="/var/lib/lxc/$se4name/rootfs/etc/hosts"
echo -e "$COLINFO"
echo "Génération de $lxc_hostname_file"
echo -e "$COLTXT"

cat >$lxc_hostname_file <<END
se4ad
END
}

function display_end_message() {
echo -e "/!\ notez bien le mot de passe root du container  --->$COLINFO se4ad $COLTXT
Il vous sera indispensable pour le premier lancement"

echo -e "$COLTXT"
# echo "Appuyez sur ENTREE "

# echo "Un nouveau script d'installation se lancera sur le container une fois que vous serez connecté root"
echo -e "$COLTITRE"
echo "Terminé!"
echo "--------"
echo -e "$COLTXT"
echo -e "${COLINFO}Container $se4name installé. Pour lancer la machine, utiliser la commande suivante :$COLCMD
lxc-start -n $se4name"
echo -e "${COLTXT}L'installation se poursuivra ensuite une fois identifié root
/!\ Mot de passe root --->$COLINFO se4ad $COLTXT"
echo "--------"
echo -e "$COLINFO" 
echo "Les valeurs utiles à la configuration du se4 seront les suivantes"
echo -e "$COLCMD"
cat $se4ad_config
echo -e "$COLTXT"
}

clear
echo -e "$COLTITRE"
usage
echo -e "$COLINFO"
echo "Appuyez sur Entree pour continuer..."

echo -e "$COLTXT"
read

show_part "Recupération des données depuis la BDD et initialisation des variables"

## recuperation des variables necessaires pour interoger mysql ###
source /etc/se3/config_m.cache.sh
source /etc/se3/config_l.cache.sh
source /usr/share/se3/includes/functions.inc.sh 

# Variables :
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/se4/master/sources/sambaedu-config"
interfaces_file="/etc/network/interfaces" 
dir_config="/etc/sambaedu"
se4ad_config="$dir_config/se4ad.config"
script_phase2="install_se4ad_phase2.sh"
lxc_arch="$(arch)"
ecard="br0"
nameserver=$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2)


ask_for_domain
conf_network
install_lxc_package
write_host_lan
preconf_se4ad_lxc
write_lxc_conf
install_se4ad_lxc
show_part "Post-installation du container : Mise en place des fichiers nécessaires à la phase 2 de l'installation"
write_lxc_lan
write_lxc_profile
write_lxc_bashrc
export_smb_files
write_sambaedu_conf
export_ldap_files
cp_config_to_lxc
write_se4ad_install
write_lxc_hosts_conf
display_end_message


# echo "Appuyez sur ENTREE "
exit 0


