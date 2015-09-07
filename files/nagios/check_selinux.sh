#!/bin/bash
# This file is managed by puppet! Do not change!
#
# Nagios plugin to check if selinux is set to enforcing
#

# defaults
dir_plugins=$(dirname $0)

# source nagios utils.sh
if ! . ${dir_plugins}/utils.sh ; then
  echo "UNKNOWN - missing nagios utils.sh"
  exit 3
elif ! . /etc/sysconfig/selinux ; then
  echo "UNKNOWN - /etc/sysconfig/selinux"
  exit 3
fi

# main program
LANG=C
LC_ALL=C
if selinuxenabled &>/dev/null ; then
  if ! status=$(getenforce | tr A-Z a-z) ; then
    echo "CRITICAL - Cannot determine status of SELinux"
    exit ${STATE_CRITICAL}
  elif echo "${status}" | grep -i "${SELINUX}" &>/dev/null ; then
    echo "OK - SELinux in mode '${status}' as configured."
    exit ${STATE_OK}
  elif [ "${SELINUX}" == "disabled" ] ; then
    echo "WARNING - SELinux running '${status}' but should be disabled. Reboot required."
    exit ${STATE_WARNING}
  else
    echo "WARNING - SELinux running '${status}' but should be '${SELINUX}'."
    exit ${STATE_WARNING}
  fi
elif [ "${SELINUX}" != "disabled" ] ; then
  echo "WARNING - SELinux disabled but should be running '${SELINUX}'. Reboot required."
  exit ${STATE_WARNING}
fi

echo "OK - SELinux disabled"
exit ${STATE_OK}
