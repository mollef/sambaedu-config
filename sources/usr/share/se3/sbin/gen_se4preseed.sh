#!/bin/bash
# Projet SambaEdu - distribué selon la licence GPL
##### Permet la génération du preseed de se4-AD et se4-FS#####
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
echo "Script intéractif permettant la génération des preseed  se4-AD/se4-FS"
}

if [ "$1" = "--help" -o "$1" = "-h" ]
then
	usage
	echo "Usage : pas d'option"
	exit
fi

function show_title() {
BACKTITLE="Projet SambaEdu - https://www.sambaedu.org/"

WELCOME_TITLE="Génération du preseed pour SE4-AD / SE4-FS"
WELCOME_TEXT="Bienvenue dans la pré-installation de SAMBAEDU 4.

Ce programme va générer un ou des fichiers de configuration automatique (preseed) utilisables pour l'installation d'un SE4-AD / SE4-FS sous Debian Stretch.

Une fois la machine SE4-AD / SE4-FS installée, il suffira de la démarrer afin de poursuivre son installation et sa configuration de façon automatique."

$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 18 75
}


ask_preseed_se4fs()
{
confirm_title="Générer un preseed pour le serveur se4-FS"
confirm_txt="Faut-il également générer un fichier de préconfiguration preseed pour une installation automatique du serveur Samba Edu 4 - Serveur de fichiers (se4-FS) ?"
	
if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 12 70) then
    preseed_se4fs="yes"
fi
}

function preconf_se4fs()
{
se4fs_lan_title="Configuration réseau du futur SE4-FS"

REPONSE=""
details="no"
se4fs_ip_cut="$(echo "$se3ip"  | cut -d . -f1-3)."
se4fs_mask="$se4ad_mask"
se4fs_network="$se4ad_network"
se4fs_bcast="$se4ad_bcast"
se4fs_gw="$se4ad_gw"

while [ "$REPONSE" != "yes" ]
do
	$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'IP du SE4-FS" 12 70 $se4fs_ip_cut 2>$tempfile || erreur "Annulation"
	se4fs_ip=$(cat $tempfile)
	
	if [ "$se4fs_ip" = "$se4ad_fs_cut" ]; then
            whiptail_error_style "$BACKTITLE" "$se4ad_lan_title" "$se4fs_ip_cut est une saisie invalide !!"
            continue
	fi
	
	
	if [ "$details" != "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir le Masque sous réseau" 12 70 $se3mask 2>$tempfile || erreur "Annulation"
		se4fs_mask=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 12 70 $se3network 2>$tempfile || erreur "Annulation"
		se4fs_network=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de broadcast" 12 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se4fs_bcast=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 12 70 $se3gw 2>$tempfile || erreur "Annulation"
		se4fs_gw=$(cat $tempfile)
	fi
	details="yes"
	
	se4fs_name_title="Nom du SE4-FS"
# 	$dialog_box --backtitle "$BACKTITLE" --title "$se4fs_name_title" --inputbox "Saisir le Nom de la machine SE4-FS" 12 70 se4fs 2>$tempfile || erreur "Annulation"
# 	se4fs_name=$(cat $tempfile)
	se4fs_name="se4fs"
	
	confirm_title="Récapitulatif de la configuration prévue"
	confirm_txt="IP :         $se4fs_ip
Masque :     $se4fs_mask
Réseau :     $se4fs_network
Broadcast :  $se4fs_bcast
Passerelle : $se4fs_gw

Nom :        $se4fs_name


Confirmer l'enregistrement de cette configuration ?"
		
		if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 18 60) then
			REPONSE="yes"
		else
			REPONSE="no"
		fi	
done

}

function partman_se4fs()
{
se4fs_partman_title="Configuration du partitionnement du futur SE4-FS"

REPONSE=""
details="no"
while [ "$REPONSE" != "yes" ]
do
    se4fs_boot_disk_txt="** Nom du disque sur lequel le système sera installé **
	
Indiquer le disque sur lequel le système sera installé. Le plus souvent il s'agira de /dev/sda mais cela peut être différent notamment sur Xen"
    
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --inputbox "$se4fs_boot_disk_txt" 13 70 "/dev/$sd_detect" 2>$tempfile || erreur "Annulation"
    se4fs_boot_disk=$(cat $tempfile)
	
    root_size_txt="** Taille de la partition racine **

Saisir en Mo la taille minimale / optimale / maximale souhaitée en séparant les trois valeurs par des espaces. Vous pouvez modifier ou confirmer les valeurs proposées"
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --inputbox "$root_size_txt" 13 70 "4000 5000 6000" 2>$tempfile || erreur "Annulation"
    root_size=$(cat $tempfile)
    root_mini="$(echo $root_size | cut -d" " -f1)"
    root_opt="$(echo $root_size | cut -d" " -f2)"
    root_max="$(echo $root_size | cut -d" " -f3)"
    
    var_size_txt="** Taille de la partition /var **

Saisir en Mo la taille minimale / optimale / maximale souhaitée en séparant les trois valeurs par des espaces. Vous pouvez modifier ou confirmer les valeurs proposées"
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --inputbox "$var_size_txt" 13 70 "10000 12000 15000" 2>$tempfile || erreur "Annulation"
    var_size=$(cat $tempfile)
    var_mini="$(echo $var_size | cut -d" " -f1)"
    var_opt="$(echo $var_size | cut -d" " -f2)"
    var_max="$(echo $var_size | cut -d" " -f3)"
            
    home_size_txt="** Taille de la partition /home **

Saisir en Mo la taille minimale / optimale / maximale souhaitée en séparant les trois valeurs par des espaces. Vous pouvez modifier ou confirmer les valeurs proposées"
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --inputbox "$home_size_txt" 13 70 "15000 20000 40000" 2>$tempfile || erreur "Annulation"
    home_size=$(cat $tempfile)
    home_mini="$(echo $home_size | cut -d" " -f1)"
    home_opt="$(echo $home_size | cut -d" " -f2)"
    home_max="$(echo $home_size | cut -d" " -f3)"
              
    varse_size_txt="** Taille de la partition /var/sambaedu **

Saisir en Mo la taille minimale / optimale / maximale souhaitée en séparant les trois valeurs par des espaces. Vous pouvez modifier ou confirmer les valeurs proposées"
    $dialog_box --backtitle "$BACKTITLE" --title "$se4fs_partman_title" --inputbox "$varse_size_txt" 13 70 "15000 20000 40000" 2>$tempfile || erreur "Annulation"
    varse_size=$(cat $tempfile)
    varse_mini="$(echo $varse_size | cut -d" " -f1)"
    varse_opt="$(echo $varse_size | cut -d" " -f2)"
    varse_max="$(echo $varse_size | cut -d" " -f3)"
	
		
confirm_title="Récapitulatif des tailles de partitions prévues"
confirm_txt="Rappel : Les valeurs sont en Mo 
    
Partition Racine : minimale $root_mini, optimale $root_opt, maximale $root_max
Partition /var : minimale $var_mini, optimale $var_opt, maximale $var_max
Partition /home : minimale $home_mini, optimale $home_opt, maximale $home_max
Partition /var/sambaedu : minimale $varse_mini, optimale $varse_opt, maximale $varse_max
Partition swap : 200% de la ram ou 16Go  - valeurs non modifiables

Disque à utiliser : $se4fs_boot_disk 


Confirmer l'enregistrement de cette configuration ?"
		
		if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 20 80) then
			REPONSE="yes"
		else
			REPONSE="no"
		fi	
done
}


# Fonction copie des fichiers de conf /etc/sambaedu
function cp_config_to_preseed()
{
show_part "Mise en place de la structure d'installation preseed et de la configuration apache"
mkdir -p $dir_preseed/secret/
cd $dir_config
if [ "$preseed_se4fs" = "yes" ];then
    show_info "Copie du fichier de configuration se4fs et du fichier $reservation_file dhcp s'il existe "
    echo -e "$COLCMD"
    cp -v $se4fs_config $dir_preseed/
    cp -v $se4fs_config_clients $dir_preseed/secret/
    if [ -e "$reservation_file" ];then
        cp -v $reservation_file $dir_preseed/
    fi
    
    if [ -e "$dir_config/dhcp.conf" ];then
        cp -v $dir_config/dhcp.conf $dir_preseed/
    fi
    echo -e "$COLTXT"
fi
show_info "Création de l'archive d'export des données $se4ad_config_tgz et copie sur $dir_preseed"
echo -e "$COLCMD"
tar -czf $se4ad_config_tgz export_se4ad
cp -av  $se4ad_config_tgz $dir_preseed/secret/
echo -e "$COLTXT"
cd - >/dev/null
sleep 2
}

function write_apache_config()
{
show_info "Mise en place de la conf apache pour le dossier diconf"
echo -e "$COLCMD"

cat > /etc/apache2/conf.d/diconf <<END
<Directory /var/www/diconf/>
    Options -Indexes FollowSymLinks MultiViews
    Allow from all
    </Directory>

<Directory /var/www/diconf/secret/>
	Options -Indexes FollowSymLinks MultiViews
	AllowOverride All
	deny from all
	Allow from $se4ad_ip
END
if [ -n "$se4fs_ip" ];then
cat >> /etc/apache2/conf.d/diconf <<END	
	Allow from $se4fs_ip
END
fi
cat >> /etc/apache2/conf.d/diconf <<END	
</Directory>
END

service apache2 restart
echo -e "$COLTXT"
}

# copie des clés ssh présente sur le serveur principal sur le container
function write_ssh_keys
{
ssh_keys_host="/root/.ssh/authorized_keys"
rm -f $dir_config/id_rsa*
ssh-keygen -t rsa -N "" -f $dir_config/id_rsa -q

if [ -e "$ssh_keys_host" ];then
    show_info "Copie du fichier des clés SSH $ssh_keys_host"
    cp "$ssh_keys_host" "$dir_preseed/"
#     echo -e "$COLCMD"
else
    touch $dir_preseed/authorized_keys
fi
chmod 644 $dir_preseed/authorized_keys
cat $dir_config/id_rsa.pub >> $dir_preseed/authorized_keys
cp "$dir_config/id_rsa.pub" "$dir_preseed/"

cp $dir_config/id_rsa $dir_preseed/secret/
chmod 644 $dir_preseed/secret/id_rsa
}

# Génération du preseed avec les données saisies
function write_preseed
{
dir_config_preseed="$dir_config/preseed"
template_preseed="preseed_se4ad_stretch.in"
target_preseed="$dir_preseed/se4ad.preseed"

show_info "Copie du modele $template_preseed dans $target_preseed"
cp "$dir_config_preseed/$template_preseed" "$target_preseed"
show_info "Modification du preseed avec les données saisies"

sed -e "s/###_SE4AD_IP_###/$se4ad_ip/g; s/###_SE4MASK_###/$se4ad_mask/g; s/###_SE4GW_###/$se4ad_gw/g; s/###_NAMESERVER_###/$nameserver/g; s/###_MIRROR_###/$mirror_name/g; s/###_SE4NAME_###/$se4ad_name/g" -i  $target_preseed
sed -e "s/###_AD_DOMAIN_###/$domain/g; s/###_IP_SE3_###/$se3ip/g; s/###_NTP_SERV_###/$ntpserv/g; s|###_BOOT_DISK_###|$se4ad_boot_disk|g" -i  $target_preseed 


if [ "$preseed_se4fs" = "yes" ];then
    template_preseed="preseed_se4fs_stretch.in"
    target_preseed="$dir_preseed/se4fs.preseed"
    show_info "Copie du modele $template_preseed dans $target_preseed"
    cp "$dir_config_preseed/$template_preseed" "$target_preseed"
    show_info "Modification du preseed avec les données saisies"
    sed -e "s/###_SE4FS_IP_###/$se4fs_ip/g; s/###_SE4FS_MASK_###/$se4fs_mask/g; s/###_SE4FS_GW_###/$se4fs_gw/g; s/###_NAMESERVER_###/$nameserver/g; s/###_MIRROR_###/$mirror_name/g; s/###_SE4FS_NAME_###/$se4fs_name/g" -i  $target_preseed
    sed -e "s/###_AD_DOMAIN_###/$domain/g; s/###_IP_SE3_###/$se3ip/g; s/###_NTP_SERV_###/$ntpserv/g" -i  $target_preseed 
    sed -e "s|###_BOOT_DISK_###|$se4fs_boot_disk|g; s/###_ROOT_SIZE_###/$root_size/g; s/###_VAR_SIZE_###/$var_size/g; s/###_VARSE_SIZE_###/$varse_size/g; s/###_HOME_SIZE_###/$home_size/g" -i  $target_preseed
fi
}

function write_late_command() {
se4fs_late_command="$dir_preseed/se4fs_late_command.sh"
show_info "Mise en place du script $se4fs_late_command"

cat > $se4fs_late_command <<END
#!/bin/sh
wget http://$se3ip/diconf/install_se4fs_phase2.sh
wget http://$se3ip/diconf/profile_se4fs
wget http://$se3ip/diconf/.bashrc
wget http://$se3ip/diconf/authorized_keys
wget http://$se3ip/diconf/sambaedu.conf
wget http://$se3ip/diconf/connexions.sql
wget http://$se3ip/diconf/quotas.sql
wget http://$se3ip/diconf/printers.conf
wget http://$se3ip/diconf/id_rsa.pub 
wget http://$se3ip/diconf/secret/id_rsa
wget http://$se3ip/diconf/secret/clients.conf

mkdir -p /target/etc/sambaedu
mkdir -p /target/etc/sambaedu/sambaedu.conf.d
cp clients.conf /target/etc/sambaedu/sambaedu.conf.d/
cp sambaedu.conf id_rsa id_rsa.pub connexions.sql quotas.sql /target/etc/sambaedu/
chmod -R 600 /target/etc/sambaedu/*
mkdir -p /target/root/.ssh/
cp authorized_keys /target/root/.ssh/
chmod +x ./install_se4fs_phase2.sh
cp profile_se4fs /target/root/.profile
cp .bashrc install_se4fs_phase2.sh /target/root/
END
if [ -e "$dir_preseed/reservations.inc" ];then 
        echo "wget http://$se3ip/diconf/reservations.inc" >> $se4fs_late_command
        echo "cp reservations.inc /target/etc/sambaedu" >> $se4fs_late_command
fi

if [ -e "$dir_preseed/dhcp.conf" ];then 
        echo "wget http://$se3ip/diconf/dhcp.conf" >> $se4fs_late_command
        echo "cp dhcp.conf /target/etc/sambaedu" >> $se4fs_late_command
fi

chmod +x $se4fs_late_command
}


# verif somme MD5
function check_md5() {

if [ -e "netboot_stretch.tar.gz" -a -e "MD5SUMS" ]; then
    md5_netboot_dl="$(grep "./netboot/netboot.tar.gz" MD5SUMS | cut -f1 -d" ")"
    md5_netboot_local="$(md5sum netboot_stretch.tar.gz  | cut -f1 -d" ")"
    
        
    if [ "$md5_netboot_dl" != "$md5_netboot_local" ]; then
        rm -f netboot_stretch.tar.gz
        rm -f MD5SUMS
        testmd5="ko"
    else
        testmd5="ok"
    fi
else
    testmd5="ko"
    fi

}

# Chargement du boot PXE debian Stretch et conf du tftp pour bootPXE
function conf_tftp() {
show_part "Configuration du TFTP"
url_debian="ftp.fr.debian.org/debian"
tftp_menu="/tftpboot/tftp_modeles_pxelinux.cfg/menu/install.menu" 

# vérification de la présence du paquet se3-clonage
if [ ! -e "/usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh" ]
then
    show_info "installation du module Clonage" 
    /usr/share/se3/scripts/install_se3-module.sh se3-clonage
fi

cd /tftpboot
check_md5
if [ "$testmd5" = "ko" ];then
    wget http://$url_debian/dists/stretch/main/installer-amd64/current/images/MD5SUMS
    wget http://$url_debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz -O netboot_stretch.tar.gz
    check_md5
fi

if [ "$testmd5" != "ko" ]; then
    mkdir /tmp/netboot
    tar -xzf netboot_stretch.tar.gz -C /tmp/netboot 
    rm -rf /tftpboot/debian-installer-stretch
    mv  /tmp/netboot/debian-installer /tftpboot/debian-installer-stretch 
    rm -rf /tmp/netboot
    if [ -z "$(grep "DebianStretch64se4ad" $tftp_menu)" ] ; then
        show_info "Ajout du menu d'installation SE4-AD dans le menu TFTP"
        echo "LABEL DebianStretch64se4ad
            MENU LABEL Netboot Debian stretch SE4-^AD (amd64)
            KERNEL  debian-installer-stretch/amd64/linux
            APPEND  auto=true priority=critical preseed/url=http://$se3ip/diconf/se4ad.preseed initrd=debian-installer-stretch/amd64/initrd.gz --
            TEXT HELP
            Installation auto de se4-AD sur Debian Stretch amd64 
            ENDTEXT" >> $tftp_menu
        /usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh menu
    fi
    if [ -z "$(grep "DebianStretch64se4fs" $tftp_menu)" -a "$preseed_se4fs" = "yes" ] ; then
        show_info "Ajout du menu d'installation SE4-FS dans le menu TFTP"
        echo "LABEL DebianStretch64se4fs
            MENU LABEL Netboot Debian stretch SE4-^FS (amd64)
            KERNEL  debian-installer-stretch/amd64/linux
            APPEND  auto=true priority=critical preseed/url=http://$se3ip/diconf/se4fs.preseed initrd=debian-installer-stretch/amd64/initrd.gz --
            TEXT HELP
            Installation auto de se4-FS sur Debian Stretch amd64 
            ENDTEXT" >> $tftp_menu
        /usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh menu
    fi
else
    echo -e "$COLERREUR"
    echo -e "Erreur MD5 du fichier téléchargé"
    echo -e "$COLTXT"
fi
service isc-dhcp-server restart
}

# Affichage message de fin
function display_end_message() {
display_end_title="Génération terminée !!"	
if [ "$preseed_se4fs" = "yes" ];then
    display_end_hight="28"
    display_end_txt="Deux fichiers preseed ont été générés
* Celui de $se4ad_name :
Pour lancer l'installation du serveur $se4ad_name, deux solutions :
- Via un boot PXE sur le se3, partie maintenance, rubrique installation puis  **Netboot Debian stretch SE4-AD**
- Par installation via clé ou CD netboot. vous devrez entrer l'url suivante au debian installeur :
http://$se3ip/diconf/se4ad.preseed
Le mot de passe root temporaire sera fixé à \"se4ad\"

* Celui de se4fs :
Pour lancer l'installation du serveur se4fs, deux solutions :
- Via un boot PXE sur le se3, partie maintenance, rubrique installation puis  **Netboot Debian stretch SE4-FS**
- Par installation via clé ou CD netboot. vous devrez entrer l'url suivante au debian installeur :
http://$se3ip/diconf/se4fs.preseed
Le mot de passe root temporaire sera fixé à \"se4fs\""
else
    display_end_hight="18"
    display_end_txt="Le preseed de $se4ad_name a été généré

Pour lancer l'installation sur serveur $se4ad_name, deux solutions :
- Via un boot PXE sur le se3, partie maintenance, rubrique installation puis  **Netboot Debian stretch SE4-AD**

- Par installation via clé ou CD netboot. vous devrez entrer l'url suivante au debian installeur :
http://$se3ip/diconf/se4ad.preseed

Le mot de passe root temporaire sera fixé à \"se4ad\""
fi
$dialog_box --backtitle "$BACKTITLE" --title "$display_end_title" --msgbox "$display_end_txt" $display_end_hight 70


echo -e "$COLTITRE"
echo "Génération du preseed de $se4ad_name terminée !!
url pour l'installation depuis un support ammovible :  
http://$se3ip/diconf/se4ad.preseed"

if [ "$preseed_se4fs" = "yes" ];then
echo ""
echo "Génération du preseed de $se4fs_name terminée !!
url pour l'installation depuis un support ammovible :  
http://$se3ip/diconf/se4fs.preseed"
fi

echo -e "$COLTXT"
}


######## Debut du Script ########

clear

## recuperation des variables necessaires pour interoger mysql ###
source /etc/se3/config_c.cache.sh
source /etc/se3/config_m.cache.sh
source /etc/se3/config_l.cache.sh
source /usr/share/se3/includes/functions.inc.sh 

# Variables :
dialog_box="$(which whiptail)"
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources"
 

dir_config="/etc/sambaedu"
dir_export="/etc/sambaedu/export_se4ad"
mkdir -p "$dir_export"
dir_preseed="/var/www/diconf"
se4ad_config="$dir_export/se4ad.config"
se4fs_config="$dir_config/sambaedu.conf"
se4fs_config_clients="$dir_config/clients.conf"

script_phase2="install_se4ad_phase2.sh"
nameserver="$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2| head -n 1)"
se4ad_config_tgz="se4ad.config.tgz"

show_title
check_whiptail
search_duplicate_sid
conf_network
preconf_se4ad
ask_preseed_se4fs
if [ "$preseed_se4fs" = "yes" ];then
    preconf_se4fs
    write_se4fs_config
    partman_se4fs
    export_dhcp
fi
export_smb_files
write_se4ad_config
export_ldap_files
export_sql_files
export_cups_config
cp_config_to_preseed
write_apache_config
write_ssh_keys
write_preseed
write_late_command
conf_tftp
display_end_message



# echo "Appuyez sur ENTREE "
exit 0


