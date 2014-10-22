# Copyright (c) 2014 Devin Reid
#
# Permission is granted to use, distribute and modify this work
# in compliance with the terms of the MIT license.
#
# A copy of the MIT license can be found in the LICENSE file that
# accompanied this work or by visiting http://opensource.org/licenses/MIT

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

