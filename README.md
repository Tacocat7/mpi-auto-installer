# MPI Auto Installer
An automatic MPI cluser setup script for Ubuntu 22.04

This program looks to implement the bash script MPI installer outlined in the Project Pleiades research proposal.

The program installs and sets up an MPI cluster with openMPI as its default distribution. This program was specifically
crafted for a small hardware cluster built from 8 outdated office computers. 

### The program is currently in active development and not finished!

Version 2 of the script takes in certain user input such as node names and IPs to write to the system's '''console/etc/hosts''' 
file. The script backs up the old file, **but deletes the file in the backup folder at the program start!**  The current 
script also generates a config file at '''console/etc/mpi-config.conf''' where it is then updated dynamically while the user
inputs their system information. 

# To run:

'''console
sudo ./mpi-installer-v2.sh
'''

or 

'''console
sudo bash mpi-installer-v3.sh
'''


# To-do List:

1. Finish the script
2. Escape all the characters and secure the config file
3. Interface witha Java GUI library


