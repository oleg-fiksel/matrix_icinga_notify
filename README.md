# Matrix icinga notifier

# Dependencies

* `cpanm LWP`

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
