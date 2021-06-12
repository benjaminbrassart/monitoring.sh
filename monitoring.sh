#!/usr/bin/env bash

# Note: awk implementation has to be gawk (GNU awk)
# because of the -M (--bignum) option, which is used
# to deal with long integers (such as disk space).

# Make sure everything is in english
export LC_ALL=C
export FS='.+:\\s*'


# Check if lvscan exists on the system and scan for
# anything that does not match '[:space:]*ACTIVE'
if !(type lvscan &> /dev/null) || lvscan | egrep -vq '^\s*ACTIVE'; then
	lvm="\e[31mno"
else
	lvm="\e[32myes"
fi
lvm="$lvm\e[0m"

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
cpu_usage=`top -bn1 | grep '^%Cpu' | cut -c 10- | xargs | \
	awk '{ printf("%.1f%%", $1 + $3) }'`

mem=`free -b | grep 'Mem' | awk '{ print $3 " " $2 }'`
mem_perc=`awk '{ printf("%.1f%%", $1 / $2 * 100) }' <<< "$mem"`
mem_human=`numfmt --from='iec' --to='iec' --field='1-2' <<< "$mem" | \
	awk '{ print $1 "/" $2 }'`

disk=`df -B1 | grep '^/dev/' | grep -v '/boot$' | \
	awk '{ us += $3 } { av += $4 } END { print us " " av }'`
disk_perc=`awk '{ printf("%.1f%%", $1 / $2 * 100) }' <<< $disk`
disk_human=`numfmt --from='iec' --to='iec' --field='1-2' <<< "$disk" | \
	awk '{ print $1 "/" $2 }'`

cat << EOF
#Architecture: `uname -a`
#CPU cores: $cpu_cores
#CPU threads: $cpu_threads
#Memory usage: $mem_human ($mem_perc)
#Disk usage: $disk_human ($disk_perc)
#CPU load: $cpu_usage
#Last boot: `who -b | cut -c 21- | xargs`
#LVM use: `echo -e $lvm`
#TCP connections: `netstat | egrep '^tcp6?\s+.+\s+ESTABLISHED$' | wc -l`
#Logged users: `who | wc -l`
#Network: `hostname -I | cut -d ' ' -f 1` (`ip address | grep 'ether' | head -n 1 | awk '{ print $2 }'`)
#sudo: 
EOF
