#!/bin/bash

: "${LOGFILE:=false}"

if ! sar > /dev/null 2>&1; then
    printf "Sar is either not on the system or metric collection is disabled.\n";
    printf "Exiting.\n";
    exit 1
fi
printf "Sar found.\n"


if [[ $# -gt 0 ]]; then
    case "$1" in
        /var/log/sa/sa*)
            printf "Found valid log file: %s\n" "$1"
            LOGFILE="$1";
            ;;
        *)
            printf "Argument was not a sar log file. Ignoring it.\n";
            ;;
    esac
fi

echo "LOGFILE: ${LOGFILE}"

printf "Generating CSV on CPU.\n"
# sar CPU csv using timestamps, %cpu usage by user && system, %cpu i/o wait, and %idle
sar -u -p -f "$1" |
    awk 'BEGIN {
            print "Timestamp,%CPU used by User,%CPU used by System,%CPU I/O Wait,%CPU Idle"
        } NR>3 && /^[0-9|A]/ { 
            print $1 "," $3 "," $5 "," $6 "," $8
        }' > cpu_usage_report.csv
if [[ ! -f cpu_usage_report.csv ]]; then
    printf "Error generating CPU usage report.\n"
else
    printf "Successfully generated CPU usage report.\n"
fi


printf "Generating CSV on Memory.\n"

# sar Memory csv using timestamp, mem free, mem available, mem used, %mem used, buffered and cached
sar -r -h -f "$1" | 
    awk 'BEGIN {
        print "Timestamp,Free Memory,Available Memory,Used Memory,%Used Memory,Buffered Memory,Cached Memory, %Commited to System/Applications"
    } 
    NR>3 {
        print $1, "," $2  "," $3 "," $4 "," $5 "," $6 "," $7 "," $9
    }' > memory_usage_report.csv
if [[ ! -f memory_usage_report.csv ]]; then
    printf "Error generating memory usage report.\n"
else
    printf "Successfully generated CPU usage report.\n"
fi



# Output:
# cat ./memory_usage_report.csv
# Timestamp,Free Memory,Available Memory,Used Memory,%Used Memory,Buffered Memory,Cached Memory, %Commited to               > System/Applications
# 20:25:45 ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%
# 20:25:46 ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%
# 20:25:47 ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%
# 20:25:48 ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%
# 20:25:49 ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%
# Average: ,1.5G,1.5G,220.6M,5.7%,0.0k,1.9G,61.8%


printf "Highest CPU spikes according to sar:\n" 
sar -u -p -f "$1" |
    awk '{
        print "System: " $5 ", User: " $3 " Time: " $1 
    }' | sort -n | tail -n 5

