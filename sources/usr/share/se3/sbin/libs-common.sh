#!/bin/bash
# Projet SambaEdu - distribué selon la licence GPL
####Script contenant les fonctions communes des Scripts  ####
### Auteur : Franck Molle franck.molle@sambaedu.org
## Version 0.3 - 12-2018 ##

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m\c"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m\c"     # Gris
COLINFO="\033[0;36m\c"	# Cyan
COLPARTIE="\033[1;34m\c"	# Bleu

# Test presence whiptail
function check_whiptail()
{
if [ -z "$(which whiptail)" ];then
apt-get install whiptail -y 
fi
}

# Erreur on quitte !
function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}

# Poursuivre ou corriger ?
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
function poursuivre()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
                echo -e "$COLTXT"
                echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
                read -t 30 REPONSE
                if [ -z "$REPONSE" ]; then
                        REPONSE="o"
                fi
        done

        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
                ERREUR "Abandon!"
        fi
}

# Demande de quitter
function quit_on_choice()
{
echo -e "$COLERREUR"
echo "Arrêt du script !"
echo -e "$1"
echo -e "$COLTXT"
exit 1
}

# Copie de ma clé ssh ;)
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

function whiptail_error_style 
{

NEWT_COLORS='                                                                                                                         
 window=,red
 border=white,red
 textbox=white,red
 button=black,white' whiptail --backtitle "$1" --title "$2" --msgbox "$3" 13 70

}

# test de l'architecture'
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

#Activation Debug
function debug() {
debug="1"
if [ "$debug" = "1" ]; then
set -x
poursuivre
fi
}
# Fonction permettant la mise à l'heure du serveur 
function settime() {
show_info "Mise à l'heure du serveur"
[ -z "$ntpserv" ] && ntpserv="ntp.midway.ovh"

/usr/sbin/ntpdate -u -b $ntpserv
sleep 1
}

# Fonction à fusionner avec la précédente ?
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



# Affichage de la partie actuelle
function show_part()
{
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

# confirmation de la conf du lan 
function conf_network()
{
interfaces_file="/etc/network/interfaces"
config_lan_title="Configuration du réseau local"	
se3network=$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")
se3bcast=$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")
se3gw=$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")
proxy_config="$(sed -n 's#http_proxy="http://##p' /etc/profile | cut -d '"' -f1)"
if [ -z "$proxy_config" ]; then
    proxy_detect="Aucun"
else
    proxy_detect="$proxy_config"
fi

REPONSE=""
while [ "$REPONSE" != "yes" ]
do
	if [ "$REPONSE" = "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de base du reseau" 15 70 $se3network 2>$tempfile || erreur "Annulation"
		se3network="$(cat $tempfile)"
				
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de broadcast" 15 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se3bcast="$(cat $tempfile)"
		
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de la passerelle" 15 70 $se3gw 2>$tempfile || erreur "Annulation"
		se3gw="$(cat $tempfile)"
		
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir adresse:port du proxy.\nExemple : 172.19.80.1:3128 ou laisser vide sans proxy" 15 70 $proxy_config 2>$tempfile || erreur "Annulation"
		proxy_config="$(cat $tempfile)"
		proxy_detect="$proxy_config"
				
	fi

	confirm_title="Configuration réseau local"
	confirm_txt="La configuration suivante a été détectée sur le serveur SE3 
	
Adresse IP du serveur SE3 :   $se3ip
Adresse réseau de base :      $se3network
Adresse de Broadcast :        $se3bcast
Adresse IP de la Passerelle : $se3gw
Adresse IP et port du proxy : $proxy_detect
	
Ces valeurs sont elles correctes ?"	
	
	if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 17 70) then
		REPONSE="yes"
	else
		REPONSE="no"
	fi
done
}

# Fonction de preconfig se4-AD
function preconf_se4ad()
{
se4ad_lan_title="Configuration du futur SE4-AD"
if [ ! -e "/bin/lsblk" ];then
    apt-get install util-linux
fi
sd_detect="$(lsblk -n -o "NAME,TYPE" | grep -v fd0 | sort | grep disk | head -n1 | cut -d " " -f1)"

REPONSE=""
details="no"
se4ad_ip_cut="$(echo "$se3ip"  | cut -d . -f1-3)."
se4ad_mask="$se3mask"
se4ad_network="$se3network"
se4ad_bcast="$se3bcast"
se4ad_gw="$se3gw"
while [ "$REPONSE" != "yes" ]
do
	se4ad_boot_disk_txt="** Nom du disque sur lequel le système sera installé **
	
Indiquer le disque sur lequel le système sera installé. Le plus souvent il s'agira de /dev/sda mais cela peut être différent notamment sur Xen"
        if [ "$1" != "lxc" ]; then
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "$se4ad_boot_disk_txt" 13 70 "/dev/$sd_detect" 2>$tempfile || erreur "Annulation"
	se4ad_boot_disk=$(cat $tempfile)
	else
            se4ad_boot_disk="Container LXC"
	fi
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'IP du SE4-AD" 12 70 $se4ad_ip_cut 2>$tempfile || erreur "Annulation"
	se4ad_ip=$(cat $tempfile)
	
	if [ "$se4ad_ip" = "$se4ad_ip_cut" ]; then
            whiptail_error_style "$BACKTITLE" "$se4ad_lan_title" "$se4ad_ip_cut est une saisie invalide !!"
            continue
	fi
	
	if [ "$details" != "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir le Masque sous réseau" 12 70 $se3mask 2>$tempfile || erreur "Annulation"
		se4ad_mask=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 12 70 $se3network 2>$tempfile || erreur "Annulation"
		se4ad_network=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de broadcast" 12 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se4ad_bcast=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 12 70 $se3gw 2>$tempfile || erreur "Annulation"
		se4ad_gw=$(cat $tempfile)
	fi
	details="yes"
	samba_domain_check="no"
	
	mirror_name_title="Miroir Debian à utiliser pour l'installation"
	$dialog_box --backtitle "$BACKTITLE" --title "$mirror_name_title" --inputbox "Confirmer le nom du miroir à utiliser ou bien saisir l'adresse de votre miroir local si vous en avez un" 12 70 deb.debian.org 2>$tempfile || erreur "Annulation"
	mirror_name=$(cat $tempfile)
		
	se4ad_name_title="Nom du SE4-AD"
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_name_title" --inputbox "Saisir le Nom de la machine SE4-AD" 12 70 se4ad 2>$tempfile || erreur "Annulation"
	se4ad_name=$(cat $tempfile)
	
	choice_domain_title="Important - Nom de domaine AD"
	choice_domain_text="Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc primordial
Il est composé de plusieurs parties : le nom de domaine samba suivi de son suffixe, séparés par un point.

Exemple de domaine AD : \"diderot.org\"
* le domaine samba serait \"diderot\" et le suffixe \".org\"

ATTENTION : 
* Le domaine samba actuel \"$se3_domain\" doit être CONSERVÉ pour permettre une migration AUTOMATIQUE des clients Windows sur le domaine AD. Le suffixe \"$domain\" peut quant à lui être modifié selon les besoins.
* le domaine samba ne doit en aucun cas dépasser 15 caractères.
* Les domaines AD du type sambaedu.lan ou etab.local sont à proscrire"
NEWT_COLORS='window=,red'   
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
	confirm_title="Récapitulatif de la configuration prévue"
	confirm_txt="Disque à utiliser : $se4ad_boot_disk
	
IP :            $se4ad_ip
Masque :        $se4ad_mask
Réseau :        $se4ad_network
Broadcast :     $se4ad_bcast
Passerelle :    $se4ad_gw
Miroir debian : $mirror_name
Serveur Proxy : $proxy_config

Nom :           $se4ad_name

Nom de domaine AD saisi : $domain
Nom de domaine samba :    $samba_domain

Confirmer l'enregistrement de cette configuration ?"
		
		if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 23 60) then
			REPONSE="yes"
		else
			REPONSE="no"
		fi	
done

}


# Fonction écriture fichier de conf /etc/sambaedu/se4ad.config et se4fs
function write_se4ad_config
{
show_part "Génération des fichiers de configuration SE4"
if [ -e "$se4ad_config" ] ; then
    show_info "$se4ad_config existe on en écrase le contenu"
fi

# Génération de $se4ad_config
cat >  $se4ad_config <<END
## Adresse IP du futur SE4-AD ##
se4ad_ip="$se4ad_ip"
## Miroir debian ##
mirror_name="$mirror_name"
## Nom du futur SE4-AD ##
se4ad_name="$se4ad_name"
## Nom de domaine samba du SE4-AD ##
samba_domain="$samba_domain"
## Nom de domaine complet - realm du SE4-AD ##
domain="$domain"
## Adresse IP de SE3 ##
se3ip="$se3ip"
## Nom du domaine samba actuel
se3_domain="$se3_domain"
##Nom netbios du serveur se3 actuel##
netbios_name="$netbios_name"
##Adresse du serveur DNS##
nameserver="$nameserver"
##Pass admin LDAP##
adminPw="$adminPw"
##base dn LDAP##
ldap_base_dn="$ldap_base_dn"
##Rdn admin LDAP##
adminRdn="$adminRdn"
##SID domaine actuel
domainsid="$domainsid"
proxy_config="$proxy_config"
END
}

function write_se4fs_config
{
cat >  $se4fs_config <<END
## Params du futur SE4-AD ## 
se4ad_ip="$se4ad_ip"
## Miroir debian ##
mirror_name="$mirror_name"
se4ad_name="$se4ad_name"
## Params du futur SE4-FS et domaine##
se4fs_ip="$se4fs_ip"
se4fs_name="$se4fs_name"
samba_domain="$samba_domain"
domain="$domain"
nameserver="$nameserver"
## params annuaire AD##
ldap_port="636"
admin_name="Administrator"
ldap_admin_name="Administrator"
admin_rdn="cn=Users"
people_rdn="ou=Utilisateurs"
groups_rdn="ou=Groups"
rights_rdn="ou=Rights"
parcs_rdn="ou=Parcs"
computers_rdn="CN=computers"
classes_rdn="ou=classes"
equipes_rdn="ou=equipes"
matieres_rdn="ou=matieres"
cours_rdn="ou=cours"
projets_rdn="ou=projets"
other_groups_rdn="ou=autres"
delegations_rdn="ou=delegations" 
equipements_rdn="ou=Materiels"
trash_rdn="ou=Trash"
lang="fr"
ldap_url="ldaps://$domain"
cnPolicy="1"
pwdPolicy="1"
path2UserSkel="/etc/skel/user"
proxy_config="$proxy_config"
END

# Params se4fs_config_clients
cat > $se4fs_config_clients <<END
adminse_name = "adminse3"  
client_windows = "1" 
adminse_passwd = "$xppass"
END

chmod +x $se4fs_config

}

# Fonction génération des fichiers /etc/hosts et /etc/hostname
function write_hostconf()
{
cat >/etc/hosts <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4fs_ip	$se4fs_name.$domain	$se4fs_name
END

cat >/etc/hostname <<END
$se4fs_name
END
}

# Fonction export des fichiers tdb et smb.conf 
function export_smb_files()
{
show_part "Export des fichiers Samba"
show_info "Arrêt du service Samba pour export des fichiers TDB"
service samba stop
show_info "Copie des fichiers TDB vers $dir_export"
tdb_smb_dir="/var/lib/samba"
pv_tdb_smb_dir="/var/lib/samba/private"
cp $pv_tdb_smb_dir/secrets.tdb $dir_export/
cp $pv_tdb_smb_dir/schannel_store.tdb $dir_export/
cp $pv_tdb_smb_dir/passdb.tdb $dir_export/

if [ -e "$tdb_smb_dir/gencache_notrans.tdb" ] ;then
    cp $tdb_smb_dir/gencache_notrans.tdb $dir_export/
fi
cp $tdb_smb_dir/group_mapping.tdb $dir_export/
cp $tdb_smb_dir/account_policy.tdb $dir_export/
cp $tdb_smb_dir/wins.tdb $dir_export/
cp $tdb_smb_dir/wins.dat $dir_export/

cp /etc/samba/smb.conf $dir_export/
show_info "Remise en route de Samba"
echo -e "$COLCMD"
service samba start
echo -e "$COLTXT"
}

# Export des fichiers DHCP
function export_dhcp()
{
dhcpd_conf="/etc/dhcp/dhcpd.conf"
reservation_file="$dir_config/reservations.inc"
rm -f $reservation_file

# mkdir -p /etc/sambaedu/sambaedu.conf.d

echo "# configuration sambaedu" > $dir_config/dhcp.conf
sed '/^\s*#/d' /etc/se3/config_d.cache.sh > $dir_config/dhcp.conf


if [ -e "$dhcpd_conf" ];then 
    show_part "Analyse de la configuration DHCP et export des réservations si besoin"
    cat "$dhcpd_conf" | while read line
    do
        if [ -n "$(echo "$line" | grep "^host")" ] || [ "$temoin" = "yes" ];then
            temoin="yes"
            echo $line >> "$reservation_file"
        else
            continue
        fi
    done
fi
}

# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif
function export_ldap_files()
{
show_part "Exports LDAP / SQL / CUPS"
show_info "Ajout du mapping de groupe sur Le groupe Administratifs avant export"
echo -e "$COLCMD"
net groupmap add ntgroup=Administratifs unixgroup=Administratifs type=domain comment="Administratifs du domaine"
echo -e "$COLTXT"

conf_slapd="/etc/ldap/slapd.conf"
show_info "Export des fichiers de conf et ldapse3.ldif vers $dir_export"
cp $conf_slapd $dir_export/
ldapsearch -xLLL -D "$adminRdn,$ldap_base_dn" -w $adminPw > $dir_export/ldapse3.ldif
schema_dir="/etc/ldap/schema"
cp $schema_dir/ltsp.schema $schema_dir/samba.schema $schema_dir/printer.schema $dir_export/
cp /var/lib/ldap/DB_CONFIG $dir_export/
cp /etc/ldap/slapd.pem $dir_export/
}

# Export des fichiers sql
function export_sql_files()
{
show_info "Export des bases connexions et quotas vers $dir_export"

mysqldump --opt se3db quotas > $dir_export/quotas.sql
mysqldump --opt se3db connexions > $dir_export/connexions.sql
[ -n "$dir_preseed" ] && cp $dir_export/quotas.sql $dir_export/connexions.sql $dir_preseed/
}

# Export des fichiers cups
function export_cups_config()
{
conf_cups="/etc/cups/printers.conf"
if [ -e "$conf_cups" ]; then
    show_info "Export du fichier de configuration Cups vers $dir_export"
    cp /etc/cups/printers.conf $dir_export/
    [ -n "$dir_preseed" ] && cp $dir_export/printers.conf $dir_preseed/
fi
}

# Recherche de sid en doublon
function search_duplicate_sid() {
test_duplicate_sid="/usr/share/se3/sbin/duplicate_sid.py"
if [ -f $test_duplicate_sid ];then
    duplicate_sid="$( python $test_duplicate_sid )"
    if [ "$duplicate_sid"  != "" ];then
        $dialog_box  --backtitle "$BACKTITLE" --title "Doublons dans l'annuaire !" --msgbox "$duplicate_sid

        Corriger cela dans l'interface :
            - Informations système => correction de problèmes => recherche des doublons ldap
            - Gestion des parcs => Rechercher => doublons MAC" 15 75
        erreur "Doublons dans l'annuaire, corriger cela dans l'interface :
- Informations système => correction de problèmes => recherche des doublons ldap
- Gestion des parcs => Rechercher => doublons MAC"
    else
        $dialog_box  --backtitle "$BACKTITLE" --title "Pas de doublon dans l'annuaire" --msgbox "Aucun sid en doublon n'a été trouvé dans l'annuaire."  12 60
    fi
fi
}
