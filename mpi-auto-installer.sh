read -p "How many nodes would you like to connect?: " number_of_nodes


while [ -z $number_of_nodes ]
do
    
    echo "Error cannot be empty"
    read -p "How many nodes would you like to connect?: " number_of_nodes
    
done

local_ip=$( ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )

cluster_ips=()
cluster_names=()

# This loop collects the names and IPs of all the computers in the system

for ((i=1; i<=$number_of_nodes; i++))
do
    # The first iteration must be the head node or localhost
    if [ $i -eq 1 ]; then
        
        read -p "Enter the IP of your head node[$local_ip]: " head_ip
        
        if [ -z "$head_ip" ]; then
            # echo "$head_ip is empty, setting to default [$local_ip]"
            
            if [ -z $local_ip ]; then
                
                while [ -z $local_ip ]
                do
                    echo "Error cannot be empty"
                    read -p "Enter the IP of your head node: " local_ip
                done
            else
                
                head_ip=$local_ip
                
            fi
            
            head_ip=$local_ip
            
        fi
        
        cluster_ips+=($head_ip)
        cluster_names+=($HOSTNAME)
        
    fi
    # The next iterations must be the nodes that will connect to the localhost
    read -p "Enter the IP of your slave node number $i: " slave_ip
    
    while [ -z "$slave_ip" ];
    do
        echo "Error cannot be empty"
        read -p "Enter the IP of your slave node number $i: " slave_ip
    done
    
    ping -c1 $slave_ip 1>/dev/null 2>/dev/null
    SUCCESS=$?
    
    while [ $SUCCESS -ne 0 ]
    do
        
        ping -c1 $slave_ip 1>/dev/null 2>/dev/null
        SUCCESS=$?
        
        echo "ping from $IP was not successful, please try again"
        read -p "Enter the IP of your slave node number $i: " slave_ip
        
        
    done
    
    echo "ping from $slave_ip successful"
    
    
    
    read -p "Enter the identification that will be associated to your node: " slave_name
    
    while [ -z "$slave_name" ];
    do
        
        echo "Error cannot be empty"
        read -p "Enter the identification that will be associated to your node: " slave_name
        
    done
    
    cluster_ips+=($slave_ip)
    cluster_names+=($slave_name)
    
done


#EOF