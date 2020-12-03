#!/bin/bash
declare -a read_write
declare -a pid_list

LC_ALL=en_US.utf8
txt_file="$(pwd)/info.txt"
cd /proc/

order_column=1 # column to sort
alpha_order=1 # sort by alpha
head_print=0 # for print n lines
reverse=0 # use in reverse to help

#------------check if the number of seconds was passed--------#

arg_counter=0
args=("$@")

if (( $#==0 )); then
    echo "ERROR: number of seconds for sleep MUST be passed"
    echo "TRY: ./procstat.sh options seconds"
    exit 1
elif (( $# >=2 )) && [[ ${args[-2]} == "-p" ]] && [[ ${args[-1]} == [0-9]* ]]; then
    echo "ERROR: number of seconds for sleep MUST be passed"
    echo "TRY: ./procstat.sh options seconds"
    exit 1
elif [[ ${args[-1]} != [0-9]* ]]; then
    echo "ERROR: number of seconds for sleep MUST be passed"
    echo "TRY: ./procstat.sh options seconds"
    exit 1
fi

seconds=${args[-1]}

#---------------check if the options passed make sense-------------#

for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ ${args[i]} == "-m" ]] || [[ ${args[i]} == "-w" ]] || [[ ${args[i]} == "-t" ]] || [[ ${args[i]} == "-d" ]]; then
        arg_counter=$(($arg_counter+1))
    fi
done

if (( $arg_counter>1 )); then
    echo "ERROR: conflit of options"
    echo "TRY: pass only one of this [-m] [-t] [-w] [-d]"
    exit 1
fi

#--------------------------------------------------------#

#--------------alphabetical sort by default-------------#
function sort_default
{
    if (( $alpha_order==1 )); then
        sort -k1 -o $txt_file $txt_file
    fi

    return 0
}
#-------------------------------------------------------#

#-------------Function used in options of sorting the file------#
function sort_by_column
{
    sort -r --key $1 --numeric-sort -o $txt_file $txt_file
    return 0
}

#----------------------------------------------------#


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


#----------Grabing PID's--------------------#

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
#------------------------------------------#

sleep $seconds

#----------------------------------------------------Value of each parameter and the necessary calculations----------------------------------------------------#
i=0
for pid in "${pid_list[@]}"; do

    PID=$(perl -pe 's/\///g' <<< "$pid") 
    COMM1=$(cat $pid/comm)
    COMM="${COMM1// /_}"
    USER="$( ps -o uname= -p "${PID}" )"
    MEM=$(awk '/VmSize:/' $pid/status | tr -dc '0-9')
    RSS=$(awk '/VmRSS:/' $pid/status | tr -dc '0-9')
    DATE=$(ps -olstart= $PID | awk '{print $2,$3,$4}' | cut -d: -f1-2)
    
    READB1=${read_write[$i]}
    WRITEB1=${read_write[$(( $i+1 ))]}
    READB2=$(awk '/rchar:/' $pid/io | tr -dc '0-9')
    WRITEB2=$(awk '/wchar:/' $pid/io | tr -dc '0-9')

    RATER=$( bc -l <<< $(( READB2 - READB1 ))/$seconds )
    RATEW=$( bc -l <<< $(( WRITEB2 - WRITEB1 ))/$seconds )

    printf "%-22s %-10s %6s %12s %12s %15s %15s %15.2f %15.2f %20s\n" $COMM $USER $PID $MEM $RSS $READB2 $WRITEB2 $RATER $RATEW "$DATE" >> $txt_file
    i=$(( $i+2 ))
done
#---------------------------------------------------------------------------------------------------------------------------------------------------------#

while getopts ":c:s:e:u:p:tdwrm" opt; do 
    case ${opt} in
        m)  # sort by decreasing MEMORY  
            alpha_order=0
            order_column=4
            sort_by_column "$order_column"
            ;;
        t)  # sort by decreasing RSS
            alpha_order=0
            order_column=5
            sort_by_column "$order_column"
            ;;
        d)  # sort by decreasing RATER
            alpha_order=0
            order_column=8
            sort_by_column "$order_column"
            ;;
        w)  # sort by decreasing RATEW
            alpha_order=0
            order_column=9
            sort_by_column "$order_column"
            ;;
        r)  # reverse last sort
            alpha_order=0
            reverse=1
            ;;
        p)  # print n lines
            line_number=$OPTARG
            head_print=1
            ;;
        c) # print by pattern  
            sort_default
            get_from_expression "$OPTARG"
            ;;
        u)  # print by user
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
            echo "Usage: cmd [-c] [-s] [-e] [-u] [-p] [-m] [-t] [-d] [-w] [-r] seconds"
            ;;
        : ) # if an option does not get an argument that it needs
            echo "Invalid option: $OPTARG requires an argument"
        ;;
    esac
done

if (( $reverse==1 )) && (( $order_column==1 )); then
    sort -r --key $order_column -o $txt_file $txt_file
elif (( $reverse==1 )); then
    sort --key $order_column --numeric-sort -o $txt_file $txt_file
fi

if (( $head_print==1 )); then 
    printf "%-22s %-10s %6s %12s %12s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    head -n $line_number $txt_file
else
    printf "%-22s %-10s %6s %12s %12s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    cat $txt_file
fi

rm $txt_file