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
import sys
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for data in sys.argv:
	print(data)
	s.sendto(data,('${masteripaddress}',9999))
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
	LOG "handle lsf dependancy ..."
	if [ "${PRODUCT}" == "lsf" ]
	then
		if [ -f /etc/redhat-release ]
		then
			LOG "\tyum -y install java-1.7.0-openjdk gcc gcc-c++ glibc.i686 httpd"
			yum -y install java-1.7.0-openjdk gcc gcc-c++ glibc.i686 httpd
		elif [ -f /etc/lsb-release ]
		then
			LOG "\tapt-get install -y gcc g++ openjdk-8-jdk make"
			if  cat /etc/lsb-release | egrep -qi "ubuntu 16"
			then
				apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages gcc g++ openjdk-8-jdk make
			else
				apt-get install -y --force-yes gcc g++ openjdk-7-jdk make
			fi
		else
			echo "unknown"
		fi
	elif [ "${PRODUCT}" == "lsf" ]
	then
		LOG "...handle lsf dependancy"
	else
		LOG "...unknown application"
	fi
}

function download_packages()
{
	if [ "$MASTERHOSTNAMES" == "$MASTERHOST" ]
	then
		# we can get the package from anywhere applicable, then export through nfs://export, not implemented here yet
		if [ "$PRODUCT" == "lsf" ]
		then
			LOG "download lsf packages ..."
			mkdir -p /export/lsf/${VERSION}
			if [ "${VERSION}" == "latest" ]
			then
				ver_in_pkg=10.1
			else
				ver_in_pkg=${VERSION}
			fi
			export LSF_INSTALL_PACKAGE=lsf${ver_in_pkg}_lsfinstall_linux_x86_64.tar.Z
			if [ "$ROLE" == 'master' ]
			then
				if echo ${uri_package_additonal} | egrep -qv "additional$"
				then
					LOG "\twget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_linux2.6-glibc2.3-x86_64.tar.Z ${uri_package_additional}"
					cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_linux2.6-glibc2.3-x86_64.tar.Z ${uri_package_additional}
				fi
				if echo ${uri_package_additonal2} | egrep -qv "additional2$"
				then
					LOG "\twget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_lnx310-lib217-x86_64.tar.Z ${uri_package_additional2}"
					cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_lnx310-lib217-x86_64.tar.Z ${uri_package_additonal2}
				fi
				cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O ${LSF_INSTALL_PACKAGE} ${uri_package_installer}
				touch /export/download_finished
			else
				if [ "$useintranet" == 'false' ]
				then
					if [ "${ROLE}" == "compute" ]
					then
						if echo ${uri_package_additonal} | egrep -qv "additional$"
						then
							LOG "\twget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_linux2.6-glibc2.3-x86_64.tar.Z ${uri_package_addtional}"
							cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_linux2.6-glibc2.3-x86_64.tar.Z ${uri_package_additional}
						fi
						if echo ${uri_package_additonal2} | egrep -qv "additional2$"
						then
							LOG "\twget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_lnx310-lib217-x86_64.tar.Z ${uri_package_additional2}"
							cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O lsf${ver_in_pkg}_lnx310-lib217-x86_64.tar.Z ${uri_package_additional2}
						fi
						LOG "\twget -nH -c --no-check-certificate -o /dev/null -O ${LSF_INSTALL_PACKAGE} ${uri_package_installer}"
						cd /export/lsf/${VERSION} && wget -nH -c --no-check-certificate -o /dev/null -O ${LSF_INSTALL_PACKAGE} ${uri_package_installer}
						touch /export/download_finished
					else
						echo "no download"
					fi
				fi
			fi
		fi
	else
		echo "wont come here before failover implementation"
	fi
}

function generate_entitlement()
{
	if [ -n "$uri_file_entitlement" ]
	then
		wget -nH -c --no-check-certificate -O ${ENTITLEMENT_FILE} ${uri_file_entitlement}
	elif [ -n "$entitlement" ]
	then
		echo $entitlement | base64 -d > ${ENTITLEMENT_FILE}
		sed -i 's/\(conductor_spark .*\)/\n\1/' ${ENTITLEMENT_FILE}
		echo >> ${ENTITLEMENT_FILE}
	fi
}

function install_product()
{
	export DESTINATION_DIR=/tmp/lsfinstall
	mkdir -p $DESTINATION_DIR
	LSF_INSTALL_PACKAGENAME=${LSF_INSTALL_PACKAGE%%_linux*}
	LSF_MASTER_LIST=${MASTERHOSTNAMES}
	cd $DESTINATION_DIR
	ln -s /export/${PRODUCT}/${VERSION}/${LSF_INSTALL_PACKAGE} .
	ln -s /export/${PRODUCT}/${VERSION}/lsf10.1_linux2.6-glibc2.3-x86_64.tar.Z .
	ln -s /export/${PRODUCT}/${VERSION}/lsf10.1_lnx310-lib217-x86_64.tar.Z .
	tar -zxf $DESTINATION_DIR/${LSF_INSTALL_PACKAGE} -C $DESTINATION_DIR
	#Modify lsfinstall
	sed -i -e "s|show_copyright|#show_copyright|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/lsfinstall
	#Modify lsfprechkfuncs.sh
	sed -i -e "s|read _n|_n=1|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/instlib/lsfprechkfuncs.sh

	LOG "installing ${PRODUCT} version ${VERSION} ..."
	sed -i -e '/7869/d'  -e '/7870/d' -e '/7871/d' /etc/services
	echo "... trying to install ${PRODUCT} version $VERSION"
	if [ "$VERSION" == "latest" -o "$VERSION" = "10.1" ]
	then
		if [ "${ROLE}" == "master" ]
		then
			LOG "\t./lsfinstall -f install.config >>$LOG_FILE"
			sed -i -e "s|# LSF_TOP=\"/usr/share/lsf\"|LSF_TOP=\"/opt/lsf\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			sed -i -e "s|# LSF_ADMINS=\"lsfadmin user1 user2\"|LSF_ADMINS=\"$CLUSTERADMIN\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			sed -i -e "s|# LSF_CLUSTER_NAME=\"cluster1\"|LSF_CLUSTER_NAME=\"$CLUSTERNAME\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			sed -i -e "s|# LSF_MASTER_LIST=\"hostm hosta hostc\"|LSF_MASTER_LIST=\"${MASTERHOSTNAMES}\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			sed -i -e "s|# LSF_ENTITLEMENT_FILE=.*|LSF_ENTITLEMENT_FILE=\"${ENTITLEMENT_FILE}\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			sed -i -e "s|# ENABLE_DYNAMIC_HOSTS=\"N\"|ENABLE_DYNAMIC_HOSTS=\"Y\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/install.config
			cd $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/
			./lsfinstall -f install.config >>$LOG_FILE 2>&1
		elif [ "${ROLE}" == "compute" ]
		then
			LOG "\t./lsfinstall -s -f slave.config >>$LOG_FILE"
			sed -i -e "s|# LSF_TOP=\"/usr/...../lsf\"|LSF_TOP=\"/opt/lsf\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/slave.config
			sed -i -e "s|# LSF_ADMINS=\"lsfadmin user1 user2\"|LSF_ADMINS=\"$CLUSTERADMIN\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/slave.config
			sed -i -e "s|# LSF_SERVER_HOSTS=\"hostm hosta hostb hostc\"|LSF_SERVER_HOSTS=\"${MASTERHOSTNAMES}\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/slave.config
			sed -i -e "s|# LSF_ENTITLEMENT_FILE=.*|LSF_ENTITLEMENT_FILE=\"${ENTITLEMENT_FILE}\"|" $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/slave.config
			cd $DESTINATION_DIR/$LSF_INSTALL_PACKAGENAME/
			./lsfinstall -s -f slave.config >>$LOG_FILE 2>&1
		else
			echo "no install"
		fi
	else
		LOG "\tfailed to install application"
		echo "... unimplimented version"
		echo "... failed to install application" >> /root/${PRODUCT}_failed
	fi
}

function start_product()
{
	if [ "${ROLE}" == "master" -o "${ROLE}" == "compute" ]
	then
		LOG "\tstart ${product} ..."
	#	source /opt/lsf/conf/profile.lsf
	#	lsadmin ckconfig >>$LOG_FILE 2>&1
	#	lsadmin limstartup >>$LOG_FILE 2>&1
	#	lsadmin resstartup >>$LOG_FILE 2>&1
	#	badmin hstartup >>$LOG_FILE 2>&1
		if [ -f /etc/redhat-release ]
		then
			service lsf start
			service lsfd start
		elif [ -f /etc/lsb-release ]
		then
			/etc/rc3.d/S95lsf start
			/etc/rc3.d/S95lsfd start
		else
			echo "no start"
		fi
	fi
}

function configure_product()
{
	LOG "Configuring LSF ..."
	LSF_CONF="/opt/lsf/conf/lsf.conf"
	LSF_CLUSTER_FILE="/opt/lsf/conf/lsf.cluster.${CLUSTERNAME}"
	LSB_PARAMETER="/opt/lsf/conf/lsbatch/${CLUSTERNAME}/configdir/lsb.params";
	## currently only single master
	if [ "$MASTERHOSTNAMES" == "$MASTERHOST" ]
	then
		# no failover
		if [ "${ROLE}" == "master" ]
		then
			LOG "configure ${PRODUCT} master ..."
			sed -i -e "s|LSF_DISABLE_LSRUN=Y|LSF_DISABLE_LSRUN=N|" $LSF_CONF
			sed -i -e "s|Administrators =.*|Administrators = ${CLUSTERADMIN}|" $LSF_CLUSTER_FILE
			sed -i -e "s|#EGO_HOST_ADDR_RANGE|EGO_HOST_ADDR_RANGE|" $LSF_CLUSTER_FILE
			sed -i -e "s|#FLOAT_CLIENTS_ADDR_RANGE|FLOAT_CLIENTS_ADDR_RANGE|" $LSF_CLUSTER_FILE
			sed -i -e "s|#FLOAT_CLIENTS|FLOAT_CLIENTS|" $LSF_CLUSTER_FILE
		elif [ "$ROLE" == "compute" ]
		then
			LOG "configure ${PRODUCT} compute node ..."
			sed -i -e "s|LSF_LOGDIR|#LSF_LOGDIR|" $LSF_CONF
		else
			echo nothing to do
		fi
		echo "LSF_RSH=ssh" >> $LSF_CONF
		chown -R ${CLUSTERADMIN}:${CLUSTERADMIN} /opt/lsf >/dev/null 2>&1
	fi
	if [ "${ROLE}" == "master" -o "${ROLE}" == "compute" ]
	then
		LOG "prepare to start ${PRODUCT} cluster ..."
		#Configure LSF as a service to start and stop LSF at system startup and shutdown
		if [ -f /opt/lsf/10.1/install/hostsetup ]
		then
			/opt/lsf/10.1/install/hostsetup --top="/opt/lsf" --boot="y" >>$LOG_FILE 2>&1
		fi
	fi
}

function funcGeneratePost()
{
cat << ENDF > /tmp/post.sh
if [ "${ROLE}" == 'master' ]
then
	if [ ! -f /etc/checkfailover ]
	then
		. /opt/lsf/conf/profile.lsf
	fi
else
	echo "nothing to do"
fi
ENDF
chmod +x /tmp/post.sh
}

function deploy_product() {
	install_product >> $LOG_FILE 2>&1
	configure_product >> $LOG_FILE 2>&1
	update_profile_d
	start_product >> $LOG_FILE 2>&1
	sleep 120
	## watch 2 more rounds to make sure symhony service is running
	declare -i ROUND=0
	while [ $ROUND -lt 2 ]
	do
		if [ "$ROLE" == "symde" ]
		then
			break
		fi
		if ! ps ax | egrep "opt.*lim" | grep -v grep > /dev/null
		then
			start_product
			sleep 120
			continue
		else
			sleep 20
			. ${SOURCE_PROFILE}
			ROUND=$((ROUND+1))
			break
		fi
	done
	echo "$PRODUCT $VERSION $ROLE ready `date`" >> /root/application-ready
	LOG "${PRODUCT} cluster is now ready ..."
	LOG "generating ${PRODUCT} post configuration activity"
	funcGeneratePost
}
##################END FUNCTIONS RELATED######################
