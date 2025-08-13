#!/bin/bash

freeSpace=$(free -mt | grep Total | awk '{print $4}')

Threesold=200

sendemail() {
TO="s1998pawan@gmail.com"
SUBJECT="Test Email"
FROM="you@example.com"
BODY="This is the body of the email."

    (
    cat <<EOF
Subject: $SUBJECT
To: $TO
From: $FROM

$BODY
EOF
    ) | sendmail -t
    
}

if [ $freeSpace -lt $Threesold ]
then
    echo "Wraning : available space is running low"
else 
    echo "Enough available space"
    sendmail
fi





