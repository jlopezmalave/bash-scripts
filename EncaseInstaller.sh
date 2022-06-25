#!/bin/sh

###############################################
# Title: EnCase Linux Deployment Script
# Version: 1.0
# Change Log:
#   * 1.0 - SF044702 - Initial Script - 11/13/2017
#   * 2.0 - JL044148 - Modified to only use SYSTEMD & Unit Files - 5/23/2018
# Exit Codes:
#   * 1: Failed to stop the running service
#   * 2: Failed to determine bitness
#   * 3: Failed to save iptables
#   * 4: Failed to start the service
#   * 5: Failed to enable service on boot
#   * 100: Already installed and service started
################################################

#Set -x

INSTALLER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTDIR="/opt/Encase"
UNITFILE="/usr/lib/systemd/system/${UNITFILE}"
SYSTEMD=$(command -v systemctl)

check_installed() {
	if [ -d ${INSTDIR} ] && command -v cmp;then
		if cmp --silent "${INSTDIR}/${SERVLET}" "${INSTALLER_DIR}/${SERVLET}"  && cmp --silent "/usr/lib/systemd/system/${UNITSCRIPT}" "${INSTALLER_DIR}/${UNITSCRIPT}";then
				if [ ! -z ${SYSTEMD} ]; then
					if systemctl status $(echo ${UNITSCRIPT} | cut -f1 -d".") | grep -q running;then
						exit 100
					fi
				fi
			start_service
		fi
	fi
}

start_service() {
	if [ ! -z ${SYSTEMD} ]; then
		systemctl start $(echo ${UNITSCRIPT} | cut -f1 -d".")
		if [ "$?" != "0" ];then
			service ${UNITSCRIPT} start
			if [ "$?" != "0" ];then
				exit 4
			fi
		fi
		systemctl enable ${UNITSCRIPT}
		if [ "$?" != "0" ];then
			chkconfig --add ${UNITSCRIPT}
			if [ "$?" =! "0" ];then
				exit 5
			fi
		fi
	fi
}

stop_service() {
	if [ ! -z ${SYSTEMD} ]; then
		if systemctl status $(echo ${UNITSCRIPT} | cut -f1 -d".") | grep -q running;then
			systemctl stop $(echo ${UNITSCRIPT} | cut -f1 -d"/")
			if [ "$?" != "0" ];then
				service ${UNITSCRIPT} stop
				if [ "$?" != "0" ];then
					exit 1
				fi
			fi
		fi
		systemctl disable ${UNITSCRIPT}
		if ["$?" != "0" ];then
			chkconfig --del ${UNITSCRIPT}
		fi
	fi
}

get_bitness() {
	#Identify whether it is a 64 or 32 bit system
	bitness=$(uname -m)
	if [[ "$bitness" == "i686" || "$bitness" == "x86" ]]; then
		SERVLET="enlinuxpc"
		UNITSCRIPT="enlinuxpc.sh"
	elif [ "$bitness" == "x86_64" ]; then
		SERVLET="enlinuxpc64"
		UNITSCRIPT="enlinuxpc64.sh"
	else
		# Cannot determine bitness
		exit
	fi
}

cleanup_old() {
	#Remove existing install
	if [ -d ${INSTDIR} ];then
		rm -R ${INSTDIR}
	fi
	
	#Delete the unit script
	if [ -f "/usr/lib/systemd/system/${UNITSCRIPT}" ]; then
		rm -f /usr/lib/systemd/system/${UNITSCRIPT}
	fi
	
	#Delete the unit file
	if [ -f "/usr/lib/systemd/system/${UNITFILE}" ]; then
		rm -f /usr/lib/systemd/system/${UNITFILE}
	fi
	
	#Create fresh directory
	if [ ! -d "${INSTDIR}" ]; then
		mkdir -p ${INSTDIR}
	fi
}

install_new() {
	# Copy the new EnCase binary
	cp -p ${INSTALLER_DIR}/${SERVLET} ${INSTDIR}/${SERVLET}
 
	# Give the required permissions
	chmod 755 ${INSTDIR}/${SERVLET}
 
	# Copy the new unit script
	cp -p ${INSTALLER_DIR}/${UNITSCRIPT} //usr/lib/systemd/system/${UNITSCRIPT}
 
	# Give it the required permissions
	chmod 755 /usr/lib/systemd/system/${UNITSCRIPT}
	
	# Copy the unit file
	cp -p ${INSTALLER_DIR}/${UNITFILE} //usr/lib/systemd/system/${UNITFILE}
	
}
 
firewall_rules() {

    if [ -f /sbin/iptables-save ];then
        # Remove the iptable rules so we don't add them twice
        iptables -D INPUT -p tcp --dport 4445 -m state --state NEW,ESTABLISHED -j ACCEPT
        iptables -D OUTPUT -p tcp --dport 4445 -m state --state ESTABLISHED -j ACCEPT

        # Add the rules back
        iptables -A INPUT -p tcp --dport 4445 -m state --state NEW,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -p tcp --dport 4445 -m state --state ESTABLISHED -j ACCEPT

        /sbin/iptables-save
        if [ "$?" != "0" ];then
            exit 3
        fi
    fi
}
	
# Get bitness of the server
get_bitness

# Check if the servlet is already installed
check_installed

# Check if the unit file was moved to the correct location
systemctl list-unit-files | grep enlinuxpc

# Enable the unit script
systemctl enable ${UNITSCRIPT}

# Stop the service
stop_service

# Cleanup existing install
cleanup_old