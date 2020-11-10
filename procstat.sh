#!/bin/bash

# declare -a list_pid_info
# declare -a list_of_lists

# mudar para a diretoria /proc
cd /proc/

# current_dir="$(pwd)/info.txt"

# COMM=$(awk '/Name:/ {print $2}' status) # nome do pid
#USER= ??# user name
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

# começar por ver quais e que temos autorização

for pid in */; do
    echo $pid
    COMM=$(awk '/Name:/ {print $2}' $pid/status) # nome do pid
    echo $COMM
done