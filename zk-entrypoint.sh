#!/bin/bash

zk_servers_file="/tmp/zk.servers"
tmp_zk_servers="${zk_servers_file}.raw"
raw_dns_answer="${zk_servers_file}.dig"

QUERY_SERVER=( )
SERVICE_NAME="${SERVICE_NAME:-zk.default.cluster.local}"
ENSEMBLE_SIZE="${ENSEMBLE_SIZE:-3}"
SLEEP_TIME="${SLEEP_TIME:-10}"

errcho () {
  >&2 echo "${@}"
}

if [[ ! -z ${DNS_SERVER} ]]
then
  QUERY_SERVER[0]="@${DNS_SERVER}"
fi

if [[ -e ${zk_servers_file} ]]
then
  mv "${zk_servers_file}" "${zk_servers_file}.bkp"
fi

rm "${tmp_zk_servers}" "${raw_dns_answer}"

while ! [[ -e ${zk_servers_file} ]] && sleep "$SLEEP_TIME"
do
  if ! dig "${QUERY_SERVER[@]}" +noall +answer "${SERVICE_NAME}" > "${raw_dns_answer}"
  then
    errcho "couldn't reach DNS server at ${QUERY_SERVER[*]}; will try again"; continue
  fi

  sort "${raw_dns_answer}" \
    | uniq \
    | awk -F 'A\t' '{ print $2 }' \
    | awk -F '.'   '{ printf "server.%s=%s\n", $4,$0 }' \
    > "${tmp_zk_servers}"

  if ! awk '!/server\.[0-9]{1,3}=[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ { exit(1) }' "${tmp_zk_servers}"
  then
    errcho "DNS output seems bogus; will try again"; continue
  fi

  if (( $(wc -l ${tmp_zk_servers} | awk '{print $1}') < ENSEMBLE_SIZE ))
  then
    errcho "esemble still smaller than requested size (${ENSEMBLE_SIZE})"; continue
  fi

  mv "${tmp_zk_servers}" "${zk_servers_file}"
done

cat "${zk_servers_file}" >> "${ZK_HOME}/conf/zoo.cfg"

exec "${@}"

