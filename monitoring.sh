#!/usr/bin/env bash

# Note: awk implementation has to be gawk (GNU awk)
# because of the -M (--bignum) option, which is used
# to deal with long integers (such as disk space).

# Make sure everything is in english
export LC_ALL=C
export FS='.+:\\s*'

# Store the result of lscpu to avoid executing it twice
cpu=`lscpu`
# Get the CPU cores from the previous output
cpu_cores=`grep '^CPU(s)' <<< "$cpu" | \
	awk -F "$FS" '{ print $2 }'`
# Get the CPU threads per core, multiplied by the cores
cpu_threads=`grep '^Thread(s) per core' <<< "$cpu" | \
	awk -F "$FS" -v "cores=$cpu_cores" '{ print cores * $2 }'`
# Get the total CPU usage, by adding the user load
# to the system load
cpu_usage=`top -bn1 | grep '^%Cpu' | cut -c 9- | xargs | \
	awk '{ printf("%.1f%%", $1 + $3) }'`

# Get the total and used memory as bytes
mem=`free -b | grep 'Mem' | awk '{ print $3 " " $2 }'`
# Get memory usage as a percentage
mem_perc=`awk '{ printf("%.1f%%", $1 / $2 * 100) }' <<< "$mem"`
# Convert bytes to human format
mem_human=`numfmt --from='iec' --to='iec' --field='1-2' <<< "$mem" | \
	awk '{ print $1 "/" $2 }'`

# Get the total and used space as bytes, on devices that
# are located in /dev/ and are mounted elsewhere than on /boot
disk=`df -B1 | grep '^/dev/' | grep -v '/boot$' | \
	awk '{ us += $3 } { av += $2 } END { print us " " av }'`
# Get disk usage as a percentage
disk_perc=`awk '{ printf("%.1f%%", $1 / $2 * 100) }' <<< $disk`
# Convert bytes to human format
disk_human=`numfmt --from='iec' --to='iec' --field='1-2' <<< "$disk" | \
	awk '{ print $1 "/" $2 }'`

sudo_log=`find /var/log/sudo/ -iwholename '*/*/*/log' 2> /dev/null | wc -l`

# Print everything
cat << EOF
#Architecture: `uname -a`
#CPU cores: $cpu_cores
#CPU threads: $cpu_threads
#Memory usage: $mem_human ($mem_perc)
#Disk usage: $disk_human ($disk_perc)
#CPU load: $cpu_usage
#Last boot: `who -b | cut -c 21- | xargs`
#LVM use: `(!(type lvscan &> /dev/null) || (lvscan | egrep -vq '^\s*ACTIVE')) && \
	echo 'no' || echo 'yes'`
#TCP connections: `ss -nt state established | head -n +2 | wc -l`
#Logged users: `who | wc -l`
#Network: `hostname -I | cut -d ' ' -f 1` (`ip address | grep 'ether' | head -n 1 | awk '{ print $2 }'`)
#sudo: $sudo_log command`if [ $sudo_log -gt 1 ]; then echo 's'; fi`
EOF

# while pretty ugly, find is likely faster than bash
# at parsing wildcard (+30ms for 14102 files)

#time find /var/log/sudo/ -iwholename '*/*/*/log'
# real	0m0.282s
# user	0m0.118s
# sys	0m0.166s
#time find /var/log/sudo/*/*/* -name 'log'
# real	0m0.312s
# user	0m0.104s
# sys	0m0.209s
