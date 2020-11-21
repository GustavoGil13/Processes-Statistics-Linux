# Trabalho1-SO-2020

A Bash script that gets the statistics of processes in Ubuntu.

You can run it by typing in the command shell:

chmod u+x procstat.sh

and then

./procstat.sh number_of_seconds 

The number of seconds is a mandatory argument.
It is used by the program to sleep in order to calculate the rate of reading/writting.

You can pass other arguments:

./procstat.sh -c "d.*" 2 
prints all the processes that have a "d" char in its name

./procstat.sh -u "user_name" 2
prints all the processes that were created by the user_name

./procstat.sh -s "Sep 10 10:00" -e "Sep 20 18:00" 2
prints all the processes that were created between this time frame. You can also use them seperatly

The script has options to order the output:

./procstat.sh -m
sorts by the amount of fisical memory

./procstat.sh -t
sorts by RSS

./procstat.sh -d
sorts by Rate of reading

./procstat.sh -w 
sorts by Rate of writting

./procstat.sh -r
reverses the sort

By default the print is done alphabetical order.
You can combine the options as you please.
