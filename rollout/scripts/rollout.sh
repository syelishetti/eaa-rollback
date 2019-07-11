#!/bin/bash
dpop=$1
proxy=$2
release=$3
check=$4

datetime=`date +"%m%d%y%H%M"`
rollout_log=/var/log/wapp/rollout/rollout_log-$dpop-${datetime}.log

export PGPASSWORD=dbpassword
export psql_connect="psql -U dbuser -h localhost -d eaa_upgrade"
dpop_bastion_ip=`$psql_connect -t -A -c  "select bastion_ip from dpop_info where dpop_name='$dpop'"`
dpop_bastion_port=`$psql_connect -t -A -c  "select port_no from dpop_info where dpop_name='$dpop'"`
current_version=`$psql_connect -t -A -c  "select current_version from dpop_release_info where release_name='$release' and trash=false"`

rollout_path=/opt/wapp/eaa/rollout/
local_ansible_path=/opt/wapp/rollout/ansible/
ansible_path=/opt/wapp/eaa/rollout/ansible
inventory_path=$ansible_path/inventory

echo > $rollout_log
exec > >(tee -a $rollout_log) 2>&1
