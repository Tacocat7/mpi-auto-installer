# MPI Auto Installer
An automatic cluster software configuration script for Linux

This program is a simple bash script which sets up the basic configuration for a HPC cluster. The final state of your system after the configuration of this script should be a barebones computing cluster. Subsequent cluster software such as SLURM or any other workload manager is installed on top of this configuration.

This program installs openMPI by default, but will be expanded to other distributions in the future.

This program is experimental, and is thought to only work in LAN networks.

### The program is currently in active development and not finished!

Version 2 of the script takes in certain user input such as node names and IPs to write to the system's ```/etc/hosts``` 
file. The script backs up the old file, **but deletes the file in the backup folder at the program start!**  The current 
script also generates a config file at ```/etc/mpi-config.conf``` where it is then updated dynamically while the user
inputs their system information. 

# To run:

```bash
sudo ./mpi-installer-v2.sh
```

or 

```bash
sudo bash mpi-installer-v2.sh
```

Alternatively, you can install the program through a .deb package
with 

```bash
sudo apt install ./slaveinstaller_0.3-1_all.deb
```
and running the application with

```bash
sudo slave-installer-v3.sh 
```



Running the script with -d parameter regenerates the config file and displays the edited files the program creates
Running the script with -r parameter only regenerates the config file



# To-do List:

1. Finish the script
2. Escape all the characters and secure the config file
3. Interface with a Java GUI library
4. ~~Fix comma glitch during serialization~~
5. Edit the tab length when picking options for profile name
6. Make the program POSIX friendly
7. Make a parity check sysytem for NFS filesystem
8. Fix /hosts file not being backed up when they restart the installer
9. Add elapsed time for sending node data
