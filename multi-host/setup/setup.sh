#!/usr/bin/bash

#set -x
hosts=./hosts
BCK_IFS=$IFS
IFS="
"

call() {
    local name=$1
    shift
    local cmd=""

    while (("$#")); do
        cmd="$cmd $1"
        shift
    done

    ssh -t centos@$name "$cmd" 2> /dev/null

}

template() {
    NAME=$1
    IN=$2
    OUT=$3
    sed 's/$NAME/'$NAME'/g' $IN > $OUT
}


MASTER=""
NODES=""
for entry in $(more $hosts)
do
    ip=$(echo $entry | awk '{print $1}')
    name=$(echo $entry | awk '{print $2}')


    if grep -q $name /etc/hosts; then
        sudo sed -i "s/.*$name/$ip $name/" /etc/hosts
    else
        echo "Adding $name"
        sudo bash -c 'echo "'$ip' '$name'" >> /etc/hosts'
    fi

    scp $hosts centos@$ip:~/hosts
    call $ip sudo mv hosts /etc/hosts 
        
    if [ "${name##*-}" == "master" ]; then
        echo "master: $name"
        MASTER=$name
        call $name mkdir kubernetes etcd
        scp -r master/kubernetes master/etcd centos@$name:.
        call $name "sudo mv kubernetes/* /etc/kubernetes/; sudo mv etcd/* /etc/etcd/; rmdir etcd kubernetes"
        call $name "`cat master/run.sh`"
    else
        echo "minion: $name"
        call $name mkdir kubernetes
        scp -r minion/kubernetes centos@$name:.
        template $name minion/kubernetes/kubelet $name-kubelet
        scp $name-kubelet centos@$name:kubernetes/kubelet
        call $name "sudo rm -f /etc/kubernetes/*; sudo mv kubernetes/* /etc/kubernetes/; rmdir kubernetes"
        call $name "`cat minion/run.sh`"
        template $name master/node.js $name.js
        NODES="$NODES $name.js"
    fi
done

IFS=$BCK_IFS

for node in $(echo $NODES)
do
    echo $node
    scp $node centos@$MASTER:.
    call $MASTER "kubectl delete -f $node"
    call $MASTER "kubectl create -f $node"
done


