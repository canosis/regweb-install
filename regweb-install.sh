#!/bin/bash

# script per instal·lar/desplegar REGWEB de manera desatesa
#
# no és necessari editar res d'aquest fitxer. en executar-se
# comprova si existeix un fitxer de configuració i el crea
# si no el troba.
#
# els fitxers de propietats se crean FORA del directori base
# i no es modifiquen si ja exiteixen.
#
# si establim la variable PAUSE a qualsevol valor diferent
# de 0 (zero), l'script anirà aturant després de cada passa
#
# àngel "mussol" bosch - 2018
#

VER="0.1"

# cream un log amb la sortida de tot l'script (dona problemes amb
# els retorns de carro en cas d'esperar entrada per STDIN)
# DATA=`date +%d-%m-%Y-%H%M%S` && FLOG="${0##*/}" && FLOG="${FLOG%.*}"
# exec > >(tee -i "${FLOG}-${DATA}.log")
# exec 2>&1 | tee "${FLOG}-${DATA}.log"

echo "`date` - $0 - v$VER"

# directori actual
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# comprovam que s'estigui executant com a root"
USCRIPT=`id -run`

if [ "$USCRIPT" != "root" ]; then
    echo "ERROR: aquest script està pensat per ser executat com a root."
    echo "Haureu de modificar els valors per defecte del fitxer de configuració"
    echo "perquè no apuntin a directoris on no teniu permís d'escriptura."
    echo -n "Si estau segurs de voler continuar escriviu OK: "
    read OK
    if [ "$OK" == "ok" ] || [ "$OK" == "OK" ]; then
	echo "Continuant amb usuari [$USCRIPT]..."
    else
	echo "Sortint..."
	exit 1
    fi
fi


# petita funció d'error"
check_err(){
if [ "$1" == "0" ]; then
    E="OK"
    # echo "OK"
else
    echo "S'ha produït un error"
    exit 1
fi
}

# funció de pausa
if [ "$PAUSE" == "" ]; then
    PAUSE="0"
fi

pause(){
if [ "$PAUSE" != "0" ]; then
    echo "Polsa intro per continuar..."
    read ENJOANPETITQUANBALLABALLABALLABALLA
fi
}

# crea una plantilla de configuració amb valors per defecte
f_template(){
    FTEMPLATE="$1"
    echo "### Creant la plantilla [$FTEMPLATE]"
    ( cat << 'EOF'

####
#### VARIABLES GENERALS
####

# entitat (normalment el nom de l'ajuntament/entitat)
ENTITAT="ticmallorca"
# directori arrel de tota la instal·lació
DIR_BASE="/opt/regweb-$ENTITAT"
# usuari amb el que s'executarà el servei
USUARI="regweb"
# nom de la instància
INSTANCIA="$ENTITAT"
# nom del servidor. pot esser també una IP, però hauria d'esser
# el FQDN que se resol públicament
SERVIDOR="regwebpre01.test.com"
# SERVIDOR="172.26.67.167"

####
#### PROPIETATS REGWEB
####

# Propietat que indica als projectes que activin les caracteristiques
# especials requerides en l'entorn de la CAIB (Govern Balear) si val true
REGWEB_ISCAIB="false"

# webservice del servei SIR
SIR_URL="http://localhost:8380/services"

# ruta de magatzem de fitxers
REGWEB_RUTA_FITXERS="/opt/regweb-fitxers/"


####
#### Autenticació
####

# 2.3.3.- Autenticació i Autorització per Usuaris Persona
# aquests són els usuaris d'administració i gestió del
# sistema, no els usuaris de la pròpia aplicació regweb

# sistema d'autenticació. pot ser bbdd o ldap. en cas de
# utilitzar ldap s'utilitzaran les dades del plugin userinfo
AUTH_PERSONA="bbdd"

AUTH_PERSONA_DS_URL="jdbc:postgresql://localhost:5432/seycon"
AUTH_PERSONA_DS_DRIVER="org.postgresql.Driver"
AUTH_PERSONA_DS_USER="seycon"
AUTH_PERSONA_DS_PASS="seycon"

# ds per la bbdd regweb d'usuaris d'aplicació
DS_REGWEB_URL="jdbc:postgresql://localhost:5432/regweb"
DS_REGWEB_DRIVER="org.postgresql.Driver"
DS_REGWEB_USER="regweb"
DS_REGWEB_PASS="regweb"


####
#### Dir3Caib
####

DIR3_TIMESTAMP="true"
DIR3_WS_USER="regwebCAIB"
DIR3_WS_PASS="password"

DIR3_RUTA_FITXERS="/opt/dir3caib_fitxers/"	# millor que acabi en barra [/]

# dialecte hibernate. possibles valors:
# org.hibernate.dialect.PostgreSQLDialect org.hibernate.dialect.MySQLDialect org.hibernate.dialect.DB2Dialect
# org.hibernate.dialect.SQLServerDialect net.sf.hibernate.dialect.Oracle9Dialect org.hibernate.dialect.Oracle10gDialect
HIB_DIALECT="org.hibernate.dialect.PostgreSQLDialect"

DS_DIR3_URL="jdbc:postgresql://localhost:5432/dir3caib"
DS_DIR3_DRIVER="org.postgresql.Driver"
DS_DIR3_USER="dir3caib"
DS_DIR3_PASS="dir3caib"

####
#### PAQUETS
####

# directori general dels paquets
DIR_PAQUETS="/opt/paquets"

# ruta del paquet java i nom del directori que se crea quan se descoprimeix
PAQUET_JAVA_JDK="${DIR_PAQUETS}/jdk-6u45-linux-x64.bin"
PAQUET_JAVA_MD5="40c1a87563c5c6a90a0ed6994615befe"
DIR_JAVA_JDK="jdk1.6.0_45"
HTTP_PAQUET_JAVA_JDK="http://attic-distfiles.pld-linux.org/distfiles/by-md5/4/0/40c1a87563c5c6a90a0ed6994615befe/jdk-6u45-linux-x64.bin" # OPCIONAL: URL des d'on baixar el paquet

# ruta del paquet JBoss i nom del directori que se crea quan se descoprimeix
PAQUET_JBOSS="${DIR_PAQUETS}/jboss-5.1.0.GA.zip"
DIR_JBOSS="jboss-5.1.0.GA"
HTTP_PAQUET_JBOSS="https://downloads.sourceforge.net/project/jboss/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA.zip" 	# OPCIONAL: URL des d'on baixar el paquet

# biblioteques extra
# ORACLE_JAR="${DIR_PAQUETS}/ojdbc14-10.2.0.3.0.jar"	# comentar o deixar en blanc si no se fa servir
# HTTP_ORACLE_JAR="http://central.maven.org/maven2/com/oracle/ojdbc14/10.2.0.3.0/ojdbc14-10.2.0.3.0.jar" 	# OPCIONAL: URL des d'on baixar el paquet
POSTGRESQL_JAR="${DIR_PAQUETS}/postgresql-9.3-1102-jdbc3.jar"	# comentar o deixar en blanc si no se fa servir
HTTP_POSTGRESQL_JAR="http://central.maven.org/maven2/org/postgresql/postgresql/9.3-1102-jdbc3/postgresql-9.3-1102-jdbc3.jar" # OPCIONAL: URL des d'on baixar el paquet

# biblioteca jboss-metadata.jar
PAQUET_METADATA="${DIR_PAQUETS}/jboss-metadata.jar"
HTTP_PAQUET_METADATA="https://repository.jboss.org/nexus/content/repositories/root_repository/jboss/metadata/1.0.6.GA-brew/lib/jboss-metadata.jar"

# biblioteca CXF
PAQUET_CXF="${DIR_PAQUETS}/jbossws-cxf-3.4.0.GA.zip"
HTTP_PAQUET_CXF="http://download.jboss.org/jbossws/jbossws-cxf-3.4.0.GA.zip"

# altres fitxers
SCRIPT_INICI="/etc/init.d/jboss-regweb-${ENTITAT}"

# ears
EAR_REGWEB="${DIR_PAQUETS}/regweb3.ear"
EAR_REGWEB_ZIP="${DIR_PAQUETS}/release-regweb3-3.0.9.zip"
HTTP_EAR_REGWEB="https://github.com/GovernIB/registre/releases/download/registre-3.0.9/release-regweb3-3.0.9.zip"

EAR_DIR3CAIB="${DIR_PAQUETS}/dir3caib.ear"
EAR_DIR3CAIB_ZIP="${DIR_PAQUETS}/release-dir3caib-1.0.7.zip"
HTTP_EAR_DIR3CAIB="https://github.com/GovernIB/dir3caib/releases/download/dir3caib-1.0.7/release-dir3caib-1.0.7.zip"

EOF
	) >> "$FTEMPLATE"

    pause
}


# fitxer de configuració d'aquest mateix script
# cercam el fitxer de propietats al mateix directori on hi ha el script
# i si no existeix el cream
f_conf(){
    F="$(basename $0)"
    FCONF="${CDIR}/${F%.*}.conf"
    # echo "### comprovant fitxer de configuració [$FCONF]"
    if [ ! -e "$FCONF" ]; then
	echo "No s'ha trobat el fitxer de configuració"
	f_template "$FCONF"
	exit 1
    fi

    # llegim el fitxer de configuració
    . "$FCONF"

    # comprovam que existeixin les variables necessàries al fitxer conf
    # en cas contrari probablement tenim un conf antic.
    CONVARS="ENTITAT DIR_BASE USUARI INSTANCIA SERVIDOR
DIR_PAQUETS
PAQUET_JAVA_JDK DIR_JAVA_JDK HTTP_PAQUET_JAVA_JDK PAQUET_JAVA_MD5
PAQUET_JBOSS DIR_JBOSS HTTP_PAQUET_JBOSS
ORACLE_JAR HTTP_ORACLE_JAR POSTGRESQL_JAR HTTP_POSTGRESQL_JAR 
PAQUET_METADATA HTTP_PAQUET_METADATA PAQUET_CXF HTTP_PAQUET_CXF
SCRIPT_INICI EAR_REGWEB EAR_REGWEB_ZIP HTTP_EAR_REGWEB
REGWEB_ISCAIB SIR_URL REGWEB_RUTA_FITXERS
AUTH_PERSONA AUTH_PERSONA_DS_URL AUTH_PERSONA_DS_DRIVER AUTH_PERSONA_DS_USER AUTH_PERSONA_DS_PASS
DS_REGWEB_URL DS_REGWEB_DRIVER DS_REGWEB_USER DS_REGWEB_PASS
DIR3_TIMESTAMP DIR3_WS_USER DIR3_WS_PASS HIB_DIALECT DIR3_RUTA_FITXERS
DS_DIR3_URL DS_DIR3_DRIVER DS_DIR3_USER DS_DIR3_PASS
EAR_DIR3CAIB EAR_DIR3CAIB_ZIP HTTP_EAR_DIR3CAIB
"

    for c in $CONVARS ; do
	# echo "DEBUG: comprovant [$c]"
	grep -q "${c}=" "$FCONF"
	if [ "$?" != "0" ]; then
	    echo "ERROR: No s'ha trobat l'atribut [$c] a la configuració."
	    echo "Probablement el fitxer [$FCONF] s'ha creat amb una versió antiga de l'script."
	    echo "Utilitzeu la plantilla següent per comprovar els canvis."
	    f_template "${FCONF}.template"
	    exit 1
	fi
    done

    # comprovam que s'hagi configurat mínimament
    if [ "$ENTITAT" == "" ]; then
	echo "ERROR: configuració errònia. Revisa el fitxer [$FCONF]"
	exit 1
    fi

    pause
}


# comprovacions vàries
precheck(){
echo -n "### comprovacions de sistema: "
if ! id $USUARI > /dev/null ; then
    echo "ERROR: No s'ha trobat l'usuari $USUARI"
    echo "Comproveu la configuració al fitxer [$FCONF]"
    exit 1
fi

# eines de sistema
if ! type -t wget > /dev/null ; then
    # echo "ERROR: aquest script necessita wget per funcionar"
    # echo "per favor instal·la wget amb les eines de sistema"
    # exit 1
    DEBS="$DEBS wget"
    RPMS="$RPMS wget"
fi


# per la versió 5.1 de JBoss se necessiten uns paquets
# de sistema

# debian/ubuntu
# DEBS="$DEBS libxtst6 libxi6 ant unzip"
DEBS="$DEBS ant unzip"
if type -t dpkg > /dev/null ; then
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

# redhat/centos
RPMS="$RPMS ant"
## NO ESTÀ PROVAT!!!
if type -t yum > /dev/null ; then
    rpm -qa | grep -q libxtst6
    if [ "$?" != "0" ]; then
	yum install libXext.i686
    fi
fi

echo "OK"
pause
}
# precheck


paquets(){
# comprovam si existeix el directori base
if [ -e "$DIR_BASE" ]; then
    echo "ATENCIÓ:	El directori [$DIR_BASE] ja existeix"
    echo "		Elimineu el directori o configurau-ne un altre al"
    echo "		fitxer [$FCONF]"
    exit 1
fi

# dir base
echo -n "### directori base: "
mkdir -vp "$DIR_BASE"
check_err "$?"
cd "$DIR_BASE"

# dir paquets
mkdir -vp "${DIR_PAQUETS}"
check_err "$?"

# java jdk
echo -n "### instal·lant java: "
if [ ! -e "$PAQUET_JAVA_JDK" ]; then
    if [ "$HTTP_PAQUET_JAVA_JDK" == "" ]; then
	echo "ERROR: No s'ha trobat el paquet [$PAQUET_JAVA_JDK]"
	exit 1
    else
	echo "### baixant el paquet des de [$HTTP_PAQUET_JAVA_JDK]"
	# oracle és molt torracollons per baixar directament coses
	# wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64.bin
	wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -nv -O "$PAQUET_JAVA_JDK" "$HTTP_PAQUET_JAVA_JDK"
	check_err "$?"
    fi
fi

# comprovam que el paquet sigui correcte (oracle fa coses rares
# amb els paquets de java)
MD5CHECK=`md5sum "$PAQUET_JAVA_JDK" | cut -d" " -f1`
# echo "DEBUG: MD5CHECK [$MD5CHECK] PAQUET_JAVA_MD5 [$PAQUET_JAVA_MD5]"
if [ "$MD5CHECK" != "$PAQUET_JAVA_MD5" ]; then
    echo "ERROR: Ha fallat la comprovació md5 del paquet [$PAQUET_JAVA_JDK]"
    exit 1
fi

chmod +x "$PAQUET_JAVA_JDK"
# echo "yes" | "$PAQUET_JAVA_JDK" #>/dev/null
"$PAQUET_JAVA_JDK" > /dev/null
check_err "$?"
# ln -vs "${DIR_BASE}/${DIR_JAVA_JDK}" "${DIR_BASE}/java"
ln -vs "${DIR_JAVA_JDK}" "java"


# jboss
echo -n "### instal·lant JBoss: "
if [ ! -e "$PAQUET_JBOSS" ]; then
    if [ "$HTTP_PAQUET_JBOSS" == "" ]; then
	echo "ERROR: No s'ha trobat el paquet [$PAQUET_JBOSS]"
	exit 1
    else
	echo "### baixant el paquet des de [$HTTP_PAQUET_JBOSS]"
	wget --no-check-certificate --no-cookies -nv -O "$PAQUET_JBOSS" "$HTTP_PAQUET_JBOSS"
	check_err "$?"
    fi
fi

unzip -q "${PAQUET_JBOSS}"
# tar -xzf "${PAQUET_JBOSS}"
check_err "$?"
ln -vs "${DIR_JBOSS}" "jboss"

# donam execució a run.sh
chmod +x "${DIR_BASE}/jboss/bin/run.sh"

# canviam l'index.html per defecte (això no és cap mesura de seguretat
# tan sols és per simplificar l'accés a l'aplicació)
mv "${DIR_BASE}/jboss/server/default/deploy/ROOT.war/index.html" "${DIR_BASE}/jboss/server/default/deploy/ROOT.war/index.html.orig"
echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Regweb</title>
<META HTTP-EQUIV="Refresh" CONTENT="1; URL=/regweb3/">

  </head>
  <body>

    <p style="text-align:center">Regweb</p>

</body>
</html>
' > "${DIR_BASE}/jboss/server/default/deploy/ROOT.war/index.html"

# feim propietari a l'usuari especificat
chown -R "$USUARI" "$DIR_BASE"

pause
}



script_inici(){
# script inici
if [ -e "$SCRIPT_INICI" ]; then
    echo "ERROR: Ja existeix un script d'inici per a l'entitat [$ENTITAT]"
    echo "	$SCRIPT_INICI"
    exit 0
fi

echo -n "### creant script d'inici [$SCRIPT_INICI]: "
(
cat << 'EOF'
#!/bin/bash
#
# JBoss Control Script
#
# chkconfig: 3 80 20
# description: JBoss EJB Container
# 
# To use this script
# run it as root - it will switch to the specified user
# It loses all console output - use the log.
#
# Here is a little (and extremely primitive) 
# startup/shutdown script for RedHat systems. It assumes 
# that JBoss lives in /usr/local/jboss, it's run by user 
# 'jboss' and JDK binaries are in /usr/local/jdk/bin. All 
# this can be changed in the script itself. 
# Bojan 
#
# Either amend this script for your requirements
# or just ensure that the following variables are set correctly 
# before calling the script

# [ #420297 ] JBoss startup/shutdown for RedHat

export DISPLAY=:0.0
export JAVA_OPTS="-Djava.awt.headless=true -Xoss128m -Xms512m -Xmx1024m -XX:MaxPermSize=256m"

#define where jboss is - this is the directory containing directories log, bin, conf etc
JBOSS_HOME="/opt/jboss"
JAVA_HOME="/opt/java"

#make java is on your path
JAVAPTH="$JAVA_HOME/bin"

# Variables nostres
# instancia
JBOSSCONF="default"

# usuari
JBOSSUS="root"

# ip des de la que escolta
JBOSSHOST=${JBOSSHOST:-"0.0.0.0"}

# Adreça multicast per defecte de jboss(no està suportat a la versió 3.2.8)
#JBOSSMC=${JBOSSMC:-"228.1.2.3"}
# JBOSSMC=${JBOSSMC:-"228.1.2.50"}

#Partició de Cluster
#JBOSSPART=${JBOSSPART:-"PartProduccio"}

#define the classpath for the shutdown class
JBOSSCP=${JBOSSCP:-"$JBOSS_HOME/bin/shutdown.jar:$JBOSS_HOME/client/jnet.jar"}

#define the script to use to start jboss
#JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSSCONF -b $JBOSSHOST -u $JBOSSMC -g $JBOSSPART"}
# JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSSCONF -b $JBOSSHOST -u $JBOSSMC"}
JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSSCONF -b $JBOSSHOST"}

if [ -n "$JBOSS_CONSOLE" -a ! -d "$JBOSS_CONSOLE" ]; then
  # ensure the file exists
  touch $JBOSS_CONSOLE
fi
 
if [ -n "$JBOSS_CONSOLE" -a ! -f "$JBOSS_CONSOLE" ]; then
  echo "WARNING: location for saving console log invalid: $JBOSS_CONSOLE"
  echo "WARNING: ignoring it and using /dev/null"
  JBOSS_CONSOLE="/dev/null"
fi

#define what will be done with the console log
JBOSS_CONSOLE=${JBOSS_CONSOLE:-"/dev/null"}

if [ -z "`echo $PATH | grep $JAVAPTH`" ]; then
  export PATH=$PATH:$JAVAPTH
fi

#define the user under which jboss will run, or use RUNASIS to run as the current user
#JBOSSUS=${JBOSSUS:-"jboss"}
JBOSSUS=${JBOSSUS:-"RUNASIS"}

CMD_START="PATH=\"$PATH\" ; cd $JBOSS_HOME/bin; $JBOSSSH" 
CMD_STOP="java -classpath $JBOSSCP org.jboss.Shutdown --shutdown -s $JBOSSHOST"

if [ "$JBOSSUS" = "RUNASIS" ] || [ "$JBOSSUS" = "root" ]; then
  SUBIT=""
else
  SUBIT="su - $JBOSSUS -c "
fi

if [ ! -d "$JBOSS_HOME" ]; then
  echo JBOSS_HOME does not exist as a valid directory : $JBOSS_HOME
  exit 1
fi

jstatus(){
    [ "$JBOSSUS" == "RUNASIS" ] && JBOSSUS="root"
    JPID=`pgrep -u $JBOSSUS -f "java.*$JBOSSCONF"`
    if [ -z "$JPID" ]; then
	echo "La instancia $JBOSSCONF de JBoss no s'esta executant"
	return 1
    else
	echo "JBoss executant-se amb usuari [$JBOSSUS] i PID: $JPID"
    fi
    export JPID
}

stop_wait(){
    STOP_PROC="$1"
    WAIT_COUNT="30"
    echo -n "stopping process $STOP_PROC: "
    while [ $WAIT_COUNT != "0" ]; do
	kill $STOP_PROC 2> /dev/null
	pgrep -f "java.*$JBOSSCONF" > /dev/null
	if [ "$?" != "0" ]; then
    	    break
	else
    	    echo -n "."
    	    sleep 1
	fi
    done
    echo " OK"
}

case "$1" in
start)
    jstatus && exit 2
    echo -n "Iniciant instancia ${JBOSSCONF}: "
    echo CMD_START = $CMD_START

    cd $JBOSS_HOME/bin
    if [ -z "$SUBIT" ]; then
        eval $CMD_START >${JBOSS_CONSOLE} 2>&1 &
    else
        $SUBIT "$CMD_START >${JBOSS_CONSOLE} 2>&1 &" 
    # $SUBIT "$CMD_START &" 
    fi
    sleep 5
    jstatus
    ;;
stop)
    jstatus || exit 3
    echo "Aturant instancia $JBOSSCONF"
    stop_wait $JPID
    ;;
restart)
    $0 stop
    $0 start
    ;;
status)
    jstatus
    ;;
*)
    echo "usage: $0 (start|stop|restart|status|help)"
esac

EOF
) >> "$SCRIPT_INICI"

sed -i "s;^JBOSS_HOME=.*;JBOSS_HOME=\"${DIR_BASE}/jboss\";" "$SCRIPT_INICI"
sed -i "s;^JAVA_HOME=.*;JAVA_HOME=\"${DIR_BASE}/java\";" "$SCRIPT_INICI"
sed -i "s;^JBOSSCONF=.*;JBOSSCONF=\"${INSTANCIA}\";" "$SCRIPT_INICI"
sed -i "s;^JBOSSUS=.*;JBOSSUS=\"${USUARI}\";" "$SCRIPT_INICI"

chmod 755 "$SCRIPT_INICI"
echo "OK"
pause
}
# script_inici


lib_extras(){



echo -n "### configurant CXF [$PAQUET_CXF]: "
# necessitam la variable del home de java per executar ant
export JAVA_HOME="${DIR_BASE}/java"
if [ ! -e "$PAQUET_CXF" ]; then
	if [ "$HTTP_PAQUET_CXF" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$PAQUET_CXF]"
	    exit 1
	else
	    echo "### baixant el paquet des de [$HTTP_PAQUET_CXF]"
	    wget --no-check-certificate --no-cookies -nv -O "$PAQUET_CXF" "$HTTP_PAQUET_CXF"
	    check_err "$?"
	fi
fi


# generam un fitxer temporal i descomprimim el cxf
DCXFTEMP=`mktemp -d`
cd "$DCXFTEMP"
unzip -q "$PAQUET_CXF"
cd jbossws-cxf-bin-dist/

echo "jboss510.home=${DIR_BASE}/jboss
jbossws.integration.target=jboss510
jboss.server.instance=default
jboss.bind.address=localhost
javac.debug=no
javac.deprecation=no
javac.fail.onerror=yes
javac.verbose=no" > ant.properties
ant -q deploy-jboss510 > /dev/null 2>&1
rm -rf "$DCXFTEMP"
cd "$DIR_BASE"
echo "OK"


# biblioteques commons d'apache.
# ATENCIÓ!!! AIXÒ HA D'ANAR DESPRÉS DE LA COMPILACIÓ CXF!!!
echo -n "### copiant biblioteca metadata [$PAQUET_METADATA]: "
if [ ! -e "$PAQUET_METADATA" ]; then
	if [ "$HTTP_PAQUET_METADATA" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$PAQUET_METADATA]"
	    exit 1
	else
	    echo "### baixant el paquet des de [$HTTP_PAQUET_METADATA]"
	    wget --no-check-certificate --no-cookies -nv -O "$PAQUET_METADATA" "$HTTP_PAQUET_METADATA"
	    check_err "$?"
	fi
fi
cp -f "$PAQUET_METADATA" "${DIR_BASE}/jboss/common/lib/"
cp -f "$PAQUET_METADATA" "${DIR_BASE}/jboss/client/"
echo "OK"



# 2.3.1.- Fitxer JDBC d'accés a BBDD

# ORACLE: si la variable està definida asumim que se vol utilitzar
if [ "$ORACLE_JAR" != "" ]; then
    echo -n "### copiant biblioteca de bbdd d'oracle: "
    if [ ! -e "$ORACLE_JAR" ]; then
	if [ "$HTTP_ORACLE_JAR" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$ORACLE_JAR]"
	    exit 1
	else
	    echo "### baixant el paquet des de [$HTTP_ORACLE_JAR]"
	    wget --no-check-certificate --no-cookies -nv -O "$ORACLE_JAR" "$HTTP_ORACLE_JAR"
	    check_err "$?"
	fi
    fi
    cp -vf "$ORACLE_JAR" "${DIR_BASE}/jboss/common/lib/"
fi

# POSTGRESQL: si la variable està definida asumim que se vol utilitzar
if [ "$POSTGRESQL_JAR" != "" ]; then
    echo -n "### copiant biblioteca de postgresql: "
    if [ ! -e "$POSTGRESQL_JAR" ]; then
	if [ "$HTTP_POSTGRESQL_JAR" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$POSTGRESQL_JAR]"
	    exit 1
	else
	    echo "### baixant el paquet des de [$HTTP_POSTGRESQL_JAR]"
	    wget --no-check-certificate --no-cookies -nv -O "$POSTGRESQL_JAR" "$HTTP_POSTGRESQL_JAR"
	    check_err "$?"
	fi
    fi
    cp -f "$POSTGRESQL_JAR" "${DIR_BASE}/jboss/common/lib/"
    echo "OK"
fi

pause
}


instancia(){
# ATENCIÓ: és convenient deixar la creació de la instància pel després 
# de la configuració del CXF i altres biblioteques ja que se sobreescriuen
# configurant instància
echo -n "### configurant instància $INSTANCIA [${DIR_BASE}/jboss/server/${INSTANCIA}]: "
case $INSTANCIA in
    all|default|minimal|standard)
	echo "OK"
    ;;
    *)
	cp -pr "${DIR_BASE}/jboss/server/default" "${DIR_BASE}/jboss/server/${INSTANCIA}"
	echo "OK"
	chown -R "$USUARI" "${DIR_BASE}/jboss/server/${INSTANCIA}"
    ;;
esac

pause
}



conf_jboss(){
# configuracions dins del jboss


# opcions vàries de java dins el jboss
echo -n "### configurant opcions de java: "
echo 'export DISPLAY=":0.0"' >> "${DIR_BASE}/jboss/bin/run.conf"
JAVA_PATH="${DIR_BASE}/java/bin/java"
echo "JAVA=\"$JAVA_PATH\"" >> "${DIR_BASE}/jboss/bin/run.conf"
echo "OK"



echo -n "### configurant directori de desplegament: "
F_DESPLEGAMENT="${DIR_BASE}/jboss/server/${INSTANCIA}/conf/bootstrap/profile.xml"
grep -q deployregweb "$F_DESPLEGAMENT"
if [ "$?" != "0" ]; then
    sed -i 's;url}deploy</value>;url}deploy</value>\n\t\t\t\t<value>${jboss.server.home.url}deployregweb</value>;' "$F_DESPLEGAMENT"
    mkdir "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb"
fi
echo "OK"


# 2.2.4.- Transaccions damunt múltiples recursos
echo -n "### configurant consultes sobre múltiples datasources: "
F_TSPROP="${DIR_BASE}/jboss/server/${INSTANCIA}/conf/jbossts-properties.xml"
grep -q com.arjuna.ats.jta.allowMultipleLastResources "$F_TSPROP"
if [ "$?" != "0" ]; then
    sed -i 's;arjuna" name="jta">;arjuna" name="jta">\n\t<property name="com.arjuna.ats.jta.allowMultipleLastResources" value="true" />;' "$F_TSPROP"
fi
echo "OK"


# 2.2.5.- Autenticador WSBASIC
echo -n "### configurant Autenticador WSBASIC: "
F_WSBASIC="${DIR_BASE}/jboss/server/${INSTANCIA}/deployers/jbossweb.deployer/META-INF/war-deployers-jboss-beans.xml"
grep -q '<key>WSBASIC</key>' "$F_WSBASIC"
if [ "$?" != "0" ]; then

    sed -i 's;<key>BASIC</key>;\t<key>WSBASIC</key>\n\t\t<value>org.apache.catalina.authenticator.BasicAuthenticator</value>\n\t</entry>\n\t<entry>\n\t\t<key>BASIC</key>;' "$F_WSBASIC"

fi
echo "OK"

# 2.2.6.- Augmentar número de Paràmetres
echo -n "### augmentant número de paràmetres: "
F_PROPSSERVICE="${DIR_BASE}/jboss/server/${INSTANCIA}/deploy/properties-service.xml"
# grep 'jboss:type=Service,name=SystemProperties">' "$F_PROPSSERVICE"
grep 'org.apache.tomcat.util.http.Parameters.MAX_COUNT=1000' "$F_PROPSSERVICE"
if [ "$?" != "0" ]; then
    sed -i 's;jboss:type=Service,name=SystemProperties">;jboss:type=Service,name=SystemProperties">\n\n\t<attribute name="Properties">\n\t\torg.apache.tomcat.util.http.Parameters.MAX_COUNT=1000\n\t</attribute>\n;' "$F_PROPSSERVICE"
fi
echo "OK"

pause
}



conf_properties(){

# 2.3.2.- Fitxer de Propietats
echo -n "### creant fitxer de propietats: "

F_PROPS="${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/regweb3-properties-service.xml"
( cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <mbean code="org.jboss.varia.property.SystemPropertiesService" name="jboss:type=Service,name=RegwebSystemProperties">
        <attribute name="Properties">

            <!-- General -->
            es.caib.regweb3.defaultlanguage=ca
            es.caib.regweb3.showtimestamp=false

            <!-- Caib -->
            es.caib.regweb3.iscaib=$REGWEB_ISCAIB

            <!-- Url de WS SIR - http://localhost:8380/services -->
            es.caib.regweb3.sir.serverbase=$SIR_URL

            <!-- Directorio base para los archivos generales -->
            es.caib.regweb3.archivos.path=$REGWEB_RUTA_FITXERS

        </attribute>
    </mbean>
</server>
EOF

) > "$F_PROPS"
echo "OK"

# directori del magatzem de fitxers
if [ ! -e "$REGWEB_RUTA_FITXERS" ]; then
    echo -n "### creant directori de magatzem de fitxers [$REGWEB_RUTA_FITXERS]: "
    mkdir -p "$REGWEB_RUTA_FITXERS"
    echo "OK"
fi

pause
}



conf_auth(){

# comprovam que s'hagi configurat ja el login-config.xml
grep -q '<application-policy name = "seycon">' "${DIR_BASE}/jboss/server/${INSTANCIA}/conf/login-config.xml"
if [ "$?" == "0" ]; then
    echo "### ja s'ha configurat login-config.xml "
else

case $AUTH_PERSONA in
    bbdd)
	echo -n "### Comprovant accés a la bbdd d'usuaris persona: "
	# rols regweb: RWE_SUPERADMIN, RWE_ADMIN, RWE_USER
	CHECK_URI=`echo "${AUTH_PERSONA_DS_URL//jdbc:/}"`
	PGUSER="$AUTH_PERSONA_DS_USER"
	PGPASSWORD="$AUTH_PERSONA_DS_PASS"
	# el psql necessita les variables exportades explícitament
	export PGUSER PGPASSWORD
	# psql -d "$CHECK_URI" -A -t -c "select count(*) from sc_wl_usuari"
	psql -d "$CHECK_URI" -A -t -c "select * from sc_wl_usugru where ugr_codgru='RWE_SUPERADMIN'" | grep -m1 RWE_SUPERADMIN
	if [ "$?" != "0" ]; then
	    echo ""
	    echo "ERROR: problemes en connectar a la BBDD amb la URI [$AUTH_PERSONA_DS_URL]"
	    echo "Comprovau que podeu connetar a la base de dades i que els usuaris i rols necessaris estan creats."
	    echo "Estau segurs que voleu continuar? s/n: "
	    read BBDDOK
	    if [ "$BBDDOK" == "s" ] || [ "$OK" == "S" ]; then
		echo "Continuant sense comprovació de la bbdd..."
	    else
		echo "Comprova la connexió a la bbdd i torna a executar l'script"
	        echo "Sortint..."
		exit 1
    	    fi
	fi

	echo -n "### Creant DS per autenticació Persona: "
	# 2.3.5.- Autenticació i Autorització per Usuaris Persona

	( cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<datasources>
  <local-tx-datasource>
    <jndi-name>es.caib.seycon.db.wl</jndi-name>
    <connection-url>$AUTH_PERSONA_DS_URL</connection-url>
    <driver-class>$AUTH_PERSONA_DS_DRIVER</driver-class>
    <user-name>$AUTH_PERSONA_DS_USER</user-name>
    <password>$AUTH_PERSONA_DS_PASS</password>
  </local-tx-datasource>
</datasources>
EOF
	) > "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/seycon-ds.xml"

	echo "OK"
	echo -n "### modificant login-config.xml per autenticació Persona amb BBDD: "

	# sed -i "s;^JBOSS_HOME=.*;JBOSS_HOME=\"${DIR_BASE}/jboss\";" "$SCRIPT_INICI"

	POLTEXT="    <!-- Directori BBDD per usuaris Persona -->

    <application-policy name = \"seycon\">
	<authentication>
	<!-- 2.3.3.- Autenticació i Autorització per Usuaris Persona -->
	    <login-module code=\"org.jboss.security.auth.spi.DatabaseServerLoginModule\" flag=\"sufficient\">
		<module-option name=\"dsJndiName\">java:/es.caib.seycon.db.wl</module-option>
		<module-option name=\"principalsQuery\">
		    select USU_PASS from SC_WL_USUARI where USU_CODI = ?
		</module-option>
		<module-option name=\"rolesQuery\">
		    select UGR_CODGRU,'Roles' from SC_WL_USUGRU where UGR_CODUSU = ?
		</module-option>
	    </login-module>

"

    ;;
    ldap)
	echo -n "### modificant login-config.xml per autenticació Persona amb LDAP: "
	# utilitzam les mateixes dades que pel plugin de userinfo
	POLTEXT="<!-- Directori LDAP per usuaris Persona -->

    <application-policy name = \"seycon\">
	<authentication>
         <login-module code=\"org.fundaciobit.plugins.loginmodule.ldap.LdapLoginModule\" flag=\"sufficient\" >
	    <module-option name=\"ldap.host_url\">$PLUGIN_USERINFOLDAP_HOST</module-option>
	    <module-option name=\"ldap.security_principal\">$PLUGIN_USERINFOLDAP_PRINCIPAL</module-option>
	    <module-option name=\"ldap.security_credentials\">$PLUGIN_USERINFOLDAP_CREDENTIALS</module-option>
	    <module-option name=\"ldap.security_authentication\">simple</module-option>
	    <module-option name=\"ldap.users_context_dn\">$PLUGIN_USERINFOLDAP_USERSDN</module-option>
	    <module-option name=\"ldap.search_scope\">subtree</module-option>
	    <module-option name=\"ldap.search_filter\">$PLUGIN_USERINFOLDAP_FILTER</module-option>
	    <module-option name=\"ldap.prefix_role_match_memberof\">$PLUGIN_USERINFOLDAP_PREFIX_MEMBEROF</module-option>
	    <module-option name=\"ldap.suffix_role_match_memberof\">$PLUGIN_USERINFOLDAP_SUFIX_MEMBEROF</module-option>
	    <module-option name=\"ldap.attribute.username\">$PLUGIN_USERINFOLDAP_ATTR_USERNAME</module-option>
	    <module-option name=\"ldap.attribute.mail\">mail</module-option>
	    <module-option name=\"ldap.attribute.administration_id\">employeeNumber</module-option>
	    <module-option name=\"ldap.attribute.name\">$PLUGIN_USERINFOLDAP_ATTR_NAME</module-option>
	    <module-option name=\"ldap.attribute.surname\">$PLUGIN_USERINFOLDAP_ATTR_SURNAME</module-option>
	    <module-option name=\"ldap.attribute.telephone\">telephoneNumber</module-option>
	    <module-option name=\"ldap.attribute.memberof\">$PLUGIN_USERINFOLDAP_ATTR_MEMBEROF</module-option>
	    <module-option name=\"ldap.attribute.surname1\">$PLUGIN_USERINFOLDAP_ATTR_SURNAME</module-option>
	    <module-option name=\"ldap.attribute.surname2\">$PLUGIN_USERINFOLDAP_ATTR_SURNAME</module-option>
	  </login-module>

"
    ;;
    *)
	# no hauria d'arribar mai aquí
	echo "ERROR: no s'ha configurat correctament"
	exit 1
    ;;
esac

POLTEXT="$POLTEXT

	</authentication>
    </application-policy>
</policy>"

# POLTEXT=`echo "$POLTEXT" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\\n/g'`
POLTEXT=`echo "$POLTEXT" | sed 's/$/\\\n/' | tr -d '\n'`

sed -i "s;</policy>;$POLTEXT;" "${DIR_BASE}/jboss/server/${INSTANCIA}/conf/login-config.xml"

echo "OK"

fi

}



conf_ds(){

echo -n "### Comprovant accés a la bbdd: "
CHECK_URI=`echo "${DS_REGWEB_URL//jdbc:/}"`
PGUSER="$DS_REGWEB_USER"
PGPASSWORD="$DS_REGWEB_PASS"
# el psql necessita les variables exportades explícitament
export PGUSER PGPASSWORD
# psql -d "$CHECK_URI" -A -t -c "select count(*) from pfi_role"
# psql -d "$CHECK_URI" -A -t -c "select * from rwe_rol" | grep -m1 RWE_SUPERADMIN
psql -d "$CHECK_URI" -A -t -c "select * from rwe_rol where nombre='RWE_ADMIN'" | grep -m1 RWE_ADMIN
if [ "$?" != "0" ]; then
    echo ""
    echo "ERROR: problemes en connectar a la BBDD amb la URI [${DS_REGWEB_URL}]"
    echo "Comprovau que podeu connetar a la base de dades i que els usuaris i rols necessaris estan creats."
    echo "Estau segurs que voleu continuar? s/n: "
    read BBDDOK
    if [ "$BBDDOK" == "s" ] || [ "$OK" == "S" ]; then
	echo "Continuant sense comprovació de la bbdd..."
    else
	echo "Comprova la connexió a la bbdd i torna a executar l'script"
	echo "Sortint..."
	exit 1
    fi
fi

echo -n "### Creant DS regweb per usuaris de la aplicació: "

# 2.5.- DataSources
( cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<datasources>
  <local-tx-datasource>
    <jndi-name>es.caib.regweb3.db</jndi-name>

    <connection-url>$DS_REGWEB_URL</connection-url>
    <driver-class>$DS_REGWEB_DRIVER</driver-class>
    <user-name>$DS_REGWEB_USER</user-name>
    <password>$DS_REGWEB_PASS</password>

  </local-tx-datasource>
</datasources>
EOF
) > "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/regweb-ds.xml"

echo "OK"

pause

}

conf_plugins(){
echo "### configuracions de plugins "


pause
}

inst_dir3(){
echo "### instal·lant dir3caib"
echo -n "### DIR3CAIB - creant fitxer de propietats dir3caib-properties-service.xml: "

F_PROPSDIR3="${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/dir3caib-properties-service.xml"
( cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <mbean code="org.jboss.varia.property.SystemPropertiesService" name="jboss:type=Service,name=Dir3caibSystemProperties">
        <attribute name="Properties">
	    <!-- Propietat que indica als projectes que activins les caracteristiques
                 especials requerides en l'entorn de la CAIB (Govern Balear) si es true -->

	    <!-- Lenguaje por defecto de la aplicación -->
	    es.caib.dir3caib.defaultlanguage=ca
	    <!-- Indicamos si estamos en un entorno CAIB -->
	    es.caib.dir3caib.iscaib=$REGWEB_ISCAIB
	    <!-- Indicamos si se quiere modo desarrollo. Funcionalidades extra -->
            es.caib.dir3caib.development=false
	    <!-- Se indica si se quiere que se muestre la hora en el pie de página de la aplicación -->
            es.caib.dir3caib.showtimestamp=$DIR3_TIMESTAMP

	    <!-- Configuración del Dialecto de la BBDD -->
	    es.caib.dir3caib.hibernate.dialect=$HIB_DIALECT
	    es.caib.dir3caib.hibernate.query.substitutions=true 1, false 0

	    <!-- Directorio base para los archivos generales
                 Directorio donde se guardan los archivos CSV descargados del los WS de dir3 de Madrid-->
            es.caib.dir3caib.archivos.path=$DIR3_RUTA_FITXERS


	    <!-- Autentificación para los dir3ws (Directorio Común en Madrid) es necesario estar dentro de la REDSARA -->
            <!--endpoints de ws-->
            es.caib.dir3caib.catalogo.endpoint=http://pre-dir3ws.redsara.es/directorio/services/SC21CT_VolcadoCatalogos
            es.caib.dir3caib.unidad.endpoint=http://pre-dir3ws.redsara.es/directorio/services/SD01UN_DescargaUnidades
            es.caib.dir3caib.oficina.endpoint=http://pre-dir3ws.redsara.es/directorio/services/SD02OF_DescargaOficinas

	    <!-- Usuario y Password de los dir3ws -->
	    es.caib.dir3caib.dir3ws.user=$DIR3_WS_USER
            es.caib.dir3caib.dir3ws.pass=$DIR3_WS_PASS

	    <!-- Expresión Cron de la Hora a la que se debe realizar la Sincronización DIR3. El ejemplo corresponde a una sincronización a las 3:00 de la madrugada -->
	    es.caib.dir3caib.cronExpression=0 0 3 1/1 * ? *

	    <!--Valores por defecto para el formulario de la búsqueda de Unidades y Oficinas-->
	    es.caib.dir3caib.busqueda.administracion=2
	    es.caib.dir3caib.busqueda.comunidad=4

        </attribute>
    </mbean>
</server>
EOF

) > "$F_PROPSDIR3"
echo "OK"


case $AUTH_PERSONA in
    bbdd)
	echo -n "### DIR3CAIB - Comprovant accés a la bbdd d'usuaris persona: "
	CHECK_URI=`echo "${AUTH_PERSONA_DS_URL//jdbc:/}"`
	PGUSER="$AUTH_PERSONA_DS_USER"
	PGPASSWORD="$AUTH_PERSONA_DS_PASS"
	# el psql necessita les variables exportades explícitament
	export PGUSER PGPASSWORD
	# psql -d "$CHECK_URI" -A -t -c "select count(*) from sc_wl_usuari"
	psql -d "$CHECK_URI" -A -t -c "select * from sc_wl_usugru where ugr_codgru='DIR_ADMIN'" | grep -m1 DIR_ADMIN
	if [ "$?" != "0" ]; then
	    echo ""
	    echo "ERROR: problemes en connectar a la BBDD amb la URI [$AUTH_PERSONA_DS_URL]"
	    echo "Estau segurs que voleu continuar? s/n: "
	    read BBDDOK
	    if [ "$BBDDOK" == "s" ] || [ "$OK" == "S" ]; then
		echo "Continuant sense comprovació de la bbdd..."
	    else
		echo "Comprova la connexió a la bbdd i torna a executar l'script"
	        echo "Sortint..."
		exit 1
    	    fi
	fi
    ;;
    ldap)
	echo "### Ja hauria d'estar configurat"
    ;;
    *)
	# no hauria d'arribar mai aquí
	echo "ERROR: no s'ha configurat correctament"
	exit 1
    ;;
esac

echo -n "### DIR3CAIB - creant datasource : "
( cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<datasources>
  <local-tx-datasource>
    <jndi-name>es.caib.dir3caib.db</jndi-name>

    <connection-url>$DS_DIR3_URL</connection-url>
    <driver-class>$DS_DIR3_DRIVER</driver-class>
    <user-name>$DS_DIR3_USER</user-name>
    <password>$DS_DIR3_PASS</password>

  </local-tx-datasource>
</datasources>
EOF
) > "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/dir3caib-ds.xml"
echo "OK"

if [ ! -e "$DIR3_RUTA_FITXERS" ]; then
    echo -n "### DIR3CAIB - creant directori magatzem de dir3: "
    mkdir -pv "$DIR3_RUTA_FITXERS"
fi

if [ -e "$EAR_DIR3CAIB" ]; then
    echo -n "### DIR3CAIB - copiant ear dir3caib: "
    cp -v "$EAR_DIR3CAIB" "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/"
else
    if [ ! -e "$EAR_DIR3CAIB_ZIP" ]; then
	if [ "$HTTP_EAR_DIR3CAIB" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$EAR_DIR3CAIB]"
	    exit 1
	else
	    echo "### DIR3CAIB - baixant el paquet des de [$HTTP_EAR_DIR3CAIB]"
	    wget --no-check-certificate --no-cookies -nv -O "$EAR_DIR3CAIB_ZIP" "$HTTP_EAR_DIR3CAIB"
	    check_err "$?"
	fi
    fi
    echo "### DIR3CAIB - descomprimint ear des de [$EAR_DIR3CAIB_ZIP]"
    mkdir -p "/tmp/.dir3tmpear"
    cd "/tmp/.dir3tmpear"
    unzip -joq "$EAR_DIR3CAIB_ZIP" \*.ear
    echo -n "### DIR3CAIB - moguent ear dir3caib: "
    mv -v *.ear "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/"

    cd "$CDIR"

    rmdir "/tmp/.dir3tmpear"
fi

pause
}



bin_ear(){
# baixar/copiar les ear
if [ -e "$EAR_REGWEB" ]; then
    echo -n "### copiant ear REGWEB: "
    cp -v "$EAR_REGWEB" "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/"
else
    if [ ! -e "$EAR_REGWEB_ZIP" ]; then
	if [ "$HTTP_EAR_REGWEB" == "" ]; then
	    echo "ERROR: No s'ha trobat el paquet [$EAR_REGWEB_ZIP]"
	    exit 1
	else
	    echo "### baixant el paquet des de [$HTTP_EAR_REGWEB]"
	    wget --no-check-certificate --no-cookies -nv -O "$EAR_REGWEB_ZIP" "$HTTP_EAR_REGWEB"
	    check_err "$?"
	fi
    fi
    echo "### descomprimint ear des de [$EAR_REGWEB_ZIP]"
    mkdir -p "/tmp/.regwebtmpear"
    cd "/tmp/.regwebtmpear"
    unzip -joq "$EAR_REGWEB_ZIP" \*.ear
    echo -n "### moguent ear regweb: "
    mv -v *.ear "${DIR_BASE}/jboss/server/${INSTANCIA}/deployregweb/"

    cd "$CDIR"
    rmdir "/tmp/.regwebtmpear"
fi

pause
}

custom(){
    # espai per personalitzar l'script
    VARIABLE="1"
    # configuració LDAP

    # pujam la verbositat del log de seguritat
    # sed -i 's|   <!-- Limit the org.apache category|\t<category name="org.jboss.security">\n\t\t<priority value="TRACE"/>\n\t</category>\n\n   <!-- Limit the org.apache category|' "${DIR_BASE}/jboss/server/${INSTANCIA}/conf/jboss-log4j.xml"

pause

}



help(){
    # 
    echo "Instal·lador Regweb"
    echo "Aquest instal·lador respecta els fitxers de configuració FORA del"
    echo "directori arrel del JBoss/Java. És a dir, els fitxers de propeties"
    echo "i la configuració del propi script"
    echo ""
    echo "Arguments:"
    echo "-all: executa totes les passes"
    echo "-p: instal·la els paquets de dependències"
    echo "-i: crea la instància de JBoss"
    echo "-s: crea script d'inici"
    echo "-e: instal·la les biblioteques extres"
    echo "-c: instal·la les biblioteques CAIB"
    echo "-j: configura les opcions de JBoss"
    echo "-r: crea els fitxers de properties"
    echo "-d: crea els fitxers de DataSources"
    echo "-b: instal·la els paquets ear"
    echo "-u: executa el bloc personalitzat (custom)"
    echo ""
    echo "En una instal·lació nova s'ha d'executar <-all>"
    echo "Per ex: $0 -all"
}


### MAIN
[ "$1" == "" ] && help
for i in "$@"; do
    case $i in
	-all)
	    f_conf
	    precheck
	    paquets
	    script_inici
	    lib_extras
	    # lib_caib
	    instancia
	    conf_jboss
	    conf_properties
	    conf_auth
	    conf_ds
	    # echo "DEBUG - `date` - surt" ; exit 0
	    conf_plugins
	    inst_dir3
	    bin_ear
	    custom
	    # ja no executam res més
	    echo "`date` - finalitzat"
	    exit 0
	;;
	-p)
	    f_conf
	    precheck
	    paquets
	;;
	-i)
	    f_conf
	    precheck
	    instancia
	;;
	-s)
	    f_conf
	    precheck
	    script_inici
	;;
	-e)
	    f_conf
	    precheck
	    lib_extras
	;;
	-c)
	    # a regweb no se fa servir
	    exit 1
	    f_conf
	    precheck
	    lib_caib
	;;
	-j)
	    f_conf
	    precheck
	    conf_jboss
	;;
	-r)
	    f_conf
	    precheck
	    conf_properties
	;;
	-t)
	    f_conf
	    precheck
	    conf_auth
	;;
	-d)
	    f_conf
	    precheck
	    conf_ds
	;;
	-3)
	    f_conf
	    precheck
	    inst_dir3
	;;
	-u)
	    f_conf
	    precheck
	    custom
	;;
	-b)
	    f_conf
	    precheck
	    bin_ear
	;;
	*)
	    help
	;;
    esac
done

echo "`date` - finalitzat"
exit 0

