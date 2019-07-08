#!/bin/bash
datetime=`date +"%m%d%y%s"`
ansible_install_log=/var/log/wapp/ansible_install_log-${datetime}.log

export PGPASSWORD=dbpassword
export psql_connect="psql -U dbuser -h localhost -d eaa_upgrade"

dpop_bastion_ip=(`$psql_connect -t -A -c "select bastion_ip from dpop_info"`)
dpop_bastion_port=3333

echo > $ansible_install_log
exec > >(tee -a $ansible_install_log) 2>&1

function install_ansible {
is_installed_status=`ssh $ip -p $dpop_bastion_port ansible --version; echo $?` > /dev/null
#is_installed_status=`ssh $ip -p $dpop_bastion_port sudo dpkg -l |grep ansible |awk '{print $1}'` > /dev/null
if [ $is_installed_status != 'ii' ]
then
    echo "Installing Ansible dependencies"
    ssh $ip -p $dpop_bastion_port "sudo apt update; sudo DEBIAN_FRONTEND=noninteractive apt install -y ansible"
else
    echo "Ansible has already been installed on the bastion $ip"
fi
}

echo "Checking & Installing Ansible on all Bastion Nodes"

for ip in ${dpop_bastion_ip[@]};
do
    echo -e "\n################"
    echo "Working on the bastion ip: $ip"
    install_ansible
done

echo -e "\nCompleted Ansible installation and verificaton on Bastion Nodes."

