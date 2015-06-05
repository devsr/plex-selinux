# SELinux policy module for Plex Media Server

*DISCLAIMER: This project is not an official Plex project, and is not supported
or endorsed by Plex.*

This is an SELinux policy module that defines a domain to confine Plex Media
Server and associated processes. By default, Plex Media Server runs in the
`initrc_t` domain. This gives Plex Media Server far more access to the system
than it needs to do its job. Installing this policy module will confine Plex
Media Server in its own domain with a tailored set of access controls.

This policy module should not interfere with Plex's normal operation except
where noted (i.e Web UI file browser). If you find something is not working
correctly please open an issue.

Bug reports and patches are welcome.

### Support Status

Supported Platforms: CentOS 6, CentOS 7

Supported Plex Media Server Version: 0.9.12.1.1079-b655370.x86_64

### Current Release Notes

The current version of Plex Media Server ships with a library
`/usr/lib/plexmediaserver/libgnsdk_dsp.so.3.07.5` that has the `execstack` flag
set. This flag must be cleared for SELinux to allow Plex to run.

This can be done with the `execstack` command (part of the `prelink` package)
as root.

    # execstack -c /usr/lib/plexmediaserver/libgnsdk_dsp.so.3.07.5


## Building

### Requirements

In order to build and install this policy module you will need the following
packages installed:

* make
* selinux-policy
* policycoreutils-python

### Build

	$ make

### Install

Installs the policy package and relabels Plex Media Server files to new file
contexts.

(as root)

	# make install

### Uninstall

Uninstalls the policy module from the system and relabels Plex Media Server
files to the default file contexts.

(as root)

	# make uninstall


## Policy Details

### Domain

SELinux uses domains to label processes. The domain of a confined process
defines what access controls the process is subjected to.

The security context of a process can be inspected by adding the `-Z` option to
the `ps` command

	$ ps -eZ | grep plex_t
	unconfined_u:system_r:plex_t:s0  7174 ?        00:00:04 Plex Media Serv
	unconfined_u:system_r:plex_t:s0  7281 ?        00:00:16 Plex DLNA Serve
	unconfined_u:system_r:plex_t:s0  7865 ?        00:00:39 python

This policy module defines the domain `plex_t` for Plex Media Server processes.


### File Contexts

SELinux requires that files be labeled with a security context so it knows what
access controls to apply. This security context is usually stored in an extended
attribute on the file.

The security context of a file can be inspected by using the `-Z` option with
the `ls` command.

	$ ls -Z /var/lib/plexmediaserver
	drwxr-xr-x. plex plex unconfined_u:object_r:plex_var_lib_t:s0 Library

A file's security context can be changed temporarily using `chcon`. These
changes will not survive a relabeling.

	$ chcon -R /usr/share/my_media_library

A file's security context can be changed permanently by using `semanage fcontext`
to define the default security context for a given set of files and then using
`restorecon` to apply those labels.

	$ semanage fcontext -a -t plex_content_t "/usr/share/my_media_library(/.*)?"
	$ restorecon -v -R /usr/share/my_media_library

This policy module defines the following file contexts:

##### plex\_content\_t and plex\_content\_rw\_t

These file contexts are for labeling media files and directories that processes
confined by `plex_t` should be allowed to read (`plex_content_t`) or manage
(`plex_content_rw_t`).
<br />
<br />
##### plex\_etc\_t

Plex Media Server configuration files.
<br />
<br />

##### plex\_initrc\_exec\_t

Plex Media Server init.d scripts.
<br />
<br />

##### plex\_exec\_t

Plex Media Server executables. Files labeled with this context will create
processes in the `plex_t` domain when called from certain domains
(notably `init_t` and `initrc_t`). Generally a transition to `plex_t` will not
occur if the calling process is `unconfined_t` (the standard user context in
the targeted policy). This means if a user calls the executable from a shell
the resulting process **will not** be confined.
<br />
<br />

##### plex\_var\_lib\_t

Plex Media Server `/var/lib` files. Processes confined by `plex_t` can manage
files and directories in this domain.
<br />
<br />

##### plex\_tmp\_t and plex\_tmpfs\_t

Plex Media Server temporary files and objects. Processes confined by `plex_t`
can manage files and directories in this domain.
<br />
<br />

##### Executable contexts

Processes confined by `plex_t` have permission to execute files in the
following security contexts:

* `plex_exec_t`
* `plex_var_lib_t`
* `plex_tmp_t`
* `plex_tmpfs_t`
* `rsync_exec_t`
* `bin_t`
* `shell_exec_t`

Processes created from executables in these contexts will be confined by `plex_t`.
<br />
<br />

##### Shared contexts

Processes confined by `plex_t` have read access to the following
shared file contexts:

* `public_content_t`
* `public_content_rw_t`

This is useful if you want label media files to be readable by processes in
domains other than `plex_t` (Apache, NFS, Samba, FTP, etc)
<br />
<br />

### Networking

Processes confined by `plex_t` have the following network capabilities:

* May connect TCP sockets to `port_t`
* May connect TCP sockets to `http_port_t`
* May bind UDP sockets to `port_t`
* May send and receive UDP packets to/from all ports.


### Booleans

SELinux booleans can be used to adjust the access controls enforced for
`plex_t`. Default settings (off) result in tightest security. Enabling a boolean
will loosen access controls and allow `plex_t` confined processes more access
to the system.

The status of booleans can be inspected using `getsebool`

	$ getsebool -a | grep plex
	allow_plex_access_home_dirs_rw --> off
	allow_plex_anon_write --> off
	allow_plex_list_all_dirs --> off
	plex_access_all_ro --> off
	plex_access_all_rw --> off

A boolean can be turned on or off using `setsebool`

(as root)

`# setsebool allow_plex_list_all_dirs on`

A `-P` option can be passed to `setsebool` that makes the setting persist
across reboots.

This policy modules defines the following booleans:

##### plex\_access\_all\_ro

Allow processes contained by `plex_t` to read all files and directories.
<br />
<br />

##### plex\_access\_all\_rw

Allow processes contained by `plex_t` to manage (read, write, create, delete)
all files and directories.
<br />
<br />

##### allow\_plex\_list\_all\_dirs

Allow processes contained by `plex_t` to list (search and read) all directories.

Note that this boolean will allow the directory browser in Plex's Web UI to work
correctly. Attempting to use the directory browser without enabling this boolean
will cause a large number of AVC denials to be logged. If this boolean is off,
directory paths should be typed in the path bar instead of browsed for.
<br />
<br />

##### allow\_plex\_anon\_write

Allow processes contained by `plex_t` to manage (read, write, create, delete)
files and directories labeled with the `public_content_rw_t` context.
<br />
<br />

##### allow\_plex\_access\_home\_dirs\_rw

Allow processes contained by `plex_t` to manage (read, write, create, delete)
files and directories in user home directories.
<br />
<br />

---

*Copyright (c) 2014 Devin Reid*

*This project is licensed under the terms of the MIT license. Please see
included LICENSE file or visit http://opensource.org/licenses/MIT*
