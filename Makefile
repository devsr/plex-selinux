include /usr/share/selinux/devel/Makefile

define relabel-plex-files
echo "Relabeling files..."
restorecon /etc/sysconfig/PlexMediaServer
restorecon /etc/init.d/plexmediaserver
restorecon -R /var/lib/plexmediaserver
restorecon -R /usr/lib/plexmediaserver
endef

.PHONY: install uninstall

install:
	semodule -v -i plex.pp
	$(relabel-plex-files)

uninstall:
	semodule -v -r plex
	$(relabel-plex-files)	

