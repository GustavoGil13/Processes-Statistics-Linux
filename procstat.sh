#!/bin/bash
declare -a read_write
declare -a pid_list
LC_ALL=en_US.utf8
current_dir="$(pwd)/info.txt"
cd /proc/
# getopts options
order_option=1
cat_full_file=0
head_print=0

segundos=${*: -1}

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

i=0
for pid in "${pid_list[@]}"; do

    PID=$(perl -pe 's/\///g' <<< "$pid") 
    COMM=$(awk '/Name:/ {print $2}' $pid/status)
    USER="$( ps -o uname= -p "${PID}" )"
    MEM=$(awk '/VmSize:/' $pid/status | tr -dc '0-9') # quantidade de memoria total
    RSS=$(awk '/VmRSS:/' $pid/status | tr -dc '0-9') # quantidade de memoria residente em memoria fisica
    DATE=$(ps -olstart= $PID | awk '{print $2,$3,$4}')
    # d=$(date -d "$DATE" +%s) # datas em segundos
    # echo $d
    
    READB1=${read_write[$i]}
    WRITEB1=${read_write[$(( $i+1 ))]}
    READB2=$(awk '/rchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Input
    WRITEB2=$(awk '/wchar:/' $pid/io | tr -dc '0-9') # numero total de bytes de Ouput

    RATER=$( bc -l <<< $(( READB2 - READB1 ))/$segundos )
    RATEW=$( bc -l <<< $(( WRITEB2 - WRITEB1 ))/$segundos )

    printf "%-20s %-10s %10s %10s %10s %15s %15s %15.2f %15.2f %20s\n" $COMM $USER $PID $MEM $RSS $READB2 $WRITEB2 $RATER $RATEW "$DATE" >> $current_dir
    i=$(( $i+2 ))
done

while getopts ":c:s:e:u:p:tdwrm" opt; do 
    case ${opt} in
        m)  
            cat_full_file=1
            order_option=4
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        t)
            cat_full_file=1
            order_option=5
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        d)
            cat_full_file=1
            order_option=8
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        w)
            cat_full_file=1
            order_option=9
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        r)
            cat_full_file=1
            sort -r --key $order_option --numeric-sort -o $current_dir $current_dir
            ;;
        p)
            line_number=$OPTARG
            head_print=1
            ;;
        c)  
            cat_full_file=1
            pattern=$OPTARG
            counter=1
            while IFS= read -r line
            do
                array=( $line )
                word=${array[0]}
                if [[ ! $word =~ $pattern ]]; then
                    sed -i "${counter}d" $current_dir 
                    counter=$(( $counter-1 ))
                fi
                counter=$(( $counter+1 ))
            done < "$current_dir"
            ;;
        u)
            cat_full_file=1
            user_name=$OPTARG
            counter=1
            while IFS= read -r line
            do
                array=( $line )
                word=${array[1]}
                if [[ $word != $user_name ]]; then
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
            ;;
        \? )
            echo "Usage: cmd [-c] [-s] [-e] [-u] [-p] [-m] [-t] [-d] [-w] [-r]"
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument"
        ;;
    esac
done

if (( cat_full_file==1 )) && (( head_print==0 )); then
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    cat $current_dir
elif (( head_print==1 )); then
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    head -n $line_number $current_dir
fi

if (( $OPTIND==1 )); then
    printf "%-20s %-10s %10s %10s %10s %15s %15s %15s %15s %20s\n" COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE
    sort -k1 $current_dir
fi

rm $current_dir