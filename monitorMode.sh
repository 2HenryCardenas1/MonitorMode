#!/bin/bash

#Autor : Henry Cardenas (H3C4)

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


#take ctrl+c
trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo${endColour}"
	tput cnorm; 
    airmon-ng stop ${networkCard} > /dev/null 2>&1
	sudo systemctl restart networking.service > /dev/null 2>&1
	exit 0
}

function helpPanel(){
    
    echo -e "\n${yellowColour}[*]${endColour}${grayColour} Uso: ./monitorMode.sh -o opcion -n nombre-interfaz ${endColour}"
	echo -e "\n\t${purpleColour}[*]${purpleColour}${yellowColour} Opcion :${yellowColour}"
    echo -e "\n\t\t${blueColour}[!]${endColour}${grayColour} -o start${endColour}"
    echo -e "\t\t${blueColour}[!]${endColour}${grayColour} -o stop${endColour}"
    iwconfig >/tmp/iwconfig.tmp 2>&1
    networkCard=$(cat /tmp/iwconfig.tmp | grep 'wlan' | awk '{print $1}' |xargs | tr -d '\n');
    echo -e "\n\t${purpleColour}n)${endColour}${yellowColour} Nombre de la tarjeta de red: ${endColour}"
    echo -e "\t\t ${redColour}[!] Este es el nombre de su tarjeta de red:${endColour} ${turquoiseColour}( $networkCard )${endColour}"
    rm /tmp/iwconfig.tmp  2>&1
    exit 0
	
}

function dependencies(){
	tput civis
	clear;
    dependencies=(aircrack-ng macchanger)

	echo -e "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios...${endColour}"
	sleep 2

	for program in "${dependencies[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta${endColour}${purpleColour} $program${endColour}${blueColour}...${endColour}"

		test -f /usr/bin/$program

		if [ "$(echo $?)" == "0" ]; then
			echo -e " ${greenColour}(V)${endColour}"
		else
			echo -e " ${redColour}(X)${endColour}\n"
			echo -e "${yellowColour}[*]${endColour}${grayColour} Instalando herramienta ${endColour}${blueColour}$program${endColour}${yellowColour}...${endColour}"
			apt-get install $program -y > /dev/null 2>&1
		fi; sleep 1
	done
}


function onMonitorMode(){
    clear 
    if [ "$(echo $optionMode)" == "start" ]; then
        echo -e "${yellowColour}[*]${endColour}${grayColour} Configurando tarjeta de red...${endColour}\n"
        airmon-ng check kill > /dev/null 2>&1
        airmon-ng start $networkCard > /dev/null 2>&1
        ifconfig ${networkCard} down && macchanger -a ${networkCard} > /dev/null 2>&1
        ifconfig ${networkCard} up; 
        killall dhclient wpa_supplicant 2>/dev/null
        echo -e "${yellowColour}[*]${endColour}${grayColour} Nueva dirección MAC asignada ${endColour}${purpleColour}[${endColour}${blueColour}$(macchanger -s ${networkCard} | grep -i current | xargs | cut -d ' ' -f '3-100')${endColour}${purpleColour}]${endColour}"

    elif [ "$(echo $optionMode)" == "stop" ]; then
        tput cnorm;
        echo -e "${yellowColour}[*]${endColour}${grayColour} Configurando tarjeta de red...${endColour}\n"
        airmon-ng stop ${networkCard} > /dev/null 2>&1
        sleep 2
        airmon-ng check kill > /dev/null 2>&1
        sleep 1
        ifconfig ${networkCard} down > /dev/null 2>&1
        iwconfig ${networkCard} mode managed > /dev/null 2>&1
        ifconfig ${networkCard} up > /dev/null 2>&1
        systemctl restart networking.service > /dev/null 2>&1
        /etc/init.d/networking restart > /dev/null 2>&1
        sleep 1
        echo -e "\n${greenColour}[*] Tarjeta de red reestablecida${endCologreenColourur}\n"

    else
		echo -e "\n${redColour}[*] Esa opcion no es válido${endColour}\n"
	fi
    
}

if [ "$(id -u)" == "0" ]; then
declare -i parameter_counter=0; while getopts ":o:n:h:" arg; do
		case $arg in
        #Opciones
            o) optionMode=$OPTARG; let parameter_counter+=1 ;;
            n) networkCard=$OPTARG; let parameter_counter+=1 ;;
			h) helpPanel;;
		esac
	done

	if [ $parameter_counter -ne 2 ]; then
		helpPanel
	else
        
        dependencies
		onMonitorMode
		tput cnorm; 
        airmon-ng stop ${networkCard}mon > /dev/null 2>&1
	fi
else
	echo -e "\n${redColour}[*] No soy root${endColour}\n"
fi
