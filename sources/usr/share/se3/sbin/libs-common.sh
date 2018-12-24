#!/bin/bash

####Script contenant les fonctions communes des Scripts  ####
# 
### Auteur : Franck Molle


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
                read REPONSE
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
    go_on
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

# Affichage d'une info
function show_info()
{
echo -e "$COLTXT"
echo -e "$COLINFO"
echo "$1"
echo -e "$COLTXT"
# sleep 1
}

# confirmation de la conf du lan 
function conf_network()
{
config_lan_title="Configuration du réseau local"	
se3network=$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")
se3bcast=$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")
se3gw=$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")


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
				
	fi

	confirm_title="Configuration réseau local"
	confirm_txt="La configuration suivante a été détectée sur le serveur SE3 
	
Adresse IP du serveur SE3 :   $se3ip
Adresse réseau de base :      $se3network
Adresse de Broadcast :        $se3bcast
Adresse IP de la Passerelle : $se3gw
	
Ces valeurs sont elles correctes ?"	
	
	if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 15 70) then
		REPONSE="yes"
	else
		REPONSE="no"
	fi
done
}


# Fonction écriture fichier de conf /etc/sambaedu/se4ad.config et se4fs
function write_sambaedu_conf
{

if [ -e "$se4ad_config" ] ; then
    echo -e "$COLINFO"
    echo "$se4ad_config existe on en écrase le contenu"
    echo -e "$COLTXT"
fi

# Génération de $se4ad_config
echo "## Adresse IP du futur SE4-AD ##" > $se4ad_config
echo "se4ad_ip=\"$se4ad_ip\"" >> $se4ad_config
echo "## Miroir debian ##" >> $se4ad_config
echo "mirror_name=\"$mirror_name\"" >> $se4ad_config
echo "## Nom du futur SE4-AD ##" >> $se4ad_config
echo "se4ad_name=\"$se4ad_name\"" >> $se4ad_config
echo "## Nom de domaine samba du SE4-AD ##" >> $se4ad_config
echo "samba_domain=\"$samba_domain\"" >>  $se4ad_config
echo "## Suffixe du domaine##" >> $se4ad_config
echo "## Nom de domaine complet - realm du SE4-AD ##" >> $se4ad_config
echo "domain=\"$domain\"" >> $se4ad_config
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
echo "##SID domaine actuel" >> $se4ad_config
echo "domainsid=\"$domainsid\"" >> $se4ad_config

if [ "$preseed_se4fs" = "yes" ];then
    echo "## Params du futur SE4-AD ##" > $se4fs_config
    echo "se4ad_ip=\"$se4ad_ip\"" >> $se4fs_config
    echo "## Miroir debian ##" >> $se4fs_config
    echo "mirror_name=\"$mirror_name\"" >> $se4fs_config
    echo "se4ad_name=\"$se4ad_name\"" >> $se4fs_config
    echo "## Params du futur SE4-FS et domaine##" >> $se4fs_config
    echo "se4fs_ip=\"$se4fs_ip\"" >> $se4fs_config
    echo "se4fs_name=\"$se4fs_name\"" >> $se4fs_config
    echo "samba_domain=\"$samba_domain\"" >>  $se4fs_config
    echo "domain=\"$domain\"" >> $se4fs_config
    echo "nameserver=\"$nameserver\"" >> $se4fs_config
    echo "## params annuaire AD##" >> $se4fs_config
    echo "ldap_port=\"636\"" >> $se4fs_config
    echo "admin_name=\"Administrator\"" >> $se4fs_config
    echo "ldap_admin_name=\"Administrator\"" >> $se4fs_config
    echo "admin_rdn=\"cn=Users\"" >> $se4fs_config
    echo "people_rdn=\"ou=Utilisateurs\"" >> $se4fs_config
    echo "groups_rdn=\"ou=Groups\"" >> $se4fs_config
    echo "rights_rdn=\"ou=Rights\"" >> $se4fs_config
    echo "parcs_rdn=\"ou=Parcs\"" >> $se4fs_config
    echo "computers_rdn=\"CN=computers\"" >> $se4fs_config
    echo "classes_rdn=\"ou=classes\"" >> $se4fs_config
    echo "equipes_rdn=\"ou=equipes\"" >> $se4fs_config
    echo "matieres_rdn=\"ou=matieres\"" >> $se4fs_config
    echo "cours_rdn=\"ou=cours\"" >> $se4fs_config
    echo "projets_rdn=\"ou=projets\"" >> $se4fs_config
    echo "other_groups_rdn=\"ou=autres\"" >> $se4fs_config
    echo "delegations_rdn=\"ou=delegations\"" >> $se4fs_config 
    echo "equipements_rdn=\"ou=Materiels\"" >> $se4fs_config
    echo "trash_rdn=\"ou=Trash\"" >> $se4fs_config
    echo "lang=\"fr\"" >> $se4fs_config
    echo "ldap_url=\"ldaps://$domain\"" >> $se4fs_config
    echo "cnPolicy=\"1\"" >> $se4fs_config
    echo "pwdPolicy=\"1\"" >> $se4fs_config
    echo "path2UserSkel=\"/etc/skel/user\"" >> $se4fs_config
    # Params se4fs_config_clients
    echo "adminse_name" = \"adminse3\"  > $se4fs_config_clients
    echo "client_windows" = \"1\" >> $se4fs_config_clients
    echo "adminse_passwd" = \"$xppass\" >> $se4fs_config_clients
fi
chmod +x $se4fs_config
}


# Fonction export des fichiers tdb et smb.conf 
function export_smb_files()
{
echo -e "$COLINFO"
echo "Arrêt du service Samba pour export des fichiers TDB"
echo -e "$COLTXT"
service samba stop
echo -e "$COLINFO"
echo "Copie des fichiers TDB vers $dir_export"
echo -e "$COLCMD"
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
echo -e "$COLINFO"
echo "Remise en route de Samba"
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
    echo -e "$COLINFO"
    echo "Analyse de la configuration DHCP et export des réservations si besoin"
    echo -e "$COLTXT"
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

# Export des fichiers sql
function export_sql_files()
{
echo -e "$COLINFO"
echo "Export des bases connexions et quotas vers $dir_export"
echo -e "$COLTXT"

mysqldump --opt se3db quotas > $dir_export/quotas.sql
mysqldump --opt se3db connexions > $dir_export/connexions.sql
[ -n "$dir_preseed" ] && cp $dir_export/quotas.sql $dir_export/connexions.sql $dir_preseed/
}

# Export des fichiers cups
function export_cups_config()
{
conf_cups="/etc/cups/printers.conf"
if [ -e "$conf_cups" ]; then
    echo -e "$COLINFO"
    echo "Export du fichier de configuration Cups vers $dir_export"
    echo -e "$COLTXT"
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
