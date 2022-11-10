#!/bin/bash

# Checks if program is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this program as root"
    exit
fi

version="0.4"
config_file="../etc/mpi-node.conf"
backup_folder="../backup/"
tmp_folder="../tmp/"
etc_folder="../etc/"
head_ip=$( ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )
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
    
    sudo rm -r $tmp_folder
    mkdir $tmp_folder
    
fi

# Generates an empty config file to /etc/mpi-config, if run with -r paramter it removes
# the config file and generates a new one
function generate_config() {
    
    if [ "$1" == "-r" ]; then
        
        sudo rm $config_file
        
    fi
    
    sudo touch $config_file
    
    sudo echo "version=$version" >> $config_file
    sudo echo "setup_started=1"  >> $config_file
    sudo echo "installed_dependencies=0"  >> $config_file
    sudo echo "cluster_name=''"  >> $config_file
    sudo echo "cluster_size=" >> $config_file
    sudo echo "master=''" >> $config_file
    sudo echo "mpi_username=''" >> $config_file
    sudo echo "mpi_password=''" >> $config_file
    sudo echo "node_name=''" >> $config_file
    sudo echo "node_ip=''" >> $config_file
    sudo echo "user_created=0" >> $config_file
    sudo echo "nfs_mounted=0" >> $config_file
    sudo echo "ssh_secured=0" >> $config_file
    sudo echo "changed_fstab=0" >> $config_file
    sudo echo "changed_hosts=0" >> $config_file
    sudo echo "directory_set=0" >> $config_file
    sudo echo "default_port=1000" >> $config_file
    sudo echo "#" >> $config_file
    
    sleep 0.5
    
    source $config_file
    
    echo -e "Empty node config file generated!"
}



if [ "$(dpkg-query -W --showformat='${Status}\n' netcat|grep "install ok installed" )" != "install ok installed" ]; then
    
    echo -e "Installing dependencies..."
    sudo apt-get update -y >/dev/null
    sudo apt-get install netcat -y >/dev/null
    echo "Done!"
    
fi

# Checks if nfs-common is installed, if not it installs is
if [ "$(dpkg-query -W --showformat='${Status}\n' nfs-common|grep "install ok installed" )" != "install ok installed" ]; then
    
    echo -e "Installing dependencies..."
    sudo apt-get update -y >/dev/null
    sudo apt-get install nfs-common -y >/dev/null
    echo "Done!"
    
fi

function listen(){
    
    IP=$1
    PORT=$2
    DESTINATION=$3
    
    
    if [ -z $IP_address ]; then
        
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
    
    ping -w 2 -c 1 $2 > /dev/null
    
    SUCCESS=$?
    
    if [ "$SUCCESS" != "0" ]; then
        echo "Error: IP cannot be reached"
        exit 1
    fi
    
    
    echo "Listening on port $PORT..."
    sudo netcat -l $PORT > $DESTINATION
    echo "Done!"
    
}

function split_file(){
    delta_split=0
    touch ./backup/mpi-config.conf
    touch ./backup/hosts
    
    while read -r line; do
        
        echo $line
        
        if [ "$delta_split" == "1" ]; then
            
            sudo echo "$line" >> ./backup/hosts
            
            elif [ "$line" != "$2" ] && [ "$delta_split" == "0" ]; then
            
            sudo echo "$line" >> ./backup/mpi-config.conf
            
            elif [ "$line" == "$2" ] && [ "$delta_split" == "0" ]; then
            
            delta_split=1
            sudo echo "$line" >> ./backup/mpi-config.conf
            
        fi
        
        
    done <$1
    
    if test -f /etc/hosts; then
        sudo rm /etc/hosts
    fi
    
    sudo mv ./backup/hosts /etc/
    sudo mv ./backup/mpi-config.conf /etc/
    
}





if [ "$1" != "-ng" ]; then
    
    echo -e "Welcome to Pleiades Node installer version 0.3! \n"
    
    read -p "Enter the IP of your Master node: " IP
    
    echo "Pinging..."
    ping -c1 $slave_ip 1>/dev/null 2>/dev/null
    SUCCESS=$?
    # echo $SUCCESS
    
    while [ $SUCCESS -eq 0 ]
    do
        
        echo "Ping from $IP was not successful, please try again"
        read -p "Enter the IP of your Master node: " IP
        
        ping -c2 $slave_ip 1>/dev/null 2>/dev/null
        SUCCESS=$?
        
    done
    
    echo -e "Ping from $IP successful! \n"
    read -p "Enter the port that the Master is transmitting on[1000]: " PORT
    
    if [ -z $PORT ]; then
        
        PORT=1000
        
    fi
    
fi





transfer_file="./backup/transfer"

if test -f $transfer_file; then
    sudo rm $transfer_file
fi

if [ $1 == "-ng" ]; then
    listen $2 $3 $transfer_file
    
else
    
    listen $IP $PORT $transfer_file
    
fi

echo "Listening..."

sudo netcat -l $PORT > $transfer_file

if test -f $transfer_file; then
    
    echo -e "\nSuccessfully copied configuration from MASTER!"
    
else
    
    echo "Error: No file recieved"
    
fi

# Splits the transferred file, and moves the new files to /etc/mpi-config-conf and /etc/hosts
split_file $transfer_file "#"

# Sources the newly transferred config file. Now the head and the nodes have the same file, but
# how can we make sure they have parity throughout the execution of the scripts?
source /etc/mpi-config.conf

# Creates an array with string of node names inside the config file. Must be converted since
# the config can't have arrays for some reason.
node_names_array=(${node_names//,/ })

sudo useradd -m "$mpi_username"
# Needs a password to be set!!!

sudo mount ${node_names_array[0]}:/home/$mpi_username /home/$mpi_username

# PARITY CHECK TO BE ADDED
# Sends config file out to head node to check for parity
# echo "Transmitting parity check on port: $PORT "
# sudo netcat -w 2 ${node_names_array[0]} $PORT < "/etc/mpi-config.conf"

# Writes to the /etc/fstab file ONCE. Turned off for debugging purposes
# if [ "$(tail -1 /etc/fstab)" != "sudo mount ${node_names_array[0]}:/home/$mpi_username /home/$mpi_username" ];then
#     # Edits /etc/fstab file so the nodes mount to the head node at startup
#     echo "sudo mount ${node_names_array[0]}:/home/$mpi_username /home/$mpi_username" | sudo tee -a /etc/fstab
#
# fi



exit
#EOF