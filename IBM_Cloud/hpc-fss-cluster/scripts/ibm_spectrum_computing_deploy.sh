#!/bin/bash

declare -i numbercomputes

##retrieve user_metadata on bare metal
if [ ! -f /root/user_metadata_bare_metal ]
then
	if dmidecode | egrep -q "HVM|Xen"
	then
		echo "on vm instance"
	elif dmidecode | egrep -q "No SMBIOS nor DMI entry point found"
	then
		echo "on vm instance"
	else
		wget --no-check-certificate -O /root/user_metadata_bare_metal https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/UserMetadata.txt
	fi
fi
[ -f /root/user_metadata ] && . /root/user_metadata
[ -f /root/user_metadata_bare_metal ] && . /root/user_metadata_bare_metal
LOG_FILE=/root/log_deploy_${product}

##run only once cloud config is not there##
[ -f /tmp/deploy ] && exit || touch /tmp/deploy

###################COMMON SHELL FUNCTIONS#################
function LOG ()
{
	echo -e `date` "$1" >> "$LOG_FILE"
}

function funcSetupProxyService()
{
	if [ "${role}" == "master" ]
	then
		if [ -f /etc/redhat-release ]
		then
			LOG "\tyum -y install squid"
			yum -y install squid
			systemctl enable squid
			systemctl start squid
		elif [ -f /etc/lsb-release ]
		then
			apt-get update
			export DEBIAN_FRONTEND=noninteractive
			LOG "\tapt-get -y install squid"
			apt-get install -y squid
			sed -i 's/#acl localnet src 10/acl localnet src 10/' /etc/squid/squid.conf
			sed -i 's/#http_access allow localnet/http_access allow localnet/' /etc/squid/squid.conf
			systemctl enable squid
			systemctl restart squid
		else
			echo "not proxy setup"
		fi
	fi
}

function funcUseProxyService()
{
	if [ "${useintranet}" != "false" -a "${role}" != "master" -a "${role}" != "failover" -a "${role}" != "symde" ]
	then
		realmasterprivateipaddress=`echo ${masterprivateipaddress} | awk '{print $1}'`
		export http_proxy=http://${realmasterprivateipaddress}:3128
		export https_proxy=http://${realmasterprivateipaddress}:3128
		export ftp_proxy=http://${realmasterprivateipaddress}:3128
		echo export http_proxy=http://${realmasterprivateipaddress}:3128 >> /root/.bash_profile
		echo export https_proxy=http://${realmasterprivateipaddress}:3128 >> /root/.bash_profile
		echo export ftp_proxy=http://${realmasterprivateipaddress}:3128 >> /root/.bash_profile
		if [ -f /etc/redhat-release ]
		then
			echo "proxy=http://${realmasterprivateipaddress}:3128" >> /etc/yum.conf
		elif [ -f /etc/lsb-release ]
		then
			echo "Acquire::http::Proxy \"http://${realmasterprivateipaddress}:3128/\";" > /etc/apt/apt.conf
		else
			echo noconfig
		fi
	fi
}

function os_config()
{
	LOG "configuring os ..."
	# check metadata to see if we need use internet interface
	if [ "$useintranet" == "0" ]
	then
		useintranet=false
	elif [ "$useintranet" == "1" ]
	then
		useintranet=true
	else
		echo "no action"
	fi
	funcSetupProxyService
	funcUseProxyService
	if [ -f /etc/redhat-release ]
	then
		LOG "\tyum -y install ed tree lsof psmisc nfs-utils net-tools"
		yum -y install ed tree lsof psmisc nfs-utils net-tools
	elif [ -f /etc/lsb-release ]
	then
		LOG "\tapt-get bash install -y wget curl tree ncompress gettext rpm nfs-kernel-server acl"
		apt-get update
		export DEBIAN_FRONTEND=noninteractive
		if  cat /etc/lsb-release | egrep -qi "ubuntu 16"
		then
			apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages  wget curl tree ncompress gettext rpm nfs-kernel-server acl
		else
			apt-get install -y --force-yes  wget curl tree ncompress gettext rpm nfs-kernel-server acl
		fi
	else
		echo "os_config not handled"
	fi
	if [ -h /bin/sh -a -f /bin/bash ]
	then
		rm -f /bin/sh
		cp /bin/bash /bin/sh
	fi
	if [ -f /etc/cloud/cloud.cfg ]
	then
		sed -i 's/\(.*\)update_etc_hosts/#\1update_etc_hosts/' /etc/cloud/cloud.cfg
	fi
}

function funcGetPrivateIp()
{
	ip address show | egrep "inet .*global" | egrep "inet[ ]+10\." | head -1 | awk '{print $2}' | sed -e 's/\/.*//'
}

function funcGetPublicIp()
{
	ip address show | egrep "inet .*global" | egrep -v "inet[ ]+10\." | head -1 | awk '{print $2}' | sed -e 's/\/.*//'
}

function funcStartFailoverService()
{
	mkdir -p /failover
	echo -e "/failover\t\t10.0.0.0/8(rw,no_root_squash) 172.16.0.0/12(rw,no_root_squash) 192.168.0.0/16(rw,no_root_squash)" > /etc/exports
	if [ -f /etc/redhat-release ]
	then
		systemctl enable nfs
		systemctl start nfs
	elif [ -f /etc/lsb-release ]
	then
		systemctl enable nfs-server
		systemctl restart nfs-server
	else
		echo "not known"
	fi
}

function funcConnectFailoverService()
{
	#if [ -n "${nfsipaddress}" -a "$useintranet" == 'true' ]
	if [ -n "${nfsipaddress}" ]
	then
		mkdir -p /failover
		while ! mount | grep failover | grep -v grep
		do
			LOG "\tmounting /failover ..."
			mount -o tcp,vers=3,rsize=32768,wsize=32768 ${nfsipaddress}:/failover /failover
			touch /failover/connected-${localhostname}
			sleep 60
		done
		sed -i '/failover/d' /etc/fstab
		echo -e "${nfsipaddress}:/failover\t/failover\tnfs\trsize=32768,wsize=32768\t2 2" >> /etc/fstab
		LOG "\tmounted /failover ..."
	fi
}

function funcStartConfService()
{
	if [ "$role" == "master" ]
	then
		mkdir -p /export
		echo -e "/export\t\t10.0.0.0/8(ro,no_root_squash) 172.16.0.0/12(ro,no_root_squash) 192.168.0.0/16(ro,no_root_squash)" > /etc/exports
		if [ -f /etc/redhat-release ]
		then
			systemctl enable nfs
			systemctl start nfs
		elif [ -f /etc/lsb-release ]
		then
			systemctl enable nfs-server
			systemctl restart nfs-server
		else
			echo "not known"
		fi
	fi
}

function funcConnectConfService()
{
	mkdir -p /export
	if [ "${role}" == "symde" ]
	then
		echo doing nothing
	elif [ "$role" == "failover" -o "$role" == "compute" ]
	then
		if [ -n "${masteripaddress}" -a "$useintranet" == 'true' ]
		then
			realmasterip=`echo ${masteripaddress} | awk '{print $1}'`
			while ! mount | grep export | grep -v grep
			do
				LOG "\tmounting /export ..."
				mount -o tcp,vers=3,rsize=32768,wsize=32768 ${realmasterip}:/export /export
				sleep 60
			done
			LOG "\tmounted /export ..."
		fi
	else
		echo doing nothing
	fi
}

function funcDetermineConnection()
{
	if [ -z "$masterprivateipaddress" ]
	then
		## on master node
		masterprivateipaddress=$(funcGetPrivateIp)
		masterpublicipaddress=$(funcGetPublicIp)
	fi
	masteripaddress=${masterprivateipaddress}
	realmasteripaddress=`echo ${masterprivateipaddress} | awk '{print $1}'`
	
	## if localipaddress is not in the same subnet as masterprivateipaddress, force using internet
	if [ "${localipaddress%.*}" != "${realmasteripaddress%.*}" ]
	then
		useintranet=false
	fi
	if [ "$useintranet" == "false" ]
	then
		masteripaddress=${masterpublicipaddress}
		localipaddress=$(funcGetPublicIp)
	fi
}
##################END FUNCTIONS RELATED######################

######################MAIN PROCEDURE##########################

# configure OS, install basic utilities like wget curl mount .etc
os_config

# get local hostname, ipaddress and netmask
localhostname=$(hostname -s)
localipaddress=$(funcGetPrivateIp)
echo -e "127.0.0.1\tlocalhost.localdomain\tlocalhost\n${localipaddress}\t${localhostname}.${domain}\t${localhostname}" > /etc/hosts

#normalize variables
export PRODUCT=$product
export VERSION=$version
export ROLE=$role
export CLUSTERNAME=$clustername
export OVERWRITE_EGO_CONFIGURATION=Yes
export SIMPLIFIEDWEM=N
export ENTITLEMENT_FILE=/tmp/entitlement
export MASTERHOSTNAMES=$masterhostnames
export MASTERHOST=`echo $MASTERHOSTNAMES | awk '{print $1}'`
export FAILOVERHOST=`echo $MASTERHOSTNAMES | awk '{print $NF}'`
if [ "$ROLE" == "master" ]
then
	export MASTERHOSTNAMES=${localhostname}
	export MASTERHOST=${localhostname}
	export FAILOVERHOST=${localhostname}
fi

# determine to use intranet or internet interface
funcDetermineConnection

# start nfs service on primary master and nfs server and try to mount nfs service from compute nodes
funcConnectFailoverService
if [ "$role" == "nfsserver" ]
then
	funcStartFailoverService
	exit
fi
funcStartConfService
funcConnectConfService

# download functions file if not there already
LOG "donwloading product function file and source it"
if [ -n "${functionsfile}" ]
then
	if [ ! -f /export/${product}.sh ]
	then
		wget --no-check-certificate -o /dev/null -O /export/${product}.sh ${functionsfile}
	fi
	LOG "\tfound /export/${product}.sh"
fi
. /export/${product}.sh

# create and/or start up upd server/client to update /etc/hosts and other messages
if [ "$role" == "master" -o "$role" == "failover" ]
then
	create_udp_server
fi
if [ "$role" != "master" -a "$role" != "nfsserver" ]
then
	create_udp_client
fi

if [ "$ROLE" != "nfsserver" -a "$ROLE" != "master" ]
then
	echo -e "`echo ${masteripaddress} | awk '{print $1}'`\t${MASTERHOST}.${domain}\t${MASTERHOST}" >> /etc/hosts
	python /tmp/udpclient.py "update ${localipaddress} ${localhostname}.${domain} ${localhostname}"
	ping -c2 -w2 ${MASTERHOST}
	if [ "$MASTERHOST" != "${FAILOVERHOST}" ]
	then
		echo -e "`echo ${masteripaddress} | awk '{print $NF}'`\t${FAILOVERHOST}.${domain}\t${FAILOVERHOST}" >> /etc/hosts
		ping -c2 -w2 ${FAILOVERHOST}
	fi
else
	echo nothing
fi


export DERBY_DB_HOST=$MASTERHOST
if [ -z "$clusteradmin" ]
then
	if [ "$product" == "symphony" -o "$product" == "cws" ]
	then
		clusteradmin=egoadmin
	elif [ "$product" == "lsf"  ]
	then
		clusteradmin=lsfadmin
	else
		clusteradmin=lsfadmin
	fi
fi
export CLUSTERADMIN=$clusteradmin

# create related user accounts
add_admin_user $CLUSTERADMIN

# handle application dependancy
app_depend

# download packages to /export
download_packages

# generate entitlement file or wait for download
generate_entitlement

if [ "${ROLE}" != "master" ]
then
	## wait untils /export/download_finished appears
	while [ ! -f /export/download_finished ]
	do
		LOG "\twaiting for package downloads ..."
		sleep 60
	done
	LOG "\tpackages downloaded ..."
fi

#deploy product 
if [ "$PRODUCT" == "symphony" ]
then
	SOURCE_PROFILE=/opt/ibm/spectrumcomputing/profile.platform
	deploy_product
elif [ "$PRODUCT" == "cws" -o "$PRODUCT" == "lsf" ]
then
	echo installing spectrum computing $PRODUCT 
	deploy_product
else
	echo "unsupported product $PRODUCT `date`" >> /root/application-failed
fi

[ -x /tmp/post.sh ] && /tmp/post.sh >> /tmp/output

echo "$0 execution ends at `date`" >> /tmp/output
###################END OF MAIN PROCEDURE##################
