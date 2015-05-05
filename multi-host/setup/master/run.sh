for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler; do     
    sudo systemctl restart $SERVICES;         
    sudo systemctl status $SERVICES;  
done

