===============
sambaedu-config
===============

scripts de configuration pour migration vers Se4

.. sectnum::
.. contents:: Table des matières

Objectifs
=========

Ce paquet a pour but la mise à disposition des éléments nécessaires à la migration des données ldap vers un nouveau serveur Se4 Active Directory.

Principe de fonctionnement
==========================

En ce qui concerne le serveur Se4-AD, deux choix de fonctionnement sont proposées :

* Un container de type LXC.  
* Une machine virtuelle indépendante type Proxmox ou autre. Dans ce cas, on pourra générer automatiquement un preseed permettant ensuite l'installation et la configuration automatique du Se4-AD

Dans un cas comme dans l'autre l'ensemble des éléments de l'annuaire LDAP d'origine sont récupérés de façon à être injectés dans L'Active Directory lors de la seconde phase de l'installation. `Cette partie est décrite sur cette documentation <https://github.com/SambaEdu/se4/blob/master/doc-installation/install-se4AD.rst>`__

Installation du paquet
======================

Le paquet est installable via les commandes habituelles à condition de déclarer le dépôt testing sur le serveur Se3

Rappel de la procédure dans la documentation dédiée https://github.com/SambaEdu/se3-docs/blob/master/dev-clients-linux/upgrade-via-se3testing.md

Il reste ensuite à installer le paquet : ``apt-get install sambaedu-config``

Cela aura pour effet de déposer les fichiers de configuration nécessaires dans /etc/sambaedu ainsi que les scripts d'installation pour LXC ou génération du preseed.

Installer un container LXC ou générer un preseed
================================================

* L'installation du container se fait à l'aide du script ``/usr/share/se3/sbin/install_se4lxc.sh``. Durant cette phase on installe de façon automatique un container Stretch et on y dépose une archive contenant les paramètres importants du Se3 et son  annuaire. Le détail du fonctionnement est indiqué dans la documentation suivante : https://github.com/SambaEdu/se4/blob/master/doc-installation/install-lxc-se4AD.rst

* Le preseed sera quand à lui généré à l'aide de la commande ``/usr/share/se3/sbin/install_se4preseed.sh``. Il sera ensuite disponible sur le serveur web du Se3 dans son dossier "install". L'url à utiliser pour le preseed sera donc. Pour plus de détails, se repporter à la documentation du script **A compléter**: https://github.com/SambaEdu/se4/tree/master/doc-installation


Roadmap - todolist
==================

* Ecriture du script preseed **(en cours)**
* Ecriture de script de vérification du bon état de l'AD 
* Ecriture du script de migration Se3 ---> Se4-FS