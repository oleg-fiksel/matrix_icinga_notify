#!/bin/sh
#
# Copyright (C) 2012-2018 Icinga Development Team (https://icinga.com/)
# Except of function urlencode which is Copyright (C) by Brian White (brian@aljex.com) used under MIT license 

PROG="`basename $0`"
ICINGA2HOST="`hostname`"

## Function helpers
Usage() {
cat << EOF

Required parameters:
  -d LONGDATETIME (\$icinga.long_date_time\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o HOSTOUTPUT (\$host.output\$)
  -s HOSTSTATE (\$host.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)

Optional parameters:
  -4 HOSTADDRESS (\$address\$)
  -6 HOSTADDRESS6 (\$address6\$)
  -b NOTIFICATIONAUTHORNAME (\$notification.author\$)
  -c NOTIFICATIONCOMMENT (\$notification.comment\$)
  -i ICINGAWEB2URL (\$notification_icingaweb2url\$, Default: unset)
  -v (\$notification_sendtosyslog\$, Default: false)

EOF
}

Help() {
  Usage;
  exit 0;
}

Error() {
  if [ "$1" ]; then
    echo $1
  fi
  Usage;
  exit 1;
}

urlencode() {
  local LANG=C i=0 c e s="$1"

  while [ $i -lt ${#1} ]; do
    [ "$i" -eq 0 ] || s="${s#?}"
    c=${s%"${s#?}"}
    [ -z "${c#[[:alnum:].~_-]}" ] || c=$(printf '%%%02X' "'$c")
    e="${e}${c}"
    i=$((i + 1))
  done
  echo "$e"
}

## Main
while getopts 4:6::b:c:d:hi:l:n:o:s:t:v: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    h) Help ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) HOSTOUTPUT=$OPTARG ;; # required
    s) HOSTSTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-service-notification.sh
for P in LONGDATETIME HOSTNAME HOSTDISPLAYNAME HOSTOUTPUT HOSTSTATE NOTIFICATIONTYPE ; do
  eval "PAR=\$${P}"

  if [ ! "$PAR" ] ; then
    Error "Required parameter '$P' is missing."
  fi
done

if [ "$HOSTSTATE" = "DOWN" ]
then
        h_color=#FF5566
        ico="☢"

#else [ "$HOSTSTATE" = "UP" ]
#then
else
        h_color=#44BB77
        ico="✓"
fi

## Build the notification message
NOTIFICATION_MESSAGE=`cat << EOF
$ico<font color="$h_color"><strong>***** Host Monitoring on $ICINGA2HOST *****</font></strong><br>
<!-- -->
<strong>Type:</strong>&emsp;&emsp;&ensp;&#160; $NOTIFICATIONTYPE<br>
<!-- -->
<strong>Message: &emsp;$HOSTDISPLAYNAME is <font color="$h_color">$HOSTSTATE!</font></strong><br>
<!-- -->
<strong>Info:</strong><br>
<font color="$h_color">$HOSTOUTPUT</font><br>
<!-- -->
<strong>When:</strong>&emsp;&emsp;&#160; $LONGDATETIME<br>
<!-- -->
<strong>Host:</strong>&emsp;&emsp;&emsp;$HOSTNAME<br>
EOF
`

## Check whether IPv4 was specified.
if [ -n "$HOSTADDRESS" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>IPv4:</strong>&emsp;&emsp;&emsp; $HOSTADDRESS<br>"
fi

## Check whether IPv6 was specified.
if [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>IPv6:</strong>&emsp;&emsp;&emsp;  $HOSTADDRESS6<br>"
fi

## Check whether author and comment was specified.
if [ -n "$NOTIFICATIONCOMMENT" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE

<strong>Comment: </strong>&#160;
<font color="#3333ff">$NOTIFICATIONCOMMENT</font> by <font color="#c47609">$NOTIFICATIONAUTHORNAME</font><br>"
fi

## Check whether Icinga Web 2 URL was specified.
if [ -n "$ICINGAWEB2URL" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Link:</strong>&emsp;&emsp;&emsp;<a href=$ICINGAWEB2URL/monitoring/show?host=$(urlencode "$HOSTNAME")>Show in Icinga2</a>"
fi

/usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | /opt/matrix_icinga_notify/send_message.pl -c /run/secrets/my-config.cfg
