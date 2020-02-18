#!/bin/bash
# check and send ip address to email

#MYIP=`ifconfig eth0 | grep 'inet addr'| awk '{print $2}' | cut -d ':' -f 2`;
MYIP=`curl ifconfig.co`
TIME=`date`;

LASTIPFILE='/home/user/.last_ip_addr';
LASTIP=`cat ${LASTIPFILE}`;

if [[ ${MYIP} != ${LASTIP} ]]
then
       echo -e "Cambio de IP\n\nFecha = ${TIME}\nIP = ${MYIP}\n\n" | \
               /usr/bin/mail -s "[INFO] Nueva IP" mail@gmail.com;
       echo ${MYIP} > ${LASTIPFILE};
else
       echo "No hay cambio!!"
fi
