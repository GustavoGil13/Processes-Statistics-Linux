# Bash - statistics of running processes in Linux

A Bash script that gets the statistics of processes in Ubuntu.

You can run it by typing in the command shell:

```sh
$ chmod u+x procstat.sh
$ ./procstat.sh number_of_seconds 
```

The number of seconds is a mandatory argument.
It is used by the program to sleep in order to calculate the rate of reading/writting.

You can pass other arguments:

prints all the processes wich the name follows a pattern.
Example:

```sh
./procstat.sh -c "d.*" 2 
```
the example will print all the processes that have a "d" in its name.

prints all the processes that were created by the user_name.
```sh
./procstat.sh -u "user_name" 2
```

prints all the processes that were created between this time frame. You can also use -s and -e seperatly.
```sh
./procstat.sh -s "Sep 10 10:00" -e "Sep 20 18:00" 2
```

The script has options to order the output:

| Options | Sorts by |
| ------ | ------ |
| -m | the amount of physical memory |
| -t | RSS |
| -d | rate of reading |
| -w | rate of writting |
| -r | reverses the sort |


By default the print is done alphabetical order.
You can combine the options as you please.
