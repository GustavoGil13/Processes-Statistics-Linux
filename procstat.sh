#!/bin/bash

declare -a list_pid_info
declare -a read_write
declare -a pid_list

LC_ALL=en_US.utf8

# HEADER=("COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE")
current_dir="$(pwd)/info.txt"

# mudar para a diretoria /proc
cd /proc/
segundos=2

i=0
j=0
for pid in */; do
    if [[ -r "$pid/io" ]] && [[ -r "$pid/status" ]]; then
        pid_list[$i]=$pid
        READB=$(awk '/rchar:/' $pid/io | tr -dc '0-9')
        WRITEB=$(awk '/wchar:/' $pid/io | tr -dc '0-9')
        read_write[$j]=$READB
        read_write[$(( $j+1 ))]=$WRITEB
        i=$(( $i+1 ))
        j=$(( $j+2 ))
    fi
done

sleep $segundos
# echo ${pid_list[*]}
# echo ${read_write[*]}

i=0
for pid in "${pid_list[@]}"; do

    PID=$(perl -pe 's/\///g' <<< "$pid") 
    COMM=$(awk '/Name:/ {print $2}' $pid/status)
    USER="$( ps -o uname= -p "${PID}" )"
    MEM=$(awk '/VmSize:/' $pid/status | tr -dc '0-9') # quantidade de memoria total
    RSS=$(awk '/VmRSS:/' $pid/status | tr -dc '0-9') # quantidade de memoria residente em memoria fisica
    # DATE=??
    
    READB1=${read_write[$i]}
    WRITEB1=${read_write[$(( $i+1 ))]}
    READB2=$(awk '/rchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Input
    WRITEB2=$(awk '/wchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Ouput

    RATER=$( bc -l <<< $(( READB2 - READB1 ))/$segundos )
    RATEW=$( bc -l <<< $(( WRITEB2 - WRITEB1 ))/$segundos )

    printf "%-20s %-10s %10s %10s %10s %15s %15s %15.2f %15.2f\n" $COMM $USER $PID $MEM $RSS $READB2 $WRITEB2 $RATER $RATEW >> $current_dir # $DATE
    i=$(( $i+2 ))
done

printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %15s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
cat $current_dir
rm $current_dir