#!/bin/bash

TIME="$(date +%Y-%m-%d_%H-%M-%S)"
OS_VERSION=$(cat /etc/centos-release)
HTTP_PROXY=""
HTTPS_PROXY=""

function error_handler() {
	if [[ $? == 1 ]]; then
		case $STEP in
			1)
				echo "("$TIME") [ERROR] Failed to install amazon-ssm-agent via YUM, exiting..." && exit 1
				;;
			2)
				echo "("$TIME") [ERROR] Faile to create proxy override configuration file, exiting..." && exit 1 		
				;;
			3)
				echo "("$TIME") [ERROR] Failed to restart amazon-ssm-agent, exiting..." && exit 1
				;;
		esac
	else
		if [[ $STEP != 2 ]]; then
			echo " : [SUCCESS]"
		fi
		STEP=$((STEP+1))
	fi
}
if yum list installed "amazon-ssm-agent" >/dev/null 2>&1; then
	STEP=1 && echo "("$TIME") : [WARNING] amazon-ssm-agent already installed on `hostname`, skipping..."
else
	echo -n "("$TIME") : Installing amazon-ssm-agent on `hostname`..."
	yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm > /dev/null 2>&1
	error_handler
fi
echo -n "("$TIME") : Placing proxy override configuration file..."

if [[ $OS_VERSION = "CentOS release 6"* ]]; then
	echo "env http_proxy="$HTTP_PROXY"
	env https_proxy="$HTTP_PROXY"
	env no_proxy=169.254.169.254" > /etc/init/amazon-ssm-agent.override
	error_handler
	stop amazon-ssm-agent && start amazon-ssm-agent
	error_handler
else
	echo "[Service]
	Environment="http_proxy="$HTTP_PROXY""
	Environment="https_proxy="$HTTPS_PROXY""
	Environment="no_proxy=169.254.169.254"" > /etc/systemd/system/amazon-ssm-agent.service.d/override.conf
	error_handler 
	systemctl daemon-reload > /dev/null 2>&1 && service amazon-ssm-agent stop > /dev/null 2>&1 && service amazon-ssm-agent start > /dev/null 2>&1
	error_handler
fi

echo "("$TIME") : Installation finished, exiting..." && exit 0
