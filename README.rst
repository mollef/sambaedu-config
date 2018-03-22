===============
sambaedu-config
===============

scripts de configuration pour migration vers Se4

.. sectnum::
.. contents:: Table des matières

Objectifs
=========

Ce paquet a pour but la mise à disposition des éléments nécessaires à la migration des données ``ldap`` vers un nouveau serveur ``Se4 Active Directory (Se4-AD)``.


Principe de fonctionnement
==========================

En ce qui concerne le serveur ``Se4-AD``, deux choix de fonctionnement exclusifs l'un de l'autre sont proposées :

* Un container de type ``LXC`` qui n'est autre que de la virtualisation allégée.  
* Une machine virtuelle indépendante type ``Proxmox``, ``Xen``, ``ESX``, ou autre. Dans ce cas, on pourra générer automatiquement un preseed permettant ensuite l'installation et la configuration automatique du ``Se4-AD``.

**Important** : Dans un cas comme dans l'autre l'ensemble des éléments de l'annuaire ``LDAP`` d'origine sont récupérés de façon à être injectés lors de la phase de configuration de l'``Active Directory``. 


Installation du paquet ``sambaedu-config``
==========================================

Le paquet ``sambaedu-config`` est installable via les commandes habituelles à condition de `déclarer le dépôt testing sur le serveur Se3. <https://github.com/SambaEdu/se3-docs/blob/master/dev-clients-linux/upgrade-via-se3testing.md>`__

Une fois le dépôt ``testing`` activé, il reste ensuite à installer le paquet : ``apt-get install sambaedu-config``.

Le paquet ``sambaedu-config`` déposera les fichiers de configuration nécessaires ainsi que les scripts d'installation pour ``LXC`` ou génération du fichier ``preseed``.


Choix du container ``LXC``
==========================

L'installation du container ``LXC`` se fait à l'aide d'un script dédié dont l'utilisation le fonctionnement est détaillé.

Durant cette phase on installe de façon automatique un container ``Stretch`` et on y dépose une archive contenant les paramètres importants du ``Se3`` et son  annuaire. Le détail du fonctionnement est indiqué `dans la documentation dédiée. <https://github.com/SambaEdu/se4/blob/master/doc-installation/install-lxc-se4AD.rst>`__


Choix du serveur dédié
======================

Le preseed sera quand à lui généré à l'aide de la commande ``/usr/share/se3/sbin/gen_se4_preseed.sh``. Il sera ensuite possible d'`installer le serveur en utilisant le serveur TFTP du Se3 ou un support ammovible.  <https://github.com/SambaEdu/se4/blob/master/doc-installation/gen-preseed-se4AD.rst>`__


Roadmap - todolist
==================

* Ecriture du script d'installation de la machine LXC **fait !**
* Ecriture du script de génération preseed **fait !**
* Ecriture du script preseed **fait !**
* Packaging de l'ensemble dans sambaedu-config **fait !**
* Ecriture de script de vérification du bon état de l'AD 
* Ecriture du script de migration Se3 ---> Se4-FS
