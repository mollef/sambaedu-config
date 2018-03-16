#!/usr/bin/make -f
# Makefile for sambaedu-config

all:

install:
	mkdir -p $(DESTDIR)/etc/sambaedu
	mkdir -p $(DESTDIR)/usr/share/se3/sbin/
	mkdir -p $(DESTDIR)/var/www/diconf 
	cp usr/share/se3/sbin/* $(DESTDIR)/usr/share/se3/sbin/
	cp -R etc/sambaedu/* $(DESTDIR)/etc/sambaedu/
	cp var/www/diconf/.bashrc $(DESTDIR)/var/www/diconf/
	cp var/www/diconf/.profile $(DESTDIR)/var/www/diconf/
	cp var/www/diconf/* $(DESTDIR)/var/www/diconf/

clean:
