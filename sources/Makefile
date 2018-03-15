#!/usr/bin/make -f
# Makefile for sambaedu-config

all:

install:
	mkdir -p $(DESTDIR)/etc/sambaedu
	mkdir -p $(DESTDIR)/usr/share/se3/sbin/
	mkdir -p $(DESTDIR)/var/www/install/se4ad/ 
	cp usr/share/se3/sbin/* $(DESTDIR)/usr/share/se3/sbin/
	cp -R etc/sambaedu/* $(DESTDIR)/etc/sambaedu/
	cp var/www/diconf* $(DESTDIR)/var/www/diconf/

clean:
