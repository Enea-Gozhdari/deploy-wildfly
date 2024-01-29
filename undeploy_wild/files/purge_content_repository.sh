#!/bin/bash

CONTROLLER_CONNECT="/opt/wildfly/bin/jboss-cli.sh --connect --controller="$1":9990"
WILD_VER="$(ls -lrt /opt/wildfly | awk -F '>' '{print $2}'| sed 's/ //')"
WILD92=wildfly-9.0.2.Final
WILD91=wildfly-9.0.1.Final
WILD90=wildfly-9.0.0.Final

if type -p java; then
	echo found java executable in PATH
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
	echo found java executable in JAVA_HOME
else
    echo "no java for user $USER"
    export JAVA_HOME=/opt/java
    export PATH=$JAVA_HOME/bin:$PATH
fi

if [ "$WILD_VER" == "$WILD92" ] || [ "$WILD_VER" == "$WILD91" ] || [ "$WILD_VER" == "$WILD90" ] ; then

    dep="$($CONTROLLER_CONNECT --command="/deployment=*:read-attribute(name=name)" | grep result | awk -F '"' '{ print $4}' | sed 1d)"

    for i in $dep 
    do 
    NOT_ADD="$($CONTROLLER_CONNECT --command="deployment-info --name="$i"" | egrep -i "(added|enabled)" | grep -v "not added" | wc -l)"
    echo ""$i" è uguale come NOT_ADD=$NOT_ADD" 
    if [ "$NOT_ADD" == 0 ] ; then
        $CONTROLLER_CONNECT --command="undeploy $i"
        echo "undeploy performed "$i""
    else
        echo ""$i" is associated with a cluster"
    fi
    done
else
    $CONTROLLER_CONNECT --command='deployment list -l' | grep -v NAME | awk '{print $1}' | grep war | while read dep
    do
    NOT_ADD="$($CONTROLLER_CONNECT --command="deployment info $dep" | egrep -i "(added|enabled)" | grep -v "not added" | wc -l)"
    if [ "$NOT_ADD" == 0 ] ; then
        $CONTROLLER_CONNECT --command="undeploy $dep"
        echo "undeploy performed $dep"
    else
    echo "$dep is associated with a cluster"
    fi
    done
fi

