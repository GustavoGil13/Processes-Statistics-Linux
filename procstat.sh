#!/bin/bash

declare -a list_pid_info
declare -a list_of_lists
cd /proc/

function get_info {
    
    COMM=$(awk '/Name:/ {print $2}' status) # nome do pid
    USER=$(whoami) # user name
    PID=$(awk '/^Pid:/' status | tr -dc '0-9') # pid
    MEM=$(awk '/VmSize:/' status | tr -dc '0-9') # quantidade de memoria total
    RSS=$(awk '/VmRSS:/' status | tr -dc '0-9') # quantidade de memoria residente em memoria fisica
    READB=$(sudo awk '/rchar:/' io | tr -dc '0-9') # numero total de bytes de Input
    WRITEB=$(sudo awk '/wchar:/' io | tr -dc '0-9') # numero total de bytes de Ouput
    # RATER ??
    # RATEW ??
    list_pid_info=($COMM $USER $PID $MEM $RSS $READB $WRITEB)

    return 0
}
cd 1
get_info
echo ${list_pid_info[*]}

# for pid in */; do
#     echo $pid
# done