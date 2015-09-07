#!/bin/bash
file_contexts="/etc/selinux/targeted/contexts/files/file_contexts.local"

for context in $(cat ${file_contexts} | grep "^/" | awk '{ print $1 }') ; do
  context_path=$(echo ${context} | sed "s/[()\?]//g" | sed "s/\.\*/\*/g")
  echo "testing for: ${context_path}"
  if [ ! -e "${context_path}" ] ; then
    echo "${context}"
  fi
done

exit 0
