#!/bin/bash

###################COMMON SHELL FUNCTIONS#################

function add_admin_user()
{
	user_id=`id $1 2>>/dev/null`
	if [ "$?" != "0" ]; then
		useradd -d /home/$1 -m -s /bin/bash $1 >/dev/null 2>&1
		ls /home/$1 > /dev/null
	else
		LOG "User $1 exists already."
	fi
}

####################FUNCTION PYTHON SCRIPTS##################
function create_udp_server()
{
	cat << ENDF > /etc/udpserver.py
#!/usr/bin/env python

ETC_HOSTS = '/etc/hosts'
import re, socket, subprocess, time, random
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(('0.0.0.0',9999))
while True:
	data, addr = s.recvfrom(1024)
	print('Received from %s:%s.' % addr)
	if re.match(r'^update', data, re.I):
		record = data.strip().split()[1:]
		if len(record) == 3 and re.match(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', record[0]):
			with open(ETC_HOSTS,'a') as f:
				f.write("%s\t%s\t%s\n" % (record[0],record[1],record[2]))
		s.sendto("done", addr)
	elif re.match(r'^egomanage', data, re.I):
		command = data.strip().split()[1:]
		if len(command) == 4:
			if command[2].strip() == "stop":
				output = subprocess.check_output(". /opt/ibm/spectrumcomputing/profile.platform; egosh service %s %s; exit 0" % (command[2], command[3]), shell=True)
			else:
				time.sleep(random.randint(1,60))
				output = subprocess.check_output(". /opt/ibm/spectrumcomputing/profile.platform; egosh service %s %s; exit 0" % (command[2], command[3]), shell=True)
			print(output)
			s.sendto(output, addr)
		else:
			s.sendto("notdone", addr)
	elif re.match(r'^queryproxy', data, re.I):
		output = subprocess.check_output("ps ax | egrep -i \"bin.squid\" | grep -v grep; exit 0",shell=True)
		if re.match(r'.*squid',output):
			s.sendto("proxyready", addr)
		else:
			s.sendto("proxyunavailable", addr)
	else:
		s.sendto("done", addr)
ENDF
	chmod +x /etc/udpserver.py
	nohup python /etc/udpserver.py >> /tmp/udpserver.log 2>&1 &
	if [ -f /etc/rc.d/rc.local ]
	then
		sed -i '/^exit 0/d' /etc/rc.d/rc.local
		echo "nohup python /etc/udpserver.py >> /tmp/udpserver.log 2>&1 &" >> /etc/rc.d/rc.local
		chmod +x /etc/rc.d/rc.local
	elif [ -f /etc/rc.local ]
	then
		sed -i '/^exit 0/d' /etc/rc.local
		echo "nohup python /etc/udpserver.py >> /tmp/udpserver.log 2>&1 &" >> /etc/rc.local
		chmod +x /etc/rc.local
	else
		echo
	fi
}

function create_udp_client()
{
	cat << ENDF > /tmp/udpclient.py
#!/usr/bin/env python

import socket
import sys, time
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for data in sys.argv:
    print(data)
    for master in "${masteripaddress}".split():
        s.sendto(data,(master,9999))
        time.sleep(1)
        print(s.recv(1024))
s.close()
ENDF
	chmod +x /tmp/udpclient.py
}

#####################SHELL FUNCTIONS RELATED#################
function update_profile_d()
{
	if [ -d /etc/profile.d ]
	then
		if [ "${ROLE}" == "master" -o "${ROLE}" == 'compute' ]
		then
			echo "[ -f /opt/ibm/spectrumcomputing/profile.platform ] && source /opt/ibm/spectrumcomputing/profile.platform" > /etc/profile.d/spectrumcomputing.sh
			echo "[ -f /opt/lsf/conf/profile.lsf ] && source /opt/lsf/conf/profile.lsf" >> /etc/profile.d/spectrumcomputing.sh
			echo "[ -f /opt/ibm/spectrumcomputing/cshrc.platform ] && source /opt/ibm/spectrumcomputing/cshrc.platform" > /etc/profile.d/spectrumcomputing.csh
			echo "[ -f /opt/lsf/conf/cshrc.lsf ] && source /opt/lsf/conf/cshrc.lsf" >> /etc/profile.d/spectrumcomputing.csh
		elif [ "${ROLE}" == "symde" ]
		then
			echo "[ -f /opt/ibm/spectrumcomputing/symphonyde/de72/profile.platform ] && source /opt/ibm/spectrumcomputing/symphonyde/de72/profile.platform" > /etc/profile.d/symphony.sh
			echo "[ -f /opt/ibm/spectrumcomputing/symphonyde/de72/profile.client ] && source /opt/ibm/spectrumcomputing/symphonyde/de72/profile.client" >> /etc/profile.d/symphony.sh
			echo "[ -f /opt/ibm/spectrumcomputing/symphonyde/de72/cshrc.platform ] && source /opt/ibm/spectrumcomputing/symphonyde/de72/cshrc.platform" > /etc/profile.d/symphony.csh
			echo "[ -f /opt/ibm/spectrumcomputing/symphonyde/de72/cshrc.client ] && source /opt/ibm/spectrumcomputing/symphonyde/de72/cshrc.client" >> /etc/profile.d/symphony.csh
		else
			echo "nothing to update"
		fi
	fi
}

function app_depend()
{
	LOG "handle symphony dependancy ..."
	if [ "${PRODUCT}" == "symphony" ]
	then
		if [ -f /etc/redhat-release ]
		then
			LOG "\tyum -y install java-1.7.0-openjdk gcc gcc-c++ glibc.i686 httpd unzip"
			yum -y install java-1.7.0-openjdk gcc gcc-c++ glibc.i686 httpd unzip
			if [ "${ROLE}" == 'symde' ]
			then
				LOG "\tyum -y install tigervnc-server xterm firefox"
				yum -y install tigervnc-server xterm firefox
			fi
		elif [ -f /etc/lsb-release ]
		then
			LOG "\tapt-get install -y gcc g++ openjdk-8-jdk make unzip"
			if  cat /etc/lsb-release | egrep -qi "ubuntu 16"
			then
				apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages gcc g++ openjdk-8-jdk make unzip
			else
				apt-get install -y --force-yes gcc g++ openjdk-7-jdk make unzip
			fi
			if [ "${ROLE}" == 'symde' ]
			then
				LOG "\tapt-get -y install vnc4server twm xterm firefox"
				apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages vnc4server twm xterm firefox
			fi
		else
			echo "unknown"
		fi
	else
		LOG "...unknown application"
	fi
}

function download_packages()
{
	if [ 1 -lt 2 ]
	then
		# we can get the package from anywhere applicable, then export through nfs://export, not implemented here yet
		LOG "download symphony packages ..."
		mkdir -p /export/symphony/${VERSION}
		if [ "${VERSION}" == "latest" ]
		then
			ver_in_pkg=7.2.0.0
		else
			ver_in_pkg=${VERSION}
		fi
		if [ -d /opt/ibm/spectrumcomputing ]
		then
			LOG "bypass downloading packages ..."
			touch /export/download_finished
		elif [ "$ROLE" == 'symde' ]
		then
			LOG "\twget -nH -c -o /dev/null -O symde-${ver_in_pkg}_x86_64.bin ${uri_package_additional}"
			cd /export/symphony/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O symde-${ver_in_pkg}_x86_64.bin ${uri_package_additional}
			touch /export/download_finished
			LOG "\twget -nH -c -o /dev/null -O eclipse.tar.gz http://mirror.csclub.uwaterloo.ca/eclipse/technology/epp/downloads/release/luna/SR2/eclipse-java-luna-SR2-linux-gtk-x86_64.tar.gz"
			wget -nH -c -o /dev/null -O /export/eclipse.tar.gz http://mirror.csclub.uwaterloo.ca/eclipse/technology/epp/downloads/release/luna/SR2/eclipse-java-luna-SR2-linux-gtk-x86_64.tar.gz
			touch /export/eclipse && rm -fr /export/eclipse && cd /export && tar xf eclipse.tar.gz
			cd /usr/bin && ln -sf /export/eclipse/eclipse .
		else
			if [ "$ROLE" == 'master' ]
			then
				LOG "\twget -nH -c --no-check-certificate -o /dev/null -O sym-${ver_in_pkg}_x86_64.bin ${uri_package_installer}"
				cd /export/symphony/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O sym-${ver_in_pkg}_x86_64.bin ${uri_package_installer}
				touch /export/download_finished
			else
				if [ "$useintranet" == 'false' ]
				then
					if [ "${ROLE}" == "compute" ]
					then
						LOG "\twget -nH -c -o /dev/null -O sym-${ver_in_pkg}_x86_64.bin ${uri_package_installer}"
						cd /export/symphony/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O sym-${ver_in_pkg}_x86_64.bin ${uri_package_installer}
						touch /export/download_finished
					fi
				fi
			fi
		fi
	fi
}

function generate_entitlement()
{
	if [ "$PRODUCT" == "symphony" ]
	then
		if [ -n "${uri_file_entitlement}" ]
		then
			wget -nH -c --no-check-certificate -O ${ENTITLEMENT_FILE} ${uri_file_entitlement}
		elif [ -n "$entitlement" ]
		then
			echo $entitlement | base64 -d > ${ENTITLEMENT_FILE}
			sed -i 's/\(sym_[a-z]*_edition .*\)/\n\1/' ${ENTITLEMENT_FILE}
			echo >> ${ENTITLEMENT_FILE}
		else
			echo noentitlement
		fi
	fi
}

function install_symphony()
{
	LOG "installing ${PRODUCT} version ${VERSION} ..."
	sed -i -e '/7869/d'  -e '/7870/d' -e '/7871/d' /etc/services
	echo "... trying to install symphony version $VERSION"
	if [ -d /opt/ibm/spectrumcomputing ]
	then
		LOG "bypassing installing $PRODUCT ..."
	else
		if [ "${ROLE}" == "symde" ]
		then
			if [ "$VERSION" == "latest" -o "$VERSION" = "7.2.0.0" -o "$VERSION" == "7.2.0.2"  ]
			then
				LOG "\tsh /export/symphony/${VERSION}/symde-7.2.0.0_x86_64.bin --quiet"
				sh /export/symphony/${VERSION}/symde-7.2.0.0_x86_64.bin --quiet
			fi
		else
			if [ "${ROLE}" == "compute" ]
			then
				export EGOCOMPUTEHOST=Y
			fi
			if [ "$VERSION" == "latest" -o "$VERSION" = "7.2.0.0" -o "$VERSION" == "7.2.0.2" ]
			then
				LOG "\tsh /export/symphony/${VERSION}/sym-7.2.0.0_x86_64.bin --quiet"
				sh /export/symphony/${VERSION}/sym-7.2.0.0_x86_64.bin --quiet
			elif [ "$VERSION" == "7.1.2" ]
			then
				LOG "\tsh /export/symphony/${VERSION}/sym-7.1.2.0_x86_64.bin --quiet"
				sh /export/symphony/${VERSION}/sym-7.1.2.0_x86_64.bin --quiet
			else
				LOG "\tfailed to install application"
				echo "... unimplimented version"
				echo "... failed to install application" >> /root/symphony_failed
			fi
		fi
	fi
}

function start_symphony()
{
	if [ "${ROLE}" == "master" -o "${ROLE}" == "failover" -o "${ROLE}" == "compute" ]
	then
		LOG "\tstart symphony..."
		if [ -f /etc/redhat-release ]
		then
			service ego start
		elif [ -f /etc/lsb-release ]
		then
			/etc/rc3.d/S95ego start
		else
			echo "no start"
		fi
	fi
}

function configure_symphony()
{
	SOURCE_PROFILE=/opt/ibm/spectrumcomputing/profile.platform
	## currently only single master
		# no failover
	if [ "${ROLE}" == "master" ]
	then
		LOG "configure symphony master ..."
		LOG "\tsu $CLUSTERADMIN -c \". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f; egoconfig setentitlement ${ENTITLEMENT_FILE}\""
		su $CLUSTERADMIN -c ". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f; egoconfig setentitlement ${ENTITLEMENT_FILE}"
		sed -i 's/AUTOMATIC/MANUAL/' /opt/ibm/spectrumcomputing/eservice/esc/conf/services/named.xml
		sed -i 's/AUTOMATIC/MANUAL/' /opt/ibm/spectrumcomputing/eservice/esc/conf/services/wsg.xml
		## disable compute role on head if there is compute nodes
		if [ ${numbercomputes} -gt 0 ]
		then
			if [ ! -f /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.${clustername} ]
			then
				sed -ibak "s/cluster1/${clustername}/" /opt/ibm/spectrumcomputing/kernel/conf/ego.shared
				cp /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.cluster1  /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.${clustername}
			fi
			sed -ibak "s/\(^${MASTERHOST} .*\)(linux)\(.*\)/\1(linux mg)\2/" /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.${clustername}
		fi
		if [ -d /failover ]
		then
			chown -R $CLUSTERADMIN /failover
			LOG "configure symphony master for failover using /failover..."
			su $CLUSTERADMIN -c ". ${SOURCE_PROFILE}; egoconfig mghost /failover -f"
			sleep 10
			touch /failover/configured-${localhostname}
			mc=`echo ${MASTERHOST} | sed -e 's/0$/1/'`
			while [ ! -f /failover/configured-${mc} ]
			do
				echo "... waiting for master candidate ${mc} to configure"
				sleep 30
			done
			su $CLUSTERADMIN -c ". ${SOURCE_PROFILE}; egoconfig masterlist ${MASTERHOST},${mc} -f"
			if [ ${numbercomputes} -gt 0 ]
			then
				if [ ! -f /failover/kernel/conf/ego.cluster.${clustername} ]
				then
					sed -ibak "s/cluster1/${clustername}/" /failover/kernel/conf/ego.shared
					cp /failover/kernel/conf/ego.cluster.cluster1  /failover/kernel/conf/ego.cluster.${clustername}
				fi
				sed -ibak "s/\(^${MASTERHOST} .*\)(linux)\(.*\)/\1(linux mg)\2/" /failover/kernel/conf/ego.cluster.${clustername}
			fi
		fi
	## handle failover
	elif [ "$ROLE" == "failover" ]
	then
		LOG "configure symphony master failover..."
		chown -R $CLUSTERADMIN /failover
		while [ ! -f /failover/configured-${MASTERHOST} ]
		do
			echo "... waiting for master ${MASTERHOST} to configure"
			sleep 30
		done
		sleep 60
		LOG "\tsu $CLUSTERADMIN -c \". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f; egoconfig mghost /failover -f\""
		su $CLUSTERADMIN -c ". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f; egoconfig mghost /failover -f"
		sed -i 's/AUTOMATIC/MANUAL/' /opt/ibm/spectrumcomputing/eservice/esc/conf/services/named.xml
		sed -i 's/AUTOMATIC/MANUAL/' /opt/ibm/spectrumcomputing/eservice/esc/conf/services/wsg.xml
		touch /failover/configured-${localhostname}
		sleep 120
	elif [ "$ROLE" == "compute" ]
	then
		LOG "configure symphony compute node ..."
		LOG "\tsu $CLUSTERADMIN -c \". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f\""
		su $CLUSTERADMIN -c ". ${SOURCE_PROFILE}; egoconfig join ${MASTERHOST} -f"
	elif [ "$ROLE" == "symde" ]
	then
		LOG "configure symphony de node ..."
		sed -i "s/^EGO_MASTER_LIST=.*/EGO_MASTER_LIST=${MASTERHOST}/" /opt/ibm/spectrumcomputing/symphonyde/de72/conf/ego.conf
		sed -i "s/^EGO_KD_PORT=.*/EGO_KD_PORT=7870/" /opt/ibm/spectrumcomputing/symphonyde/de72/conf/ego.conf
		sed -i 's/$version = "3"/$version = "3" -o $version = "4"/' /opt/ibm/spectrumcomputing/symphonyde/de72/conf/profile.symclient
		LOG "\tconfigured symphony de node ..."
	else
		echo nothing to do
	fi
	if [ "${ROLE}" == "master" -o "${ROLE}" == "failover" -o "${ROLE}" == "compute" ]
	then
		LOG "prepare to start symphony cluster ..."
		LOG "\tegosetrc.sh; egosetsudoers.sh"
		. ${SOURCE_PROFILE}
		egosetrc.sh
		egosetsudoers.sh
		sleep 2
	fi
}

function funcGeneratePost()
{
cat << ENDF > /tmp/post.sh
if [ "${ROLE}" == "symde" ]
then
	echo -e "\tpost configuration for DE host" >> ${LOG_FILE}
	echo -e "\t...logon to soam client" >> ${LOG_FILE}
	while [ 1 -lt 2 ]
	do
		if su - $clusteradmin -c "soamlogon -u Admin -x Admin" >/dev/null 2>&1
		then
			break
		else
			echo -e "\t... waiting for cluster" >> ${LOG_FILE}
			sleep 60
		fi
	done
	echo -e "\t...logged on to soam client" >> ${LOG_FILE}
	echo -e "\twait 2 minutes for the master to create consumer" >> ${LOG_FILE}
	sleep 150
	su - $clusteradmin -c "cd /opt/ibm/spectrumcomputing/symphonyde/de72/7.2/samples/CPP/SampleApp; make ; cd Output; gzip SampleServiceCPP; soamdeploy add SampleServiceCPP -p SampleServiceCPP.gz -c \"/SampleAppCPP\""
	su - $clusteradmin -c "cd /opt/ibm/spectrumcomputing/symphonyde/de72/7.2/samples/CPP/SampleApp; sed -ibak 's/<SSM resReq/<SSM resourceGroupName=\"ManagementHosts\" resReq/' SampleApp.xml; sed -ibak 's/preStartApplication=/resourceGroupName=\"ComputeHosts\" preStartApplication=/' SampleApp.xml; soamreg SampleApp.xml" >> $LOG_FILE 2>&1
	echo -e "\tSampleAppCPP registered..." >> ${LOG_FILE}
	#su - $clusteradmin -c "cd /opt/ibm/spectrumcomputing/symphonyde/de72/7.2/samples/CPP/SampleApp/Output; ./SyncClient ; sleep 5; ./AsyncClient" >> $LOG_FILE 2>&1

elif [ "${ROLE}" == 'master' ]
then
	while [ 1 -lt 2 ]
	do
		if su - $clusteradmin -c "egosh user logon -u Admin -x Admin" >/dev/null 2>&1
		then
			break
		else
			sleep 60
		fi
	done
	. ${SOURCE_PROFILE}
	egosh user logon -u Admin -x Admin
	echo -e "\t...logged on to ego" >> ${LOG_FILE}
#	if [ -d /failover ]
#	then
#		mc=`echo $MASTERHOST | sed -e 's/0$/1/'`
#		echo -e "\t...configuring failover" >> ${LOG_FILE}
#		. ${SOURCE_PROFILE}
#		while ! egosh resource list -l | grep "\$mc.*ok" | grep -v grep > /dev/null
#		do
#				echo ... waiting for service to come up \`date\` >> ${LOG_FILE}
#				sleep 20
#		done
#		su - $clusteradmin -c ". ${SOURCE_PROFILE}; egoconfig masterlist ${MASTERHOST},`echo ${MASTERHOST} | sed -e 's/0$/1/'` -f"
#		sleep 10
#		egosh ego restart -f
#		sleep 60
#		while ! egosh resource view \$mc | grep "resourceattr.*mg" | grep -v grep > /dev/null 2>&1
#		do
#				echo ... waiting for master candidata \$mc to become management host  >> ${LOG_FILE}
#				sleep 30
#		done
#	fi
else
	echo "nothing to do"
fi
ENDF
chmod +x /tmp/post.sh
}

function deploy_product() {
	install_symphony >> $LOG_FILE 2>&1
	configure_symphony >> $LOG_FILE 2>&1
	update_profile_d
	start_symphony >> $LOG_FILE 2>&1
	sleep 120 
	## watch 2 more rounds to make sure symhony service is running
	declare -i ROUND=0
	while [ $ROUND -lt 2 ]
	do
		if [ "$ROLE" == "symde" ]
		then
			break
		fi
		if ! ps ax | egrep "opt.ibm.*lim" | grep -v grep > /dev/null
		then
			start_symphony
			sleep 120
			continue
		else
			sleep 20
			. ${SOURCE_PROFILE}
			ROUND=$((ROUND+1))
			## prepare demo examples
			LOG "prepare demo examples ..."
			LOG "\tlogging in ..."
			egosh user logon -u Admin -x Admin
			LOG "\tlogged in ..."
			LOG "create /SampleAppCPP consumer ..."
			egosh consumer add "/SampleAppCPP" -a Admin -u Guest -e $clusteradmin -g "ManagementHosts,ComputeHosts" >> $LOG_FILE 2>&1
			LOG "\tconsumer /SampleAppCPP created"
			break
		fi
	done
	echo "$PRODUCT $VERSION $ROLE ready `date`" >> /root/application-ready
	LOG "symphony cluster is now ready ..."
	LOG "generating symphony post configuration activity"
	funcGeneratePost
}
##################END FUNCTIONS RELATED######################
