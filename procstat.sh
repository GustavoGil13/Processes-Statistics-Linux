#!/bin/bash

declare -a read_write
declare -a pid_list

LC_ALL=en_US.utf8
current_dir="$(pwd)/info.txt"
cd /proc/

order_option=1
head_print=0
cat_full_file=0

segundos=${*: -1}

#-------------Sort Alfabético por defeito-------------#
function sort_default
{
    if (( $cat_full_file==0 )); then
        sort -k1 -o $current_dir $current_dir
    fi

    return 0
}
#-----------------------------------------------------#


#-----------------Valor usado em '-u'-----------------#
function get_user
{   
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        word=${array[1]}
        if [[ $word != $1 ]]; then
            sed -i "${counter}d" $current_dir 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$current_dir"

    n_lines=$(wc -l $current_dir | awk '{print $1}')
    if (( n_lines==0 )); then
        echo "User not found"
        rm $current_dir
        exit 1
    fi

    return 0
}
#-------------------------------------------------------#


#-----------------Valor usado em '-c'-------------------#
function get_pattern
{
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        word=${array[0]}
        if [[ ! $word =~ $1 ]]; then
            sed -i "${counter}d" $current_dir 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$current_dir"

    n_lines=$(wc -l $current_dir | awk '{print $1}')
    if (( n_lines==0 )); then
        echo "Pattern not found"
        rm $current_dir
        exit 1
    fi

    return 0
}
#-------------------------------------------------------#


#-----------------Valor usado em '-e'-------------------#
function remove_smaller_dates
{
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        date1="${array[9]} ${array[10]} ${array[11]}"
        data=$(date -d "$date1" +%s)
        if (( $data <= $1 )); then
            sed -i "${counter}d" $current_dir 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$current_dir"

    n_lines=$(wc -l $current_dir | awk '{print $1}')
    if (( n_lines==0 )); then
        echo "No dates found"
        rm $current_dir
        exit 1
    fi

    return 0
}
#-------------------------------------------------------#


#-----------------Valor usado em '-s'-------------------#
function remove_bigger_dates
{
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        date1="${array[9]} ${array[10]} ${array[11]}"
        data=$(date -d "$date1" +%s)
        if (( $data >= $1 )); then
            sed -i "${counter}d" $current_dir 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$current_dir"

    n_lines=$(wc -l $current_dir | awk '{print $1}')
    if (( n_lines==0 )); then
        echo "No dates found"
        rm $current_dir
        exit 1
    fi

    return 0
}
#-------------------------------------------------------#

i=0
j=0
for pid in */; do
    if [[ $pid = [0-9]* ]] && [[ -r "$pid/io" ]] && [[ -r "$pid/status" ]]; then
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

#----------------------------------------------------Valores de cada parâmetro e cálculos necessários----------------------------------------------------#
i=0
for pid in "${pid_list[@]}"; do

    PID=$(perl -pe 's/\///g' <<< "$pid") 
    COMM=$(cat $pid/comm)
    USER="$( ps -o uname= -p "${PID}" )"
    MEM=$(awk '/VmSize:/' $pid/status | tr -dc '0-9') # quantidade de memoria total
    RSS=$(awk '/VmRSS:/' $pid/status | tr -dc '0-9') # quantidade de memoria residente em memoria fisica
    DATE=$(ps -olstart= $PID | awk '{print $2,$3,$4}')
    
    READB1=${read_write[$i]}
    WRITEB1=${read_write[$(( $i+1 ))]}
    READB2=$(awk '/rchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Input
    WRITEB2=$(awk '/wchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Ouput

    RATER=$( bc -l <<< $(( READB2 - READB1 ))/$segundos )
    RATEW=$( bc -l <<< $(( WRITEB2 - WRITEB1 ))/$segundos )

    printf "%-20s %-10s %10s %10s %10s %15s %15s %15.2f %15.2f %20s\n" $COMM $USER $PID $MEM $RSS $READB2 $WRITEB2 $RATER $RATEW "$DATE" >> $current_dir
    i=$(( $i+2 ))
done
#---------------------------------------------------------------------------------------------------------------------------------------------------------#

sort_default

while getopts ":c:s:e:u:p:tdwrm" opt; do 
    case ${opt} in
        m)  # sort by decreasing MEMORY  
            cat_full_file=1
            order_option=4
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        t)  # sort by decreasing RSS
            cat_full_file=1
            order_option=5
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        d)  # sort by decreasing RATER
            cat_full_file=1
            order_option=8
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        w)  # sort by decreasing RATEW
            cat_full_file=1
            order_option=9
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        r)  # reverse last sort
            cat_full_file=1
            sort --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        p)  # print n lines
            line_number=$OPTARG
            head_print=1
            ;;
        c)  # print by user
            sort_default
            get_pattern "$OPTARG"
            ;;
        u)  # print by pattern
            sort_default
            get_user "$OPTARG"
            ;;
        s)  # removes dates that are smaller than the date that is given 
            sort_default
            given_date=$(date -d "$OPTARG" +%s)
            remove_smaller_dates "$given_date"
            ;;
        e)  # removes dates that are bigger than the date that is given 
            sort_default      
            given_date=$(date -d "$OPTARG" +%s)
            remove_bigger_dates "$given_date"
            ;;
        \? ) # if none of the corret arguments are passed
            echo "Usage: cmd [-c] [-s] [-e] [-u] [-p] [-m] [-t] [-d] [-w] [-r]"
            ;;
        : ) # if an option does not get an argument that it needs
            echo "Invalid option: $OPTARG requires an argument"
        ;;
    esac
done

if (( $head_print==1 )); then 
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    head -n $line_number $current_dir
else
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    cat $current_dir
fi

rm $current_dir
