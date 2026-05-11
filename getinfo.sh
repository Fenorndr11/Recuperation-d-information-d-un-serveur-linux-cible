#!/bin/bash

#####################################################################
#                                                                   #
#   BASH SCRIPTING FOR RETRIVIAL INFORMATION FROM A LINUX SERVER    #
#                                                                   #
#####################################################################

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

echo -e "${r}\t\t\t======================\n\t\t\t\tOS INFORMATION\n\t\t\t====================== ${nc}"
echo -e "${b}Distribution linux: ${nc} ${j} ${PRETTY_NAME}${nc}"
echo -e "${b}Noyau (Linux Kernel): ${nc} ${j} $(uname -r)${nc}"
echo -e "${b}Interpreteur de commande (chemin): ${nc} ${j} $(echo "$SHELL")${nc}"

##Recuperation des informations coté materielle et fabricant grace aux fichiers dans /sys/class/dmi/id
file=/sys/class/dmi/id
echo -e "\n\n${r}\t\t\t======================\n\t\t\t\tHARDWARE INFORMATION\n\t\t\t====================== ${nc}"
if [[ -d $file ]];then
  if [[ -r "$file/sys_vendor" ]];then
    model=$(cat $file/sys_vendor)
  elif [[ -r "$file/board_vendor" ]];then
	model=$(cat $file/board_vendor)
  elif [[ -r "$file/chassis_vendor" ]];then
	model=$(cat $file/chassis_vendor)
  fi
  
  if [[ -r "$file/product_name" ]];then
	model+="$(cat $file/product_name)"
  fi
  if [[ -r "$file/product_version" ]];then
	model+="$(cat $file/product_version)"
  fi
elif [[ -r /sys/firmware/devicetree/base/model ]];then
  model=$(cat /sys/firmware/devicetree/base/model)
fi
if [[ -n $model ]];then
  echo -e "${b}Modele du machine: ${nc} ${j}$model${nc}"
fi
  
