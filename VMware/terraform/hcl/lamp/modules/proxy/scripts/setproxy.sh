# =================================================================
# Copyright 2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================
#!/bin/bash
if (( $# != 4 )); then
echo "usage: arg 1 is proxy host, arg 2 is proxy user, arg3 is proxy password, arg 4 is proxy port"
exit -1
fi

HTTP_PROXY_HOST="$1"
HTTP_PROXY_USER="$2"
HTTP_PROXY_PASSWORD="$3"
HTTP_PROXY_PORT="$4"

function begin_message() {
  # Function is used to log the start of some configuration function
	config_name=$1
  string="============== Configure : $config_name : $TEMPLATE_TIMESTAMP =============="
  echo "`echo $string | sed 's/./=/g'`"
  echo "$string"
  echo -e "`echo $string | sed 's/[^=]/ /g'`\n"
}

function end_message() {
	string="============== Completed : $config_name, Status: $1 =============="
	echo -e "\n`echo $string | sed 's/[^=]/ /g'`"
	echo "$string"
	echo -e "`echo $string | sed 's/./=/g'`\n\n"
	config_name="unknown"
}

# Check if a command exists
command_exists() {
  type "$1" &> /dev/null;
}

#Get platform
function get_platform() {
  PLATFORM=""
  if command_exists python; then
    PLATFORM=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
  else
    if command_exists python3; then
      PLATFORM=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
    fi
  fi

  # Check if the executing platform is supported
  if [[ $PLATFORM == *"ubuntu"* ]] || [[ $PLATFORM == *"redhat"* ]] || [[ $PLATFORM == *"rhel"* ]] || [[ $PLATFORM == *"centos"* ]]; then
    echo "$PLATFORM"
  else
    echo "ERROR"
  fi
}

begin_message $HTTP_PROXY_HOST
begin_message $HTTP_PROXY_USER
begin_message $HTTP_PROXY_PORT

 
if [[ -z "$HTTP_PROXY_HOST" ]]; then
	begin_message Proxy host is empty, skipping proxy configuration
else
	begin_message Set up proxy
	PLATFORM=$(get_platform)
	if [[ "$PLATFORM" == "ERROR" ]] ; then
	  echo "[ERROR] Platform $PLATFORM not supported"
	  exit 1      
	fi
	###
	#Allow sudo users to use the http_proxy 
	#https_proxy no_proxy env variables
	###
  sudo touch /etc/sudoers.tmp
  sudo cp /etc/sudoers /tmp/sudoers.mod
  sudo sh -c 'echo "Defaults env_keep += \"http_proxy https_proxy no_proxy\"" >> /tmp/sudoers.mod'
  sudo visudo -c -f /tmp/sudoers.mod
  if [ "$?" -eq "0" ]; then
    sudo mv /tmp/sudoers.mod /etc/sudoers
  fi
  sudo rm /etc/sudoers.tmp  
  
	###
	#Process http proxy data type 
	#and set exports
	###  
  PROTOCOL="$(echo $HTTP_PROXY_HOST |  grep :// | sed -e 's/^\(.*:\/\/\).*/\1/g')"	
  HTTP_PROXY_HOST=`echo ${HTTP_PROXY_HOST/$PROTOCOL/}`

  begin_message "Set http proxy environment variables"  
  HTTP_PROXY_VAR=$PROTOCOL
  HTTPS_PROXY_VAR=$PROTOCOL
  if [[ -n "$HTTP_PROXY_USER" && -n "$HTTP_PROXY_PASSWORD" ]]; then
    HTTP_PROXY_VAR="$HTTP_PROXY_VAR$HTTP_PROXY_USER:$HTTP_PROXY_PASSWORD@"
    HTTPS_PROXY_VAR="$HTTPS_PROXY_VAR$HTTP_PROXY_USER:$HTTP_PROXY_PASSWORD@"
  fi
  HTTP_PROXY_VAR="$HTTP_PROXY_VAR$HTTP_PROXY_HOST"
  HTTPS_PROXY_VAR="$HTTPS_PROXY_VAR$HTTP_PROXY_HOST"
  if [[ -n "$HTTP_PROXY_PORT"  ]]; then
    HTTP_PROXY_VAR="$HTTP_PROXY_VAR:$HTTP_PROXY_PORT"
    HTTPS_PROXY_VAR="$HTTPS_PROXY_VAR:$HTTP_PROXY_PORT"
  fi
  export http_proxy=$HTTP_PROXY_VAR
  export https_proxy=$HTTPS_PROXY_VAR
  NO_PROXY="127.0.0.1,localhost"
  export no_proxy=$NO_PROXY
  echo "export http_proxy=$HTTP_PROXY_VAR" | sudo tee --append /etc/profile.d/proxy-env-var.sh
  echo "export https_proxy=$HTTPS_PROXY_VAR" | sudo tee --append /etc/profile.d/proxy-env-var.sh
  echo "export no_proxy=$NO_PROXY" | sudo tee --append /etc/profile.d/proxy-env-var.sh  
  ###
  #Set proxy for apt or yum 
  ###  
  if [[ $PLATFORM == *"ubuntu"* ]]; then    
    echo "Acquire::http::Proxy \"${HTTP_PROXY_VAR}/\";" | sudo tee --append /etc/apt/apt.conf
    echo "Acquire::https::Proxy \"${HTTPS_PROXY_VAR}/\";" | sudo tee --append /etc/apt/apt.conf
  else  
    RHEL_HTTP_PROXY_VAR="proxy=$PROTOCOL$HTTP_PROXY_HOST"
    if [[ -n "$HTTP_PROXY_PORT"  ]]; then
      RHEL_HTTP_PROXY_VAR="$RHEL_HTTP_PROXY_VAR:$HTTP_PROXY_PORT"
    fi
    RHEL_HTTP_PROXY_PASSWORD="proxy_password=$HTTP_PROXY_PASSWORD"
    RHEL_HTTP_PROXY_USER="proxy_username=$HTTP_PROXY_USER"
    sudo sed -i "/\[main\]/a $RHEL_HTTP_PROXY_VAR\n$RHEL_HTTP_PROXY_PASSWORD\n$RHEL_HTTP_PROXY_USER" /etc/yum.conf  
   fi  
fi
