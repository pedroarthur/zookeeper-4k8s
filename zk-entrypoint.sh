#!/bin/bash

trap 'exit 1' HUP INT QUIT TERM

QUERY_SERVER=( )
SERVICE_NAME="${SERVICE_NAME:-zoo.default.svc.cluster.local}"

ZK_INSTANCE_IP="${ZK_INSTANCE_IP:-127.0.0.1}"
ENSEMBLE_SIZE="${ENSEMBLE_SIZE:-1}"
SLEEP_TIME="${SLEEP_TIME:-10}"
PEER_PORT="${PEER_PORT:-2888}"
ELECTION_PORT="${ELECTION_PORT:-3888}"
CLIENT_PORT="${CLIENT_PORT:-2181}"

zk_servers_file="/tmp/zk.servers"
zk_local_conf_file="${ZK_CONF}.local"

tmp_zk_servers="${zk_servers_file}.raw"
raw_dns_answer="${zk_servers_file}.dig"

# the RE below is the exact meaning of "good enough"
mostly_ip_pattern='!/server\.[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { exit(1) }'

# AWK to add PEER_PORT and ELECTION_PORT to server entries
ip_with_ports="{ print \$0 \":${PEER_PORT}:${ELECTION_PORT}:participant\" }"

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

# If ENSEMBLE_SIZE is smaller or equal to 1, it means we don't
# want an ensemble to form; let zookeeper just run.
if (( ENSEMBLE_SIZE > 1 ))
then
  # The outcome of this loop is a zk_servers_file, which we
  # will merge with zookeeper's configuration file in ZK_CONF
  while ! [[ -e ${zk_servers_file} ]] && sleep "$SLEEP_TIME"
  do
    rm "${tmp_zk_servers}" "${raw_dns_answer}" 2> /dev/null

    # Search for others peers using the SERVICE_NAME using
    # the name server in DNS_SERVER
    if ! dig "${QUERY_SERVER[@]}" +noall +answer "${SERVICE_NAME}" > "${raw_dns_answer}"
    then
      errcho "# couldn't reach DNS server at ${QUERY_SERVER[*]}; will try again"; continue
    fi

    # Tranforma DNS entries in zookeeper peers entries. For example,
    #   zoo.kafka.svc.cluster.local. 30 IN A 10.202.101.1
    # becomes
    #   server.102021011=10.202.101.1
    sort "${raw_dns_answer}" \
      | uniq \
      | awk -F 'A\t' '{ print $2 }' \
      | awk -F  '.'  '{ printf "server.%s=%s\n", $1$2$3$4,$0 }' \
      > "${tmp_zk_servers}"

    # When the hosts are not listed in DNS, dig returns a error
    # string. For this reason, we now check if the entries we
    # build comply with zookeeper's requirements.
    if ! awk "${mostly_ip_pattern}" "${tmp_zk_servers}"
    then
      errcho "# DNS output seems bogus; will try again"; cat "${tmp_zk_servers}"; continue
    fi

    # We now check we have enough peers to start operating
    if (( $(wc -l ${tmp_zk_servers} | awk '{print $1}') < ENSEMBLE_SIZE ))
    then
      errcho "# esemble still smaller than requested size (${ENSEMBLE_SIZE})"; continue
    fi

    # Effectively, ends the while loop
    mv "${tmp_zk_servers}" "${zk_servers_file}"
  done

  # Adds the PEER and ELECTION ports to entries and append them
  # in the configuration file.
  awk "${ip_with_ports}" "${zk_servers_file}" >> "${ZK_CONF}"

  # Remove the temporary file
  rm "${zk_servers_file}"
fi

# Set the clientPort property
sed -i -e "s:^clientPort=.*:clientPort=${CLIENT_PORT}:" "${ZK_CONF}"

# Appends a "local" configuration file to the main configuration
# file (eg, the file that contains TLS configuration).
if [[ -e ${zk_local_conf_file} ]]
then
  cat "${zk_local_conf_file}" >> "${ZK_CONF}"
fi

# Write a myid file using the instance IP
# For example, 10.202.101.1 becomes 102021011
awk -F '.' '{ print $1$2$3$4 }' <<< "${ZK_INSTANCE_IP}" > "${ZK_DATA}/myid"

exec "${@}"

