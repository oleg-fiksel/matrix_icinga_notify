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
  -e SERVICENAME (\$service.name\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o SERVICEOUTPUT (\$service.output\$)
  -s SERVICESTATE (\$service.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)
  -u SERVICEDISPLAYNAME (\$service.display_name\$)

Optional parameters:
  -4 HOSTADDRESS (\$address\$)
  -6 HOSTADDRESS6 (\$address6\$)
  -b NOTIFICATIONAUTHORNAME (\$notification.author\$)
  -c NOTIFICATIONCOMMENT (\$notification.comment\$)
  -i ICINGAWEB2URL (\$notification_icingaweb2url\$, Default: unset)

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
while getopts 4:6:b:c:d:e:hi:l:n:o:s:t:u:v: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    e) SERVICENAME=$OPTARG ;; # required
    h) Usage ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) SERVICEOUTPUT=$OPTARG ;; # required
    s) SERVICESTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    u) SERVICEDISPLAYNAME=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Usage ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Usage ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Usage ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-host-notification.sh
for P in LONGDATETIME HOSTNAME HOSTDISPLAYNAME SERVICENAME SERVICEDISPLAYNAME SERVICEOUTPUT SERVICESTATE NOTIFICATIONTYPE ; do
        eval "PAR=\$${P}"

        if [ ! "$PAR" ] ; then
                Error "Required parameter '$P' is missing."
        fi
done

if [ "$SERVICESTATE" = "CRITICAL" ]
then
        s_color=#FF5566
        ico="☢"

elif [ "$SERVICESTATE" = "WARNING" ]
then
        s_color=#FFAA44
        ico="⚠"

elif [ "$SERVICESTATE" = "UNKNOWN" ]
then
        s_color=#90A4AE
        ico="?"

elif [ "$SERVICESTATE" = "DOWN" ]
then
        s_color=#FF5566
        ico="!"

#else [ "$SERVICESTATE" = "OK" ]
#then
else
        s_color=#44BB77
        ico="✓"
fi

## Build the notification message
NOTIFICATION_MESSAGE=`cat << EOF
$ico<font color="$s_color"><strong>***** Service Monitoring on $ICINGA2HOST *****</font></strong><br>
<!-- -->
<strong>Type:</strong>&emsp;&emsp;&ensp;&#160; $NOTIFICATIONTYPE<br>
<!-- -->
<strong>Message: &emsp;$SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is <font color="$s_color">$SERVICESTATE!</font></strong><br>
<!-- -->
<strong>Info:</strong><br>
<font color="$s_color">$SERVICEOUTPUT</font><br>
<!-- -->
<strong>When:</strong>&emsp;&emsp;&#160; $LONGDATETIME<br>
<!-- -->
<strong>Service:</strong>&emsp;&ensp; $SERVICENAME<br>
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
<strong>Link:</strong>&emsp;&emsp;&emsp;<a href=$ICINGAWEB2URL/monitoring/service/show?host=$(urlencode "$HOSTNAME")&service=$(urlencode "$SERVICENAME")>Show in Icinga2</a>"
fi

/usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | /opt/matrix_icinga_notify/send_message.pl -c /run/secrets/my-config.cfg
