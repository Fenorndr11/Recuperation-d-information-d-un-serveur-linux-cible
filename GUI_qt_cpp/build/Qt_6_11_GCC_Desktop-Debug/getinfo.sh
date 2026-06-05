#!/bin/bash

#####################################################################
#                                                                   #
#   BASH SCRIPTING FOR RETRIVIAL INFORMATION FROM A LINUX SERVER    #
#                                                                   #
#####################################################################

###definition des foncions necessaires
sec_field()
{
  cut -d ":" -f2 |xargs
}

###definition des codes couleurs utilisés
r='\033[0;31m' #rouge
v='\033[0;32m' #vert
j='\033[0;33m' #jaune
b='\033[0;34m' #bleu
nc='\033[0m'   #default


###rafraichit l'ecran du terminal
clear

###verifie l'argument entré
if [[ $# -ne 0 ]];then
  echo -e "${r}Erreur:${nc} Mauvais argument, Usage : $0"
  exit 1
fi

###verifie l'OS à analyser
if [[ $OSTYPE != linux* ]];then
    echo -e "${r}Erreur:${nc} Mauvais type d'OS, SUPPORTE SEULEMENT UN SYSTEME LINUX"
    exit 1
fi

###Extraction des informations systemes à l'aide du fichier os-release
##On copie les variables du fichier os_release dans l'environnement
if [[ -r /etc/os-release ]];then
  . /etc/os-release
elif [[ -r /usr/lib/os-release ]];then
  . /usr/lib/os-release
fi

echo -e "${r}\t\t\t======================\n\t\t\t  OS INFORMATION\n\t\t\t====================== ${nc}"
echo -e "${b}Distribution linux: ${nc} ${j} ${PRETTY_NAME}${nc}"
echo -e "${b}Noyau (Linux Kernel): ${nc} ${j}$(</proc/sys/kernel/osrelease)${nc}"
echo -e "${b}Interpreteur de commande (chemin): ${nc} ${j} $SHELL ${nc}"

###Recuperation des informations coté materielle et fabricant grace aux fichiers dans /sys/class/dmi/id
file=/sys/class/dmi/id
echo -e "\n\n${r}\t\t\t======================\n\t\t\t  HARDWARE INFORMATION\n\t\t\t====================== ${nc}"
if [[ -d $file ]];then
  if [[ -r "$file/sys_vendor" ]];then
    model=$(<$file/sys_vendor)
  elif [[ -r "$file/board_vendor" ]];then
  model=$(<$file/board_vendor)
  elif [[ -r "$file/chassis_vendor" ]];then
  model=$(<$file/chassis_vendor)
  fi
  
  if [[ -r "$file/product_name" ]];then
  model+=" $(<$file/product_name)"
  fi
  if [[ -r "$file/product_version" ]];then
  model+=" $(<$file/product_version)"
  fi
elif [[ -r /sys/firmware/devicetree/base/model ]];then
  model=$(cat /sys/firmware/devicetree/base/model)
fi
if [[ -n $model ]];then
  echo -e "${b}Modele du machine: ${nc} ${j}$model${nc}"
fi

##architecture et information cpu
info=$(lscpu)
core_per_socket=$(echo "$info" | awk -F: '/^Core\(s\) per socket/ {gsub(/ /,"",$2); print $2}')
threads_per_core=$(echo "$info" | awk -F: '/^Thread\(s\) per core/ {gsub(/ /,"",$2); print $2}')
sockets=$(echo "$info"          | awk -F: '/^Socket\(s\)/          {gsub(/ /,"",$2); print $2}')
echo -e "${b}Architecture: ${nc} ${j}$(echo "$info" |head -n 1 |tail -n 1 | sec_field)${nc}" #sed 's/^( ){20}//g')${nc}"
echo -e "${b}Modele CPU: ${nc} ${j}$(echo "$info" |head -n 8 |tail -n 1 | sec_field)${nc}"
echo -e "${b}CPU cores/threads/sockets: ${nc} ${j} $((core_per_socket * sockets))/$(echo "$threads_per_core*$core_per_socket*$sockets" |bc -l)/$(echo "$sockets" |bc -l) ${nc}"

##information memoire (coté RAM et disque)
mem=$(free -h |head -n 2 |tail -n 1)
echo -e "${b}RAM:${nc}"
echo -e "${v} _totale: ${nc} ${j}$(echo -e "$mem" |awk '{ print $2 }') ${nc}"
echo -e "${v} _disponible (prete à utiliser): ${nc} ${j}$(echo -e "$mem" |awk '{ print $7 }' |sed 's/i//g') ${nc}"
echo -e "${v} _libre (non utilisée mais récupérable) : ${nc} ${j}$(echo -e "$mem" |awk '{ print $4 }' |sed 's/i//g') ${nc}"
nb_disque=$(lsblk -d -e 7 -o NAME,SIZE |wc -l)
disque=$(lsblk -d -o NAME,SIZE)
line=2
echo -e "${b}DISQUE:${nc}"
while((line <= nb_disque));do
  echo -e "${v} $(echo -e "$disque" |head -n $line |tail -n 1) ${nc}"
  ((line++))
done

###information cote logiciel
echo -e "\n\n${r}\t\t\t======================\n\t\t\t  SOFTWARE INFORMATION\n\t\t\t====================== ${nc}"
##nombre de logiciel installé selon gestionnaire de paquet
if command -v dpkg &> /dev/null; then
    total=$(dpkg -l | grep -c ^ii)
elif command -v rpm &> /dev/null; then
    total=$(rpm -qa | wc -l)
elif command -v pacman &> /dev/null; then
    total=$(pacman -Q | wc -l)
else
    total="Inconnu (gestionnaire non supporté)"
fi

echo -e "${b}Nombre de paquets installés: ${nc} ${j}$total${nc}"
echo -e "${b}Nombre de processus en cours: ${nc} ${j}$(ps -e --no-headers | wc -l)${nc}"

###information cote reseau
echo -e "\n\n${r}\t\t\t======================\n\t\t\t  NETWORK INFORMATION\n\t\t\t====================== ${nc}"
echo -e "${b}Nom de la machine: ${nc} ${j}$HOSTNAME${nc}"
if command -v iwgetid >/dev/null; then
  NETWORKNAME=$(iwgetid -r || true)
fi
if [[ -n $NETWORKNAME ]]; then
  echo -e "${b}Nom du reseau (SSID): ${nc} ${j}$NETWORKNAME${nc}"
fi
echo -e "${b}Adresse ipv4: ${nc} ${j}$(ip -o -4 a show up scope global | awk '{ print $2,$4 }')${nc}"
for interface in $(ip -o a show up primary scope global | awk '{ print $2 }' | uniq); do
    mac=$(</sys/class/net/$interface/address)
    echo -e "${b}MAC ($interface):${nc} ${j}$mac${nc}"
done