#!/usr/bin/env bash

util:wait_until() {
  cmd="$@"
  local ret=0
  for i in {1..10}; do
    eval "$cmd" > /dev/null || true
    ret=$?
    if [[ ${ret} -eq 0 ]]; then
      return 0
    fi
    echo "$cmd failed, retrying(${i} times)"
    sleep 1
  done

  echo "$* failed"
  return ${ret}
}