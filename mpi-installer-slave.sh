#!/bin/bash

sudo apt-get update -y
sudo apt-get install netcat

clear

echo "Welcome to Pleiades Node installer version 0.2!"

read -p "Enter the IP of your Master node: " IP

echo "Pinging..."
ping -c1 $slave_ip 1>/dev/null 2>/dev/null
SUCCESS=$?
# echo $SUCCESS

while [ $SUCCESS -eq 0 ]
do
    
    echo "Ping from $IP was not successful, please try again"
    read -p "Enter the IP of your Master node: " IP
    
    ping -c1 $slave_ip 1>/dev/null 2>/dev/null
    SUCCESS=$?
    
done

echo "Ping from $IP successful! \n"

read -p "Enter the port that the Master is transmitting on: " PORT

echo "Listening..."

sudo netcat -l $PORT > "hosts"

if test -f ./hosts; then
echo -e "\e Success!"
fi

echo "EOF"