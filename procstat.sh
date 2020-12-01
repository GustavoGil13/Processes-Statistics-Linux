#!/bin/bash
declare -a read_write
declare -a pid_list

LC_ALL=en_US.utf8
txt_file="$(pwd)/info.txt"
cd /proc/

order_option=1
head_print=0
cat_full_file=0
seconds=0

#--------checks if the number of seconds are passed--------#
if (( $#==0 )); then
    echo "ERROR: Number of seconds for sleep MUST be passed"
    echo "TRY: ./procstat.sh number"
    exit 1
elif (( $#==1 )) || [[ $1 = [0-9]* ]]; then
    seconds=$1
else
    args=("$@")
    for ((i = 1; i < ${#args[@]}; i++)); do
        if [[ ${args[i]} = [0-9]* ]] && [[ ${args[$(($i-1))]} != "-p" ]]; then
            seconds=${args[i]}
        fi
    done

    if (( $seconds==0 )); then
        echo "ERROR: Number of seconds for sleep MUST be passed"
        echo "TRY: ./procstat.sh number"
        exit 1
    fi
fi
#--------------------------------------------------------#

#--------------alphabetical sort by default-------------#
function sort_default
{
    if (( $cat_full_file==0 )); then
        sort -k1 -o $txt_file $txt_file
    fi

    return 0
}
#-------------------------------------------------------#


#-----------------Function used for '-u' argument----------------#
function get_user
{   
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        word=${array[1]}
        if [[ $word != $1 ]]; then
            sed -i "${counter}d" $txt_file 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$txt_file"

    n_lines=$(wc -l $txt_file | awk '{print $1}')
    if (( $n_lines==0 )); then
        echo "No PID's created by $1 were found"
        rm $txt_file
        exit 1
    fi

    return 0
}
#------------------------------------------------------#


#----------------Function used for '-c' option----------------#
function get_from_expression
{
    counter=1
    while IFS= read -r line
    do
        array=( $line )
        word=${array[0]}
        if [[ ! $word =~ $1 ]]; then
            sed -i "${counter}d" $txt_file 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$txt_file"

    n_lines=$(wc -l $txt_file | awk '{print $1}')
    if (( $n_lines==0 )); then
        echo "No PID's names with $1 were found"
        rm $txt_file
        exit 1
    fi

    return 0
}
#-----------------------------------------------------#


#-----------------Function used for '-e' option--------------#
function remove_smaller_dates
{
    counter=1
    d=$1
    date1=$(date -d "$d" +%s)
    while IFS= read -r line
    do
        array=( $line )
        date2="${array[9]} ${array[10]} ${array[11]}"
        date3=$(date -d "$date2" +%s)
        if (( $date3 <= $date1 )); then
            sed -i "${counter}d" $txt_file 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$txt_file"

    n_lines=$(wc -l $txt_file | awk '{print $1}')
    if (( $n_lines==0 )); then
        echo "No PID's older than $d were found"
        rm $txt_file
        exit 1
    fi

    return 0
}
#-----------------------------------------------------#


#---------------Function used for '-s' option----------------#
function remove_bigger_dates
{
    counter=1
    d=$1
    date1=$(date -d "$d" +%s)
    while IFS= read -r line
    do
        array=( $line )
        date2="${array[9]} ${array[10]} ${array[11]}"
        date3=$(date -d "$date2" +%s)
        if (( $date3 >= $date1 )); then
            sed -i "${counter}d" $txt_file 
            counter=$(( $counter-1 ))
        fi
        counter=$(( $counter+1 ))
    done < "$txt_file"

    n_lines=$(wc -l $txt_file | awk '{print $1}')
    if (( $n_lines==0 )); then
        echo "No PID's younger than $d were found"
        rm $txt_file
        exit 1
    fi

    return 0
}
#----------------------------------------------------#

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

sleep $seconds

#----------------------------------------------------Value of each parameter and the necessary calculations----------------------------------------------------#
i=0
for pid in "${pid_list[@]}"; do

    PID=$(perl -pe 's/\///g' <<< "$pid") 
    COMM=$(cat $pid/comm)
    USER="$( ps -o uname= -p "${PID}" )"
    MEM=$(awk '/VmSize:/' $pid/status | tr -dc '0-9')
    RSS=$(awk '/VmRSS:/' $pid/status | tr -dc '0-9')
    DATE=$(ps -olstart= $PID | awk '{print $2,$3,$4}' | cut -d: -f1-2 )
    
    READB1=${read_write[$i]}
    WRITEB1=${read_write[$(( $i+1 ))]}
    READB2=$(awk '/rchar:/' $pid/io | tr -dc '0-9')
    WRITEB2=$(awk '/wchar:/' $pid/io | tr -dc '0-9')

    RATER=$( bc -l <<< $(( READB2 - READB1 ))/$seconds )
    RATEW=$( bc -l <<< $(( WRITEB2 - WRITEB1 ))/$seconds )

    printf "%-20s %-10s %10s %10s %10s %15s %15s %15.2f %15.2f %20s\n" $COMM $USER $PID $MEM $RSS $READB2 $WRITEB2 $RATER $RATEW "$DATE" >> $txt_file
    i=$(( $i+2 ))
done
#---------------------------------------------------------------------------------------------------------------------------------------------------------#

sort_default

while getopts ":c:s:e:u:p:tdwrm" opt; do 
    case ${opt} in
        m)  # sort by decreasing MEMORY  
            cat_full_file=1
            order_option=4
            sort -r --key $order_option --numeric-sort -o $txt_file $txt_file
            ;;
        t)  # sort by decreasing RSS
            cat_full_file=1
            order_option=5
            sort -r --key $order_option --numeric-sort -o $txt_file $txt_file
            ;;
        d)  # sort by decreasing RATER
            cat_full_file=1
            order_option=8
            sort -r --key $order_option --numeric-sort -o $txt_file $txt_file
            ;;
        w)  # sort by decreasing RATEW
            cat_full_file=1
            order_option=9
            sort -r --key $order_option --numeric-sort -o $txt_file $txt_file
            ;;
        r)  # reverse last sort
            cat_full_file=1
            sort --key $order_option --numeric-sort -o $txt_file $txt_file
            ;;
        p)  # print n lines
            line_number=$OPTARG
            head_print=1
            ;;
        c)  # print by user
            sort_default
            get_from_expression "$OPTARG"
            ;;
        u)  # print by pattern
            sort_default
            get_user "$OPTARG"
            ;;
        s)  # removes dates that are smaller than the date that is given 
            sort_default
            remove_smaller_dates "$OPTARG"
            ;;
        e)  # removes dates that are bigger than the date that is given 
            sort_default      
            remove_bigger_dates "$OPTARG"
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
    head -n $line_number $txt_file
else
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    cat $txt_file
fi

rm $txt_file
