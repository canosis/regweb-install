#!/bin/bash

# script per instal·lar la base de dades de Regweb
# s'ha d'executar al directori on hi ha els scripts sql


SERVER="localhost"		# servidor

DATABASE_TYPE="postgresql"	# tipus de base de dades: oracle / postgresql

DATABASE_NAME="regweb"		# nom de la base de dades

# USUARI_ADMIN="postgres"	# usuari administrador de la base de dades. si
				# es deixa en blanc no s'intentarà crear la base
				# de dades i s'assumirà que s'ha creat prèviament
# PASS_ADMIN="postgres"		# contrasenya d'administrador

USUARI_BBDD="regweb"		# usuari propietari de la base de dades regweb
PASS_BBDD="regweb"		# contrasenya d'usuari de la bbdd


##############################################################################
##############################################################################
###################### No tocar res a partir d'aquí ##########################
##############################################################################
##############################################################################

paquets(){
    echo -n "### Comprovant paquets: "

    DEBS="$DEBS postgresql-client"	# debian/ubuntu
    RPMS="$RPMS unzip"	# RH/CentOS # NO ESTÀ PROVAT

    if type -t dpkg > /dev/null ; then
	echo "detectats paquets Debian"
	for d in $DEBS ; do
	    # echo "DEBUG: comprovant $d"
	    # dpkg -s "$d" > /dev/null 2>&1
	    dpkg -l "$d" | grep -q "^ii"
	    if [ "$?" != "0" ]; then
    		export DEBIAN_FRONTEND=noninteractive
    		apt-get -q -y install $d
	    fi
	done
    fi

    if type -t yum > /dev/null ; then
	echo "detectats paquets RH/CentOS"
	for r in $RPMS ; do
	    rpm -qa | grep -q $d
	    if [ "$?" != "0" ]; then
		yum install $d
	    fi
	done
    fi

}


check_conn(){
    echo -n "### comprovant connexió a la bbdd: "
    if [ "$USUARI_ADMIN" == "" ]; then
	UCHECK="$USUARI_BBDD"
	PCHECK="$PASS_BBDD"
    else
	UCKECK="$USUARI_ADMIN"
	PCHECK="$PASS_ADMIN"
    fi

    case $1 in
	oracle)
	    echo "No implementat"
	    exit 0
	;;
	postgre)
	    PGPASSWORD="$PCHECK" psql -A -t -h $SERVER -U$UCHECK -c '\list ;' | grep -m1 postgres
	    if [ "$?" != "0" ]; then
		echo "ERROR: Problemes en connectar al servidor de BBDD [$SERVER]"
		exit 1
	    fi
	;;
	*)
	    echo "ERROR: No hauria d'haver arribat aquí"
	    exit 1
        ;;
    esac

}


admin_postgres(){
    if [ "$USUARI_ADMIN" == "" ]; then
	echo ""
	echo "No s'ha especificat cap usuari administrador de la bbdd."
	echo "Haurieu d'executar aquestes comandes al servidor de postgresql:"
	echo ""
	echo "	CREATE USER \"$USUARI_BBDD\" WITH ENCRYPTED PASSWORD '$PASS_BBDD' ;"
	echo "	CREATE DATABASE \"$DATABASE_NAME\" WITH OWNER=$USUARI_BBDD;"
	echo "	GRANT ALL PRIVILEGES ON DATABASE \"$DATABASE_NAME\" TO $USUARI_BBDD;"
	echo "	GRANT ALL PRIVILEGES ON SCHEMA PUBLIC TO $USUARI_BBDD;"
	echo ""
	sleep 1
	return 0
    fi

    echo "### Creant la bbdd [regweb]"
}

postgres_scripts(){
    echo "### Executant scripts sql per a Postgresql"
    SCRIPTS_SQL="regweb3_create_schema.sql
regweb3_create_data.sql
update_from_3.0.0_to_3.0.1/regweb3_update_schema_from_3.0.0_to-3.0.1.sql
update_from_3.0.1_to_3.0.2/regweb3_update_schema_from_3.0.1_to-3.0.2.sql
update_from_3.0.2_to_3.0.3/regweb3_update_schema_from_3.0.2_to-3.0.3.sql
update_from_3.0.5_to_3.0.6/regweb3_update_schema_from_3.0.5_to-3.0.6.sql
update_from_3.0.6_to_3.0.7/regweb3_update_schema_from_3.0.6_to-3.0.7.sql
update_from_3.0.7_to_3.0.8/regweb3_update_schema_from_3.0.7_to-3.0.8.sql
update_from_3.0.8_to_3.0.9/regweb3_update_schema_from_3.0.8_to-3.0.9.sql
update_from_3.0.8_to_3.0.9/regweb3_update_data_from_3.0.8_to-3.0.9.sql"

    for s in $SCRIPTS_SQL ; do
	if [ ! -e "$s" ]; then
	    echo "ERROR: No s'ha trobat l'script sql [$s]"
	    echo "Assegura't que et trobes al directori on hi ha els scripts i que la versió que vols instal·lar és la correcta"
	    exit 1
	fi
	echo ""
	echo "#### Executant [$s]"
	# PGPASSWORD="$PASS_BBDD" psql -q -A -t -h $SERVER -U$USUARI_BBDD < "$s"
	# PGPASSWORD="$PASS_BBDD" psql -A -t -h $SERVER -U$USUARI_BBDD < "$s"
	cat "$s" | tr -d '\r' | PGPASSWORD="$PASS_BBDD" psql -q -A -t -h $SERVER -U$USUARI_BBDD
	# echo "DEBUG: `date` - Polsa enter per continuar" ; read a

    done
}


echo "`date` - $0"
case $DATABASE_TYPE in
    oracle|o)
	echo "No implementat"
	exit 0
    ;;
    postgre|postgresql|p)
	paquets
	admin_postgres
	check_conn postgre
	postgres_scripts
    ;;
    *)
	echo "ERROR: Has d'especificar un tipus de base de dades. Valors possibles: oracle / postgresql"
	echo "Edita aquest propi script i modifica els valors"
    ;;
esac
