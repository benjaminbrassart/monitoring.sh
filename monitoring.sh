#!/usr/bin/env bash

export LC_ALL=C
export FS='.+:\\s*'

cpu=`lscpu`
cpu_cores=`echo "$cpu" | grep '^CPU(s)' | \
	awk -F "$FS" '{ print $2 }'`
cpu_threads=`echo "$cpu" | grep '^Thread(s) per core' | \
	awk -F "$FS" -v "cores=$cpu_cores" '{ print cores * $2 }'`
cpu_usage=`top -bn1 | grep '^%Cpu' | cut -c 10- | xargs | \
	awk '{ printf("%.1f%%", $1 + $3) }'`

mem_mb=`free -m | grep 'Mem' | awk '{ printf("%d/%dMB", $3, $2) }'`
mem_pr=`free | grep 'Mem' | awk '{ printf("%.2f%%", $3 / $2 * 100) }'`

lvm_usage=`type lvscan &> /dev/null && lvscan | grep -vq 'ACTIVE' && echo 'yes' || echo 'no'`

cat << EOF
#Architecture: `uname -a`
#CPU cores: $cpu_cores
#CPU threads: $cpu_threads
#Memory usage: $mem_mb ($mem_pr)
#Disk usage: 
#CPU load: $cpu_usage
#Last boot: `who -b | cut -c 21- | xargs`
#LVM use: $lvm_usage
#TCP connections: `netstat | egrep '^tcp6?\s+.+\s+ESTABLISHED$' | wc -l`
#Logged users: `who | wc -l`
#Network: `hostname -I | xargs` (`ip address | grep 'ether' | head -n 1 | awk '{ print $2 }'`)
#sudo: 
EOF
