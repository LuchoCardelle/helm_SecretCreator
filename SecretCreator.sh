#!/bin/bash
set -e
DIRWRK="WhiteStack"


###########################################################
#	--HELP

# Función para mostrar ayuda
show_help() {
  echo "Uso: helm SecretCreator"
  echo
  echo "Opciones:"
  echo "  --help        Muestra esta ayuda"
  echo "  --version     Muestra la versión del plugin"
  echo
  # Añade aquí más opciones según sea necesario
}

# Comprobar si se ha pasado el argumento --help
if [[ "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Comprobar si se ha pasado el argumento --version
if [[ "$1" == "--version" ]]; then
  echo "SecretCreator versión 0.1.0"
  echo
  exit 0
fi

###########################################################
#	START

basecode() {
  openssl rand -base64 10 
}

validate() {
  min_length=8
  if [[ $(echo $COUNT) -lt $min_length ]]; then
    echo "a. Longitud mínima del password: 8 caracteres. [chequear] $NAME"
    exit 1
  fi

  if ! [[ $KEY =~ [A-Z] ]]; then
    echo "b. Al menos una letra en mayúscula. [chequear] $NAME"
    exit 1
  fi

  if ! [[ $KEY =~ [a-z] ]]; then
    echo "c. Al menos una letra en minúscula. [chequear] $NAME"
    exit 1
  fi

  if ! [[ $KEY =~ [0-9] ]]; then
    echo "d. Al menos un dígito. [chequear] $NAME"
    exit 1
  fi

  if ! [[ $KEY =~ [\@\#\$\%\^\&\*\(\)\_\+\-\=\{\}\[\]\|\:\;\"\'\<\>\,\.\?\/] ]]; then
    echo "e. Al menos un caracter especial. [chequear] $NAME"
    echo "opcoines : [\@\#\$\%\^\&\*\(\)\_\+\-\=\{\}\[\]\|\:\;\"\'\<\>\,\.\?\/]"
    exit 1
  fi
}



#######################################################
#  string de usuario y contraseña en base64 con openSSL
#######################################################

VAR1="generatedSecretkey1	$(basecode)"
VAR2="generatedSecretValue1	$(basecode)"

secrets_regex() {
echo "
$VAR1
$VAR2
"
}

  secrets_regex | egrep -v '^$|^#' | while IFS=$'\t' read -r LINE; do
  NAME=$(echo $LINE | awk '{print $1}' )
  KEY=$(echo $LINE | awk '{print $2}' | sed 's/ //g')
  COUNT=$(echo $KEY | sed 's/ //g' | wc -m)
  #####################################
  #  validacion de usuario y contraseña
  #####################################
  echo "exec validacion  :  $NAME $KEY $COUNT"
  validate $NAME $KEY $COUNT
  done

#######################################################
#  funcion de ejecucion para la creacion de las secrets
#######################################################
create_secret() {
  STRINGKEY=$( echo $VAR1 | awk '{print $1"="$2}' )
  STRINGVALUE=$( echo $VAR2 | awk '{print $1"="$2}' )
  kubectl create secret generic generatedsecretkey1 --dry-run=client\
  --from-literal="$STRINGVALUE" \
  --from-literal="$STRINGKEY" \
  --namespace whitestack \
  -o yaml > $DIRWRK/secret.yaml
  echo "Secret created and saved to $DIRWORK/secret.yaml"
  echo "Copy this file to your chart/template directory before deploy the chart."
}

#####################################
#  creacion de la secret
#####################################
	RC=$(echo $?)
	if [ $RC -eq "0" ]; then
	  echo " creacion de las secrets desde string openSSL base64"
	  echo " $VAR1  ---- $VAR2 "
	  create_secret 
	  echo " $STRINGKEY  ---- $STRINGVALUE "
	fi

###########
# END OF PR

#########################################################################
#  chequeo existencia de informacion sensible en el archivo 'values.yaml'
#########################################################################
	grep -E 'passwords|pwd|pass|credentials' $DIRWRK/values.yaml 
	RC=$(echo $?)
	if [ $RC -eq "0" ]; then 
		echo "a"
	fi
