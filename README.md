# Matrix icinga notifier

# Dependencies

* CPANM: `cpanm LWP LWP::Protocol::https`
* Ubuntu: `apt-get install -y libwww-perl`

# Getting access token

* `curl -XPOST -d {type:m.login.password, user:username, password:MyVerySecurePassword} "https://server.domain.com:8448/_matrix/client/r0/login"`

# Creating config

* `cp config.cfg-sample my-config.cfg`
* `vim my-config.cfg`

# Creating Icinga (1) notification command

```
################################################################################
# NOTIFICATIONS BY MATRIX
################################################################################

define command{
	command_name	notify-host-by-matrix
	command_line	/usr/bin/printf "%b" "***** Icinga *****<br>Notification Type: $NOTIFICATIONTYPE$<br>Host: <strong>$HOSTNAME$</strong><br>State: <strong>$HOSTSTATE$</strong><br>Address: <strong>$HOSTADDRESS$</strong><br>Info: <pre><code>$HOSTOUTPUT$</code></pre>Date/Time: $LONGDATETIME$" | /opt/matrix_icinga_notify/send_message.pl -c /run/secrets/my-config.cfg
	}

define command{
	command_name	notify-service-by-matrix
	command_line	/usr/bin/printf "%b" "***** Icinga *****<br>Notification Type: $NOTIFICATIONTYPE$<br>Service: <strong>$SERVICEDESC$</strong><br>Host: <strong>$HOSTALIAS$</strong><br>Address: <strong>$HOSTADDRESS$</strong><br>State: <strong>$SERVICESTATE$</strong><br>Date/Time: $LONGDATETIME$<br>Additional Info:<pre><code>$SERVICEOUTPUT$\n$LONGSERVICEOUTPUT$</code></pre>" | /opt/matrix_icinga_notify/send_message.pl -c /run/secrets/my-config.cfg
	}
```

# Icinga (2) config
The `icinga2-code` folder contains the necessary code for matrix notifications in Icinga2. Make sure to place your config with Docker Secrets or Kubernetes Secrets at `/run/secrets/my-config.cfg`or adjust `/run/secrets/my-config.cfg` in the notification scripts to reflect your needs. The same applies to the location of the perl script. It's assumed to be at `/opt/matrix_icinga_notify/send_message.pl`

* `cp -rp icinga2-code/conf.d/ /etc/icinga2/conf.d/`
* `cp -rp icinga2-code/scripts/ /etc/icinga2/scripts/`
* Debian / Ubuntu: `chown nagios:nagios /etc/icinga2/scripts/matrix-*-notification.sh`
* RHEL / CentOS: `chown icinga:icinga /etc/icinga2/scripts/matrix-*-notification.sh`

# Usage

```
# ./send_message.pl --help
echo 'Message text (also <strong>bold</strong>).' | ./send_message.pl -c config.cfg [-ds]
        -c              config file
        -d              debug
        -s              disable SSL cert verification
```
