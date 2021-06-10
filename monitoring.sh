#!/usr/bin/env bash

export LC_ALL=C
export FS='.+:\\s*'

cpu=`lscpu`
cpu_cores=`echo "$cpu" | grep '^CPU(s)' | \
	awk -F "$FS" '{ print $2 }'`
cpu_threads=`echo "$cpu" | grep '^Thread(s) per core' | \
	awk -F "$FS" -v cores=$cpu_cores '{ print cores * $2 }'`

cat << EOF
#Architecture: `uname -a`
#CPU cores: $cpu_cores
#CPU threads: $cpu_threads
#Memory usage: 
#Disk usage: 
#CPU load: 
#Last boot: 
#LVM use: 
#TCP connections: 
#Logged users: 
#Network: 
#sudo: 
EOF
