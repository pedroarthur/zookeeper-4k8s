#!/bin/bash

DNS_SERVER="${DNS_SERVER:-}"

dig "$DNS_SERVER" +noall +answer google.com \
  | sort | uniq  \
  | awk -F 'A\t' '{ print $2}' \
  | awk -F '.' '{printf "server.%s=%s\n", $4,$0}'

