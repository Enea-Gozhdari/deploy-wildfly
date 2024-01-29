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

    LIST="$($CONTROLLER_CONNECT --command="/deployment=*:read-attribute(name=name)" | grep result | awk -F '"' '{ print $4}' | sed 1d | tr -d 0-9 | sed 's/\-\.\.\.war//g' | sort | uniq -D | uniq)"
    for i in $LIST
    do
    LIST_DEP="$($CONTROLLER_CONNECT --command='/deployment=*:read-attribute(name=name)' | grep result | awk -F '"' '{ print $4}' | grep "$i")" 
    for dep in $LIST_DEP
    do
    DEP_ENABLE="$($CONTROLLER_CONNECT --command="deployment-info --name=$dep" | grep enabled | wc -l)" 
    if [ "$DEP_ENABLE" -eq 1 ] ; then
        VER="$(( $(echo $dep | tr -d [a-zA-Z]- | sed 's/\.//g') -1 ))"
        for i in $LIST_DEP
        do
        VER_DEP="$(echo $i | tr -d [a-zA-Z]- | sed 's/\.//g')"
        if [ "$VER_DEP" -lt "$VER" ] ;then
        $CONTROLLER_CONNECT --command="undeploy $i --all-relevant-server-groups"
        else
        echo "No undeploy"
        fi
        done  
    done
    done
else

    $CONTROLLER_CONNECT --command='deployment list -l' | grep -v NAME | awk '{print $1}' | grep war |  tr -d 0-9 | sed 's/\-\.\.\.war//g' | uniq -D | uniq | while read name
    do
    LIST_DEP="$($CONTROLLER_CONNECT --command='deployment list -l' | grep -v NAME | awk '{print $1}' | grep "$name")"
    $CONTROLLER_CONNECT --command='deployment list -l' | grep -v NAME | awk '{print $1}' | grep "$name" | while read dep
    do
    DEP_ENABLE="$($CONTROLLER_CONNECT --command="deployment info $dep" | grep enabled | wc -l)"
    if [ "$DEP_ENABLE" -eq 1 ] ; then
        VER="$(( $(echo $dep | tr -d [a-zA-Z]- | sed 's/\.//g') -1 ))"
        for i in $LIST_DEP
        do
        VER_DEP="$(echo $i | tr -d [a-zA-Z]- | sed 's/\.//g')"
        if [ "$VER_DEP" -lt "$VER" ] ;then
        $CONTROLLER_CONNECT --command="undeploy $i --all-relevant-server-groups"
        else
        echo "No undeploy"
        fi
        done
    else
        echo "war is not enable"
fi

done
done
