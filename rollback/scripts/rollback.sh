#!/bin/bash
dpop=$1
proxy=$2
release=$3
check=$4

datetime=`date +"%m%d%y%H%M"`
rollback_log=/var/log/wapp/rollback/rollback_log-$dpop-${datetime}.log

export PGPASSWORD=dbpassword
export psql_connect="psql -U dbuser -h localhost -d eaa_upgrade"
dpop_bastion_ip=`$psql_connect -t -A -c  "select bastion_ip from dpop_info where dpop_name='$dpop'"`
dpop_bastion_port=`$psql_connect -t -A -c  "select port_no from dpop_info where dpop_name='$dpop'"`
current_version=`$psql_connect -t -A -c  "select current_version from dpop_release_info where release_name='$release' and trash=false"`
previous_version=`$psql_connect -t -A -c  "select previous_version from dpop_release_info where release_name='$release' and trash=false"`

rollback_path=/opt/wapp/eaa/rollback/
local_ansible_path=/opt/wapp/rollback/ansible/
ansible_path=/opt/wapp/eaa/rollback/ansible
inventory_path=$ansible_path/inventory

echo > $rollback_log
exec > >(tee -a $rollback_log) 2>&1

echo -e "\n###########################"
echo "Rolling back $proxy on the $dpop via Bastion $dpop_bastion_ip"

echo -e "\n\n###########################"
echo "Providing ubuntu user permission to the $rollback_path"
ssh ${dpop_bastion_ip} -p ${dpop_bastion_port} "sudo mkdir -p $rollback_path; sudo chown -R ubuntu:ubuntu $rollback_path"

echo -e "\n\n###########################"
echo "Copying the local ansible path to the remote Bastion Machine"
rsync -e 'ssh -p 3333' -arvz --progress --delete $local_ansible_path ubuntu@$dpop_bastion_ip:$ansible_path -v

echo -e "\n\n###########################"
if [ $check = 'Yes' ]
then
	echo "Running the playbook in Check Mode from Bastion of $dpop to all the $proxy nodes"
	ssh ${dpop_bastion_ip} -p ${dpop_bastion_port} ansible-playbook -i $inventory_path/$dpop -e \"role=$proxy group=$proxy user=ubuntu current_version=$current_version previous_version=$previous_version rollback=true copy_config=false\" -vv $ansible_path/main.yml --check
else
	echo "Running the playbook from Bastion of $dpop to all the $proxy nodes"
	ssh ${dpop_bastion_ip} -p ${dpop_bastion_port} ansible-playbook -i $inventory_path/$dpop -e \"role=$proxy group=$proxy user=ubuntu current_version=$current_version previous_version=$previous_version rollback=true copy_config=false\" -vv $ansible_path/main.yml
fi
