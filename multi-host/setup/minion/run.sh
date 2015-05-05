for SERVICES in kube-proxy kubelet docker; do
    sudo systemctl restart $SERVICES;
    systemctl status $SERVICES ;
done
