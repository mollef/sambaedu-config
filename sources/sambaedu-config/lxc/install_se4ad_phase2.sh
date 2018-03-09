#!/bin/bash
# installation Se4-AD phase 2
# version pour Stretch - franck molle
# version 12 - 2017 

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m"     # Gris
COLINFO="\033[0;36m"	# Cyan
COLPARTIE="\033[1;34m"	# Bleu

# # Fonction permettant de quitter en cas d'erreur 
function erreur()
{
	echo -e "$COLERREUR"
	echo "ERREUR!"
	echo -e "$1"
	echo -e "$COLTXT"
	exit 1
}

# Fonction permettant de poser la question s'il faut poursuivre ou quitter
function poursuivre()
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
                erreur "Abandon!"
        fi
}

# Fonction de verification de succes
function verif()
{
if [ "$?" != "0" ]; then
	echo -e "$COLERREUR"
	echo "Attention "
	echo -e "la dernière commande a envoyé une erreur !"
	echo -e "$COLTXT"
	poursuivre
fi
}


# Fonction génération du sources.list stretch FR
function gensourcelist()
{
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ stretch main non-free contrib

# Security Updates:
deb http://security.debian.org/ stretch/updates main contrib non-free

# stretch-updates
deb http://ftp.fr.debian.org/debian/ stretch-updates main contrib non-free

# stretch-backports
#deb http://ftp.fr.debian.org/debian/ stretch-backports main


END
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

poursuivre

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

# Fonction Affichage du titre
function show_title()
{

clear

echo -e "$COLTITRE"
echo "--------------------------------------------------------------------------------"
echo "L'installeur est maintenant sur le point de configurer SambaEdu4-AD."
echo "--------------------------------------------------------------------------------"
echo -e "$COLTXT"
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
		echo -e "Voulez-vous ne pas tenir compte de cet avertissement (${COLCHOIX}1${COLTXT}),"
		echo -e "ou préférez-vous interrompre le script d'installation (${COLCHOIX}2${COLTXT})"
		echo -e "et corriger le problème avant de relancer ce script?"
		REPONSE=""
		while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
		do
			echo -e "${COLTXT}Votre choix: [${COLDEFAUT}2${COLTXT}] ${COLSAISIE}\c"
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
prim_packages="ntpdate vim wget nano iputils-ping bind9-host libldap-2.4-2 ldap-utils makepasswd haveged"
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
$se4ad_ip	se4ad.$ad_domain	se4ad
END

cat >/etc/hostname <<END
se4ad
END
}

# Fonction installation et config de slapd afin d'importer l'ancien SE3 ldap
function install_slapd()
{
echo -e "$COLINFO"
echo "Installation et configuration du backend slapd pour récupération des anciennes données" 
echo -e "$COLCMD"
apt-get install --assume-yes slapd ldb-tools
echo -e "$COLINFO"
echo "configuration et import de l'annuaire" 
echo -e "$COLCMD"
/etc/init.d/slapd stop
echo -e "$COLTXT"

cat > /etc/default/slapd <<END
SLAPD_CONF="/etc/ldap/slapd.conf"
SLAPD_USER="openldap"
SLAPD_GROUP="openldap"
SLAPD_PIDFILE=
SLAPD_SERVICES="ldap:/// ldapi:///"
SLAPD_SENTINEL_FILE=/etc/ldap/noslapd
SLAPD_OPTIONS=""
END

cat > /etc/ldap/ldap.conf <<END
HOST $se4ad_ip
BASE $ldap_base_dn
END

cat > /etc/ldap.secret <<END
$adminPw
END

rm /etc/ldap/slapd.d -rf
cp $dir_config/slapd.conf $dir_config/slapd.pem /etc/ldap/
sed '/^include \/etc\/ldap\/syncrepl.conf/d' -i /etc/ldap/slapd.conf 
sed "s/$sambadomaine_old/$sambadomaine_new/" -i $dir_config/$se3ldif

cp $dir_config/*.schema  /etc/ldap/schema/
# nettoyage au besoin
rm -f /var/lib/ldap/* 
cp $dir_config/DB_CONFIG  /var/lib/ldap/
slapadd -l $dir_config/$se3ldif
verif
chown -R openldap:openldap /var/lib/ldap/
chown -R openldap:openldap /etc/ldap

echo -e "$COLINFO"
echo "Lancement de slapd" 
echo -e "$COLCMD"
/etc/init.d/slapd start
verif
echo -e "$COLTXT"
}

# Nettoyage comptes machines en erreurs et root
function clean_ldap()
{
ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn uid=*\$ uid | sed -n "s/^uid: //p" | while read uid_computers
do
	uidnumberEntry="$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn "uid=$uid_computers" uidNumber  | grep uidNumber)"
	if [ -z "$uidnumberEntry" ];then
		echo -e "$COLINFO"
		echo -e "Suppression de l'entrée invalide uid=$uid_computers,ou=Computers,$ldap_base_dn"
		echo -e "$COLCMD"
		ldapdelete -x -D "$adminRdn,$ldap_base_dn" -w "$adminPw" "uid=$uid_computers,ou=Computers,$ldap_base_dn"
		sleep 2
		echo -e "$COLTXT"
	fi
	
#	number_attributes="$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn "uid=$uid_computers" | wc -l)"
	
done
echo -e "$COLINFO"
echo -e "Suppression du compte root samba obsolète"
echo -e "$COLCMD"
ldapdelete -x -D "$adminRdn,$ldap_base_dn" -w "$adminPw" "uid=root,ou=People,$ldap_base_dn"
# A voir pour adaptation surppression groupe root
#ldapdelete -x -D "$ADMINRDN,$BASEDN" -w "$ADMINPW" "cn=root,$GROUPSRDN,$BASEDN"
echo -e "$COLTXT"
}

# Fonction génération des ldifs de l'ancien annuaire se3 avec adaptation de la structure pour conformité AD
function extract_ldifs()
{
rm -f $dir_config/ad_rights.ldif
ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b ou=Rights,$ldap_base_dn cn | sed -n 's/^cn: //p' | while read cn_rights
do
	
cat >> $dir_config/ad_rights.ldif <<END	
dn: CN=$cn_rights,OU=Rights,$ad_base_dn
objectClass: group
objectClass: top
member: CN=Administrator,CN=Users,$ad_base_dn
END
ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b cn=$cn_rights,ou=Rights,$ldap_base_dn member | sed -n 's/member: uid=//p' | cut -d "," -f1 | grep -v "^admin" | while read member_rights
	do
		echo "member: CN=$member_rights,CN=Users,$ad_base_dn" >> $dir_config/ad_rights.ldif
	done
	
ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b cn=$cn_rights,ou=Rights,$ldap_base_dn member | sed -n 's/member: cn=//p' | cut -d "," -f1 | while read member_rights
	do
		echo "member: CN=$member_rights,OU=Groups,$ad_base_dn" >> $dir_config/ad_rights.ldif
	done
echo ""	>> $dir_config/ad_rights.ldif
done

if [ -n "$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn| sed -n 's/^cn: //p')" ]; then
	rm -f $dir_config/ad_parcs.ldif
	ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn| sed -n 's/^cn: //p' | while read cn_parcs
	do
	cat >> $dir_config/ad_parcs.ldif <<END	
dn: CN=$cn_parcs,OU=Parcs,$ad_base_dn
objectClass: group
objectClass: top
END
	if [ -n "$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn=$cn_parcs | sed -n 's/member: cn=//p')"  ]; then
		ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn=$cn_parcs | sed -n 's/member: cn=//p'  | cut -d "," -f1 | while read member_parcs
		do
			if [ -n "$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn uid="$member_parcs"$ dn)" ]; then 
				echo "member: CN=$member_parcs,CN=Computers,$ad_base_dn" >> $dir_config/ad_parcs.ldif
			fi
		done
	fi
	echo "" >>  $dir_config/ad_parcs.ldif
	done
	
fi
rm -f $dir_config/ad_computers.ldif
ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn uid=*\$ uid | sed -n "s/^uid: //p"| sed -e 's/\$//g' | while read cn_computers
do
	ipHostNumber="$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn "cn=$cn_computers" ipHostNumber | sed -n "s/ipHostNumber: //p")"
	macAddress="$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Computers,$ldap_base_dn "cn=$cn_computers" macAddress | sed -n "s/macAddress: //p")"
	if [ -n "$ipHostNumber" -a   -n "$macAddress" ];then
		cat >>  $dir_config/ad_computers.ldif <<END	
dn: CN=$cn_computers,cn=Computers,$ad_base_dn
changetype: modify
add: ipHostNumber
ipHostNumber: $ipHostNumber
-
add: networkAddress
networkAddress: $macAddress

END
	fi 
	# ajouter lecture cn=
done

}

# Fonction installation de samba 4.5 (pour le moment)
function installsamba()
{
echo -e "$COLINFO"
echo "Installation de samba 4.5" 
echo -e "$COLCMD"
apt-get install $samba_packages 
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

# Fonction conversion domaine se3 ldap vers AD
function convert_smb_to_ad()
{
if [ -e "$dir_config/smb.conf" ]; then
	rm -f /etc/samba/smb.conf
	rm -f /var/lib/samba/private/*.tdb

	echo -e "$COLINFO"
	echo "Lancement de la migration du domaine NT4 vers Samba AD avec sambatool" 
	echo -e "$COLCMD"
	sed "s/$netbios_name/se4ad/" -i $dir_config/smb.conf
	sed "s/$sambadomaine_old/$sambadomaine_new/" -i $dir_config/smb.conf
	sed "s#passdb backend.*#passdb backend = ldapsam:ldap://$se4ad_ip#" -i $dir_config/smb.conf  
	echo "samba-tool domain classicupgrade --dbdir=$db_dir --use-xattrs=yes --realm=$ad_domain_up --dns-backend=SAMBA_INTERNAL $dir_config/smb.conf"
	samba-tool domain classicupgrade --dbdir=$db_dir --use-xattrs=yes --realm=$ad_domain_up --dns-backend=SAMBA_INTERNAL $dir_config/smb.conf
	if [ "$?" != "0" ]; then
		erreur "Une erreur s'est produite lors de la migration de l'annaire avec samba-tool. Reglez le probleme et relancez le script" 
	else
		echo -e "$COLINFO"
		echo "Migration de l'annuaire vers samba AD Ok !! On peut couper le service slapd" 
		echo -e "$COLCMD"
		/etc/init.d/slapd stop
		echo -e "$COLTXT"
	fi
else
	erreur "$dir_config/smb.conf ne semble pas présent. Il est indispensable pour la migration des données. Reglez le probleme et relancez le script"
fi
}	
	
# Fonction provision d'un nouvel AD - cas new installation
function provision_new_ad()	
{
echo -e "$COLINFO"
echo "$db_dir/smb.conf Manquant - Lancement d'une nouvelle installation de Samba AD avec sambatool" 
samba-tool domain provision --realm=$ad_domain_up --domain $smb4_domain_up --adminpass $ad_admin_pass  
echo -e "$COLCMD"
}

# Fonction activation samba ad-dc
function activate_smb_ad()
{
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
# systemctl disable samba winbind nmbd smbd
systemctl mask samba winbind nmbd smbd

echo -e "$COLINFO"
echo "En avant la musique :) - lancement de Samba AD-DC"
echo -e "$COLCMD"
/etc/init.d/samba-ad-dc start
echo -e "$COLTXT"
}

# Fonction permettant de fixer le pass admin : Attention complexité requise
function change_pass_admin()
{
TEST_PASS="none"
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte Administrator AD (remplaçant de admin sur se3) $COLTXT"
echo -e "---- /!\ Attention /!\ ----"
echo -e "le mot de passe doit contenir au moins 8 caractères tout en mélangeant lettres / chiffres, au moins une Majuscule et un caractère spécial ! $COLTXT"
read -r administrator_pass
printf '%s\n%s\n' "$administrator_pass" "$administrator_pass"|(/usr/bin/smbpasswd -s Administrator)
smbclient -L localhost -U Administrator%"$administrator_pass" >/dev/null 

    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte ou ne respecte pas les critères de sécurité demandés"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe Administrator changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"
}

# Fonction permettant l'ajout d'une OU ds l'annuaire AD
function ldbadd_ou()
{
local dn_add=$1
local rdn_add=$2
local desc_add=$3
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
dn: $dn_add
changetype: add
objectClass: organizationalUnit
objectClass: top
instanceType: 4
OU: $rdn_add
description: $desc_add
EOF
}

# Fonction permettant le déplacement d'un groupe ds l'annuaire AD
function ldbmv_grp()
{
local dn_mv=$1
local rdn_mv=$2
local target_dn_mv=$3

ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
dn: $dn_mv
changetype: moddn
newrdn: $rdn_mv
deleteoldrdn: 1
newsuperior: $target_dn_mv
EOF
}

# Fonction permettant l'ajout des parties spécifiques à SE4 avec récup des données de l'ancien SE3 ds l'annuaire AD
function modif_ldb()
{
echo -e "$COLINFO"
echo "Ajout des branches de l'annuaire propres à SE4"
echo -e "$COLCMD"
ldbadd_ou "OU=Rights,$ad_base_dn" "Groups" "Branche des droits"
ldbadd_ou "OU=Groups,$ad_base_dn" "Groups" "Branche des groupes"
ldbadd_ou "OU=Trash,$ad_base_dn" "Trash" "Branche de la corbeille"
ldbadd_ou "OU=Parcs,$ad_base_dn" "Parcs" "Branche parcs"
ldbadd_ou "OU=Printers,$ad_base_dn" "Printers" "Branche imprimantes"
sleep 2

echo -e "$COLINFO"
echo "Commplétion de la branche Rights"
echo -e "$COLCMD"
ldbadd -H /var/lib/samba/private/sam.ldb $dir_config/ad_rights.ldif

echo -e "$COLINFO"
echo "Commplétion de la branche Parcs"
echo -e "$COLCMD"
ldbadd -H /var/lib/samba/private/sam.ldb $dir_config/ad_parcs.ldif

echo -e "$COLINFO"
echo "Commplétion de la branche Computers"
echo -e "$COLCMD"
ldbmodify -H /var/lib/samba/private/sam.ldb $dir_config/ad_computers.ldif

echo -e "$COLINFO"
echo "Déplacement des groupes dans la branche dédiée"
echo -e "$COLCMD"
# ldapsearch -xLLL -D $ad_bindDN -w $administrator_pass -b $ad_base_dn -H ldaps://sambaedu4.lan "(objectClass=group)" dn | grep "dn:" | while read dn
ldbsearch -H /var/lib/samba/private/sam.ldb -b "CN=users,$ad_base_dn" "(objectClass=group)" dn | grep "dn:" | while read dn
do
	rdn="$(echo $dn | sed -e "s/dn: //" | cut -d "," -f1)"
	rdn_classe="$(echo $rdn | sed -n "s/^CN=Classe_\|^CN=Equipe_//"p)"
# 	rdn_equipe="$(echo $rdn | sed -n "s/^CN=Equipe_//"p)"
	if [ -n "$rdn_classe" ];then
		target_dn="OU=$rdn_classe,OU=Groups,$ad_base_dn"
		ldbsearch -H /var/lib/samba/private/sam.ldb -b "$target_dn" | grep "dn:" || ldbadd_ou "$target_dn" "$rdn_classe" "ensemble $rdn_classe"
	else
		target_dn="OU=Groups,$ad_base_dn"
	fi
	ldbmv_grp "$rdn,CN=users,$ad_base_dn" "$rdn" "$target_dn"
done

}

# Fonction permettant l'écriture de smb.conf car sambatool n'ajoute pas le dns forwarder lors de l'upgrade
function write_smbconf()
{
mv /etc/samba/smb.conf /etc/samba/smb.conf.ori
cat >/etc/samba/smb.conf <<END
# Global parameters
[global]
	netbios name = SE4AD
	realm = $ad_domain_up
	workgroup = $smb4_domain_up
	dns forwarder = $nameserver
	server role = active directory domain controller
	idmap_ldb:use rfc2307 = yes
	
[netlogon]
	path = /var/lib/samba/sysvol/sambaedu4.lan/scripts
	read only = No

[sysvol]
	path = /var/lib/samba/sysvol
	read only = No
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
		echo -e "${COLTXT}Vous devez donc vérifier par vous même que celle-ci est à l'heure"
		echo -e "le serveur indique le$COLINFO $(date +%c)"
		echo -e "${COLTXT}Ces renseignements sont-ils corrects ? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
		read rep
		[ "$rep" = "n" ] && echo -e "${COLERREUR}Mettez votre serveur à l'heure avant de relancer l'installation$COLTXT" && exit 1
	fi
fi
}

# Fonction permettant l'écriture de resolv.conf car AD est DNS du domaine
function write_resolvconf()
{
cat >/etc/resolv.conf<<END
search $ad_domain
nameserver 127.0.0.1
END
}

# Fonction permettant de se connecter ssh root sur se4-AD
function Permit_ssh_by_password()
{
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

/usr/sbin/service ssh restart
}


# Fonction permettant de descendre le niveau de complexité des pass utilisateurs
function change_policy_passwords() {
samba-tool domain passwordsettings set --complexity=off
samba-tool domain passwordsettings set --history-length=0
samba-tool domain passwordsettings set --min-pwd-age=0
samba-tool domain passwordsettings set --max-pwd-age=0
}

# Fonction permettant de changer le pass root
function change_pass_root()
{	
TEST_PASS="none"
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte super-utilisateur root $COLTXT"
passwd
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe root changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"
}

#Variables :

### Mode devel pour le moment on !###
devel="yes"

samba_packages="samba winbind libnss-winbind krb5-user smbclient"
export DEBIAN_FRONTEND=noninteractive
dir_config="/etc/sambaedu"
se4ad_config="$dir_config/se4ad.config"
db_dir="/etc/sambaedu/smb_export"
nameserver=$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2)
se3ldif="ldapse3.ldif"

echo -e "$COLPARTIE"
echo "Prise en compte des valeurs de $se4ad_config"
echo -e "$COLTXT"

#### Fichier de conf contient ces variables ####
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


echo -e "$COLINFO"
if [ -e "$se4ad_config" ] ; then
 	echo "$se4ad_config est bien present sur la machine"
	source $se4ad_config 
	echo -e "$COLTXT"
else
	echo "$se4ad_config ne se trouve pas sur la machine"
	echo -e "$COLTXT"
	se4ad_ip="$(ifconfig eth0 | grep "inet " | awk '{ print $2}')"
fi

poursuivre

if [ -n "$devel" ]; then
	mkdir -p /root/.ssh/
	ssh_keyser="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMQ6Nd0Kg+L8200pR2CxUVHBtmjQ2xAX2zqArqV45horU8qopf6AYEew0oKanK3GzY2nrs5g2SYbxqs656YKa/OkTslSc5MR/Nndm9/J1CUsurTlo+VwXJ/x1qoLBmGc/9mZjdlNVKIPwkuHMKUch+XmsWF92GYEpTA1D5ZmfuTxP0GMTpjbuPhas96q+omSubzfzpH7gLUX/afRHfpyOcYWdzNID+xdmML/a3DMtuCatsHKO94Pv4mxpPeAXpJdE262DPXPz2ZIoWSqPz8dQ6C3v7/YW1lImUdOah1Fwwei4jMK338ymo6huR/DheCMa6DEWd/OZK4FW2KccxjXvHALn/QCHWCw0UMQnSVpmFZyV4MqB6YvvQ6u0h9xxWIvloX+sjlFCn71hLgH7tYsj4iBqoStN9KrpKC9ZMYreDezCngnJ87FzAr/nVREAYOEmtfLN37Xww3Vr8mZ8/bBhU1rqfLIaDVKGAfnbFdN6lOJpt2AX07F4vLsF0CpPl4QsVaow44UV0JKSdYXu2okcM80pnVnVmzZEoYOReltW53r1bIZmDvbxBa/CbNzGKwxZgaMSjH63yX1SUBnUmtPDQthA7fK8xhQ1rLUpkUJWDpgLdC2zv2jsKlHf5fJirSnCtuvq6ux1QTXs+bkTz5bbMmsWt9McJMgQzWJNf63o8jw== GitLab"
	echo $ssh_keyser >> /root/.ssh/authorized_keys 
fi
# A voir pour modifier ou récupérer depuis sambaedu.config 
[ -z "$smb4_domain" ] && smb4_domain="sambaedu4"
[ -z "$suffix_domain" ] && suffix_domain="lan"
ad_domain="$smb4_domain.$suffix_domain" 
ad_base_dn="DC=$smb4_domain,DC=$suffix_domain"
ad_bindDN="CN=Administrator,CN=users,$ad_base_dn"

smb4_domain_up="$(echo "$smb4_domain" | tr [:lower:] [:upper:])"
suffix_domain_up="$(echo "$suffix_domain" | tr [:lower:] [:upper:])"
ad_domain_up="$(echo "$ad_domain" | tr [:lower:] [:upper:])"
sambadomaine_old="$(echo $se3_domain| tr [:lower:] [:upper:])"
sambadomaine_new="$smb4_domain_up"
haveged
ad_admin_pass=$(makepasswd --minchars=8)

while :; do
	case $1 in
		-d|--download)
		download="yes"
		;;
		
		-n|--network)
		network="yes"
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

if [ "$download" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Pré-téléchargement des paquets uniquement"
	echo -e "$COLTXT"
	installbase
	gensourcelist
	gensourcese4
	echo -e "$COLINFO"
	echo "Téléchargement de samba 4" 
	echo -e "$COLCMD\c"

	apt-get install $samba_packages -d


	echo "Phase de Téléchargement est terminée !"
	echo -e "$COLTXT"
	exit 0
fi


if [ "$network" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Mofification de l'adressage IP"
	echo -e "$COLTXT"
	gennetwork
	service networking restart
	echo "Modification Ok" 
	echo "Testez la connexion internet avant de relancer le script sans option afin de procéder à l'installation"
	exit 0
fi

show_title
echo "Appuyez sur Entree pour continuer"
read dummy


echo -e "$COLPARTIE"

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY

test_ecard
# LADATE="$(date +%d-%m-%Y)"
# fichier_log="/etc/se3/install-stretch-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

gensourcelist

gensourcese4

installbase

write_hostconf

echo -e "$COLPARTIE"
echo "Installation de Samba et cie" 
echo -e "$COLTXT"

installsamba

if [ -e "$dir_config/slapd.conf" ]; then 
	install_slapd
	clean_ldap
	extract_ldifs
	convert_smb_to_ad
	write_krb5
	write_smbconf
	activate_smb_ad
	write_resolvconf
	change_pass_admin
	modif_ldb
else
	echo "$dir_config/slapd.conf non trouvé - L'installation se poursuivra sur un nouveau domaine sans import d'anciennes données"
	poursuivre
	provision_new_ad # Voir partie dns interne
	write_smbconf
	activate_smb_ad
	write_krb5
	
fi

change_policy_passwords

Permit_ssh_by_password	

change_pass_root

echo -e "$COLTITRE"
echo "L'installation est terminée. Bonne utilisation de SambaEdu4-AD ! :)"
echo -e "$COLTXT"

# script_absolute_path=$(readlink -f "$0")
# [ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_phase2.sh ] && mv /root/install_se4ad_phase2.sh  /root/install_phase2.done
. /etc/profile

unset DEBIAN_FRONTEND
exit 0

