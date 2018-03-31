#!/bin/bash

####Script permettant de migrer la conf Se3  wheezy vers se4 stretch  ####
# ne change rien aux parametres existants
### Auteur : Denis Bonnenfant


# chargement des fonctions de configuration 3 
/usr/share/se3/includes/config.inc.sh -f


mkdir -p /etc/sambaedu/sambaedu.conf.d

echo "# configuration sambaedu" > /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_c.cache.sh >> /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_o.cache.sh >> /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_p.cache.sh >> /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_m.cache.sh >> /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_l.cache.sh >> /etc/sambaedu/sambaedu.conf
sed '/^\s*#/d' /etc/se3/config_s.cache.sh >> /etc/sambaedu/sambaedu.conf

echo "# configuration sambaedu" > /etc/sambaedu/sambaedu.conf.d/dhcp.conf
sed '/^\s*#/d' /etc/se3/config_d.cache.sh >> /etc/sambaedu/sambaedu.conf.d/dhcp.conf

echo "# configuration sambaedu" > /etc/sambaedu/sambaedu.conf.d/backup.conf
sed '/^\s*#/d' /etc/se3/config_b.cache.sh >> /etc/sambaedu/sambaedu.conf.d/backup.conf

chmod -R 700 /etc/sambaedu/sambaedu.conf*
chown -R www-se3 /etc/sambaedu/sambaedu.conf*

# chargement des fonctions de configuration 4

. /usr/share/sambaedu/includes/config.inc.sh

# modification des parametres 
