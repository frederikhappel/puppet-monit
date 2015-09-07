#!/bin/bash
# This file is managed by puppet! Do not change!

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# main
LANG=C
num_processes=$(monit status | grep -i "monitoring status" | wc -l)
num_running=$(monit status | egrep -i "^[[:blank:]]*status[[:blank:]]*[running|not monitored]" | wc -l)
num_monitored=$(monit status | grep -i "^[[:blank:]]*monitoring status[[:blank:]]*monitored" | wc -l)
if [ ${num_running} -lt ${num_processes} ] ; then
  echo "CRITICAL - Process(es) seem down"
  exit $STATE_CRITICAL
elif [ ${num_monitored} -lt ${num_processes} ] ; then
  echo "WARNING - Process(es) are not monitored"
  exit $STATE_WARNING
fi
echo "OK - all processes are monitored and running"
exit $STATE_OK
