#!/bin/bash

# declare -a list_pid_info
# declare -a list_of_lists

# mudar para a diretoria /proc
cd /proc/

# current_dir="$(pwd)/info.txt"

# COMM=$(awk '/Name:/ {print $2}' status) # nome do pid
# USER= ?? ps -o uname= -p "${pid}"
# PID=$(awk '/^Pid:/' status | tr -dc '0-9') # pid
# MEM=$(awk '/VmSize:/' status | tr -dc '0-9') # quantidade de memoria total
# RSS=$(awk '/VmRSS:/' status | tr -dc '0-9') # quantidade de memoria residente em memoria fisica
# READB=$(awk '/rchar:/' io | tr -dc '0-9') # numero total de bytes de Input
# WRITEB=$(awk '/wchar:/' io | tr -dc '0-9') # numero total de bytes de Ouput
#RATER=??
#RATEW=??

# string="$COMM\t$USER\t$PID\t$MEM\t$RSS\t$READB\t$WRITEB\t$RATERR\t$RATEW"

# echo -e $string > $current_dir
# cat $current_dir

# tenho de tirar / de pid

for pid in */; do
    if [[ -r "$pid/io" ]] && [[ -r "$pid/status" ]];then # checa se tanto io como status sao readable
        echo $pid # pid
        COMM=$(awk '/Name:/ {print $2}' $pid/status)
        USER="$( ps -o uname= -p "${pid}" )"
        READB=$(awk '/rchar:/' $pid/io | tr -dc '0-9')
        echo $COMM
        echo $USER
        echo $READB
        echo -e "\n"
    fi
done
