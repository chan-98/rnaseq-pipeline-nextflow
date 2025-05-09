#!/bin/bash -ue

host_ip=`ifconfig 2>/dev/null|grep inet|grep 255.255.252.0|sed -e's/^[ ]*//'|cut -d' ' -f2`
email=$(basename "$MAIL")
email="${email:0:-4}"
email="${email}@umassmed.edu"

current_user=`echo ${LOGNAME}@hpc.umassmed.edu`

 

#interactive_date=$(date -d "@$LSF_JOB_TIMESTAMP_VALUE" +"%Y-%m-%d %H:%M:%S")
#echo "Starting ... [Interactive session started at ${interactive_date}]"
echo -e "Hello\n\nYour DEBrowser session has started on the UMass HPC.\n\nYou can connect from UMass Chan Open OnDemand SCI Desctop using the following link http://${host_ip}:8088\n\nor create an SSH tunnel with this command 'ssh -L 8088:${host_ip}:8088 ${current_user}'\n\nand connect using your local pc at 127.0.0.1:8088"|/usr/bin/mail -s 'DEBrowser started on HPC' ${email}
exec singularity exec --pid ${HOME}/.singularity/danhumassmed-debrowser-1.0.1.img Rscript /startDEBrowser.R




