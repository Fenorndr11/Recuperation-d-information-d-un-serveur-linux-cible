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
echo -e "${b}Noyau (Linux Kernel): ${nc} ${j} $(uname -r)${nc}"
echo -e "${b}Interpreteur de commande (chemin): ${nc} ${j} $(echo "$SHELL")${nc}"

##Recuperation des informations coté materielle et fabricant grace aux fichiers dans /sys/class/dmi/id
file=/sys/class/dmi/id
echo -e "\n\n${r}\t\t\t======================\n\t\t\t  HARDWARE INFORMATION\n\t\t\t====================== ${nc}"
if [[ -d $file ]];then
  if [[ -r "$file/sys_vendor" ]];then
    model=$(cat $file/sys_vendor)
  elif [[ -r "$file/board_vendor" ]];then
	model=$(cat $file/board_vendor)
  elif [[ -r "$file/chassis_vendor" ]];then
	model=$(cat $file/chassis_vendor)
  fi
  
  if [[ -r "$file/product_name" ]];then
	model+=" $(cat $file/product_name)"
  fi
  if [[ -r "$file/product_version" ]];then
	model+=" $(cat $file/product_version)"
  fi
elif [[ -r /sys/firmware/devicetree/base/model ]];then
  model=$(cat /sys/firmware/devicetree/base/model)
fi
if [[ -n $model ]];then
  echo -e "${b}Modele du machine: ${nc} ${j}$model${nc}"
fi

##architecture et information cpu
info=$(lscpu)
core_per_socket=$(echo "$info" |head -n 12 |tail -n 1 | sec_field)
threads_per_core=$(echo "$info" |head -n 11 |tail -n 1 | sec_field) 
sockets=$(echo "$info" |head -n 13 |tail -n 1 | sec_field)
echo -e "${b}Architecture: ${nc} ${j}$(echo "$info" |head -n 1 |tail -n 1 | sec_field)${nc}" #sed 's/^( ){20}//g')${nc}"
echo -e "${b}Modele CPU: ${nc} ${j}$(echo "$info" |head -n 8 |tail -n 1 | sec_field)${nc}"
echo -e "${b}CPU cores/threads/sockets: ${nc} ${j} $(echo "$core_per_socket*$sockets" |bc -l)/$(echo "$threads_per_core*$core_per_socket*$sockets" |bc -l)/$(echo "$sockets" |bc -l) ${nc}"

##information memoire (coté RAM et disque)
mem=$(free -h |head -n 2 |tail -n 1)
echo -e "${b}RAM:${nc}"
echo -e "${v}\t_totale: ${nc} ${j}$(echo -e "$mem" |awk '{ print $2 }' |sed 's/i//g') ${nc}"
echo -e "${v}\t_disponible (prete à utiliser): ${nc} ${j}$(echo -e "$mem" |awk '{ print $7 }' |sed 's/i//g') ${nc}"
echo -e "${v}\t_libre (inutilisable): ${nc} ${j}$(echo -e "$mem" |awk '{ print $4 }' |sed 's/i//g') ${nc}"
nb_disque=$(lsblk -d -o NAME,SIZE |wc -l)
disque=$(lsblk -d -o NAME,SIZE)
line=2
echo -e "${b}DISQUE:${nc}"
while((line <= nb_disque));do
  echo -e "${v}\t$(echo -e "$disque" |head -n $line |tail -n 1) ${nc}"
  line=$(echo "$line+1" |bc -l)
done

