#!/bin/bash

#Configuration
LDAP_HOST=""
LDAP_OU=""
OUTLOGDIR=""

DATE="$(date +%Y-%m-%d_%H-%M-%S)"
TEMP="tmp.txt"
TEMP2="tmp2.txt"
LDAP="ldap-export.txt"
OUTLOG="audit-log-`hostname`-"$DATE".log"

if [ ! -d "$OUTLOGDIR" ]; then
	mkdir $OUTLOGDIR
fi
mkdir "$OUTLOGDIR"/work && cd "$OUTLOGDIR"/work

#Pull LDAP Users
ldapsearch -x -b "$LDAP_OU" -H "$LDAP_HOST" > "$LDAP"
#Process LDAP users list to UID/UIDnumber
sed -i '/^\(uidNumber\|uid\)/!d' "$LDAP"
#Process Epoch date + UID into temp files for filestream manipulation
awk '/cmd="su"/ {print $2}' /var/log/audit/audit.log | sed 's/\..*$//' | sed 's/msg=audit(//g' > "$TEMP"
awk '/cmd="su"/ {print $4}' /var/log/audit/audit.log | sed 's/uid=//g' > "$TEMP2"

echo "====== SU Report $DATE `hostname` ======" > "$OUTLOG"
while read uid;
do
	while read line;
	do
		while read a b; 
		do
			if [ "$uid" == "$b" ];
			then
				#Transform Epoch date into Human Readable and echo to Log
				PROCESSED="$(date -d @"$line")"
				echo "$PROCESSED - $NAME" >> $OUTLOG
				#Remove leading line of Datefile
				tail -n +2 "$TEMP" > "$TEMP.tmp" && mv "$TEMP.tmp" "$TEMP"
				break
			else
				NAME="$b"
			fi
		done < "$LDAP"
		break
	done < "$TEMP"
done < "$TEMP2"
IFS=
echo $(cat "$OUTLOG")

#Cleanup
mv "$OUTLOG" "$OUTLOGDIR" && rm -rf "$OUTLOGDIR"/work
