##Installation:  

    cd /usr/local/bin  
    for f in soc-mpisetup shutdown-workers  
    do  
        ln -s /usr/HD/$f.bash $f  
    done  

    ln -s /usr/HD/soc-hostname .  

To build and set protection on soc-hostname:  

    sudo -u root -g hd-cluster gcc -o soc-hostname soc-hostname.c  
    sudo chmod 750 soc-hostname  
    sudo chmod u+s soc-hostname  
    bashrc represents revised default version of .bashrc
