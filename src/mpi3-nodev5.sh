#!/bin/bash

# Checks if program is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this program as root"
    exit
fi

config_file="../etc/mpi-node.conf"
master_config="../tmp/master.conf"
hosts_file="../tmp/hosts"
backup_folder="../backup/"
tmp_folder="../tmp/"
etc_folder="../etc/"
node_ip=$( ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )
cluster_names=()
cluster_ips=()


# Checks for debug arguments if the argument is -r then it only regenerates config file.
# If the argument is -d then deletes the entire program structure as if it were a fresh install
# If you would like to delete the user that the script creates for you, run with the second
# argument as the username
if [ "$1" == "-r" ] || [ "$1" == "-d" ]; then
    
    sudo rm $config_file
    
    if [ ! -z $2 ]; then
        sudo deluser --remove-home $2 > /dev/null
    fi
    
    if [ "$1" == "-d" ]; then
        
        sudo rm -r $backup_folder
        sudo rm -r $etc_folder
        sudo rm -r $tmp_folder
        
    fi
fi

# If it cannot find the config folder, it will assume that the program structure has
# not yet been created. If the etc folder has been created it clears the tmp directory
if [ ! -d $etc_folder ]; then
    
    mkdir $etc_folder
    mkdir $tmp_folder
    mkdir $backup_folder
    
else
    # Reset directories for debugging
    sudo rm -r $tmp_folder
    mkdir $tmp_folder
    #sudo rm -r $etc_folder
    #mkdir $etc_folder
    sudo rm -r $backup_folder
    mkdir $backup_folder
    
fi

# Generates an empty config file to /etc/mpi-config, if run with -r paramter it removes
# the config file and generates a new one
function generate_config() {
    
    source "../etc/master.conf"
    
    
    if [ "$1" == "-r" ]; then
        
        sudo rm $config_file
        
    fi
    
    sudo touch $config_file
    
    sudo echo "version=0.4" >> $config_file
    sudo echo "installed_dependencies=1" >> $config_file
    sudo echo "cluster_name=$cluster_name"  >> $config_file
    sudo echo "cluster_size=$cluster_size" >> $config_file
    sudo echo "master=$master" >> $config_file
    sudo echo "mpi_username=$mpi_username" >> $config_file
    sudo echo "secret=$secret" >> $config_file
    sudo echo "node_name=$HOSTNAME" >> $config_file
    sudo echo "node_names=$node_names" >> $config_file
    sudo echo "node_ip=$node_ip" >> $config_file
    sudo echo "user_created=0" >> $config_file
    sudo echo "nfs_mounted=0" >> $config_file
    sudo echo "ssh_secured=0" >> $config_file
    sudo echo "changed_fstab=0" >> $config_file
    sudo echo "changed_hosts=1" >> $config_file
    sudo echo "directory_set=1" >> $config_file
    sudo echo "default_port=$port" >> $config_file
    sudo echo "N=" >> $config_file
    sudo echo "#" >> $config_file
    
    sleep 0.5
    
    source $config_file
    
    echo -e "Empty node config file generated!"
}

# Function to write config file
function write_config(){
    sudo sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $config_file
    source "$config_file"
}


function listen(){
    
    IP=$1
    PORT=$2
    DESTINATION=$3
    
    echo $IP
    
    if [ -z $IP ]; then
        
        echo "Error no IP address specified"
        exit 1
        
        elif [ -z $PORT ]; then
        
        echo "Error no port specified"
        echo "Defaulting to port 1000"
        
        PORT=1000
        
        elif [ -z $DESTINATION ]; then
        
        echo "Error no destination address"
        exit 2
        
    fi
    
    echo "Listening on port $PORT..."
    sudo netcat -l $PORT > $DESTINATION
    echo "Done!"
    
}

function split_file(){
    
    delta_split=0
    
    
    touch $master_config
    touch $hosts_file
    
    while read -r line; do
        
        if [ "$delta_split" == "1" ]; then
            
            sudo echo "$line" >> $hosts_file
            
            elif [ "$line" != "$2" ] && [ "$delta_split" == "0" ]; then
            
            sudo echo "$line" >> $master_config
            
            elif [ "$line" == "$2" ] && [ "$delta_split" == "0" ]; then
            
            delta_split=1
            sudo echo "$line" >> $master_config
            
        fi
        
        
    done <$1
    
    if [ -f /etc/hosts ]; then
        sudo mv /etc/hosts $backup_folder
    fi
    
    sudo mv $hosts_file /etc/hosts
    sudo mv $master_config $etc_folder
    hosts_file="/etc/hosts"
    master_config="../etc/master.conf"
    
}


# Calls the config file and sources its variables
if [ -f $config_file ]; then
    echo "Config found!"
    source "$config_file"
fi

if [ -d $etc_folder ] && [ -d $backup_folder ] && [ -d $tmp_folder ]; then
    
    echo "Directory made"
    
else
    echo "Unknown error, could not create directory for program"
    exit 10
fi

# Only installs dependencies if config file says so
if [ ! -f $config_file ]; then
    echo -e "Updating apt..."
    sudo apt-get update -y >/dev/null
    
    # Checks if netcat and nfs-kernel-server is installed, if not it installs is
    if [ "$(dpkg-query -W --showformat='${Status}\n' netcat|grep "install ok installed" )" != "install ok installed" ]; then
        
        echo -e "Installing dependencies..."
        sudo apt-get install netcat -y >/dev/null
        echo "Done!"
        
        elif [ "$(dpkg-query -W --showformat='${Status}\n' nfs-common|grep "install ok installed")" != "install ok installed" ]; then
        
        echo "Installing dependencies..."
        sudo apt-get install nfs-common -y >/dev/null
        echo "Done!"
        
    fi
    
    
fi

# If the user is running the "no gui" option then skip the input
if [ "$1" != "-ng" ] && [ "$changed_hosts" != "1" ]; then
    
    clear
    echo -e "Welcome to Pleiades Node installer version 0.3! \n"
    
    read -p "Enter the IP of your Master node: " IP
    
    echo "Pinging..."
    ping -c1 $slave_ip 1>/dev/null 2>/dev/null
    SUCCESS=$?
    
    while [ $SUCCESS -eq 0 ]
    do
        
        echo "Ping from $IP was not successful, please try again"
        read -p "Enter the IP of your Master node: " IP
        
        ping -c2 $slave_ip 1>/dev/null 2>/dev/null
        SUCCESS=$?
        
    done
    
    echo -e "Ping from $IP successful! \n"
    read -p "Enter the port that the Master is transmitting on[1000]: " port
    
    if [ -z $port ]; then
        
        port=1000
        
    fi
    
fi

transfer_file="../tmp/transfer"

if [ "$1" == "-ng" ] && [ "$changed_hosts" != "1" ]; then
    
    listen $2 $3 $transfer_file
    
    elif [ "$changed_hosts" != "1" ]; then
    
    listen $IP $port $transfer_file
    
fi

while [ ! -f $transfer_file ] && [ "$changed_hosts" != "1" ]; do
    
    echo "No transmission from port $port, retrying..."
    if [ "$1" == "-ng" ]; then
        
        listen $2 $3 $transfer_file
        
    else
        
        listen $IP $port $transfer_file
        
    fi
    echo "Error no transmission"
    exit 2
    
    
done

if [ -f $transfer_file ] && [ "$changed_hosts" != "1" ]; then
    
    echo -e "\nSuccessfully copied configuration from MASTER!"
    # Splits the transferred file, and moves the new files to /etc/mpi-config-conf and /etc/hosts
    split_file $transfer_file "#"
    
    elif [ "$changed_hosts" != "1" ]; then
    
    echo "Error: No file recieved"
    
    
fi

hosts_file="/etc/hosts"
master_config="../etc/master.conf"


# Generates node config from master config
if [ ! -f "$config_file" ]; then
    echo "Generating new config file..."
    sleep 0.5
    generate_config
fi

source "$config_file"

node_names_array=(${node_names//,/ })

while [ -z $N ]; do
    
    n=0
    
    for name in ${node_names_array[@]}; do
        
        # Note $name must be exactly the same as $HOSTNAME which may be entered incorrectly on the user's part
        if [ "$name" == "$HOSTNAME" ]; then
            
            write_config N $n
            
        fi
        
        n="$((n+1))"
        
    done
    
done

# If user is not created then create it, skip otherwise
if [ "$user_created" != "1" ] && [ ! -d /home/$mpi_username ]; then
    
    sudo useradd -m "$mpi_username" -s /bin/bash -u 1500
    # Needs a password to be set!!!
    echo "$mpi_username:$secret" | sudo chpasswd
    
    write_config user_created 1
    
    elif [ "$user_created" == "1" ] && [ -d /home/$mpi_username ]; then
    
    
    write_config user_created 0
    
fi

while [ -d /home/$mpi_username ] && [ "$nfs_mounted" != "1" ]; do
    
    sudo mount $master:/home/$mpi_username /home/$mpi_username
    
    sleep 1
    
    if df -h | grep $master ; then
        
        echo "Mounted onto $master"
        write_config nfs_mounted 1
        
    fi
    
done

mpi_folder="/home/$mpi_username/.mpi"

# Results in a program lock, FIX
while [ "$N" == "1" ] && [ "$ssh_secured" != "1" ]; do
    
    sudo runuser -l $mpi_username -c "mkdir ~/.mpi"
    sudo runuser -l $mpi_username -c "ssh-keygen -N '' -f /home/$mpi_username/.ssh/id_rsa -q"
    wait
    
    sudo runuser -l $mpi_username -c "touch ~/.mpi/ssh"
    
    if [ -d "/home/$mpi_username/.mpi/ssh" ]; then
        
        read -p "Check if it worked :3"
        
    fi
    
done



read -p "End of file!"
exit