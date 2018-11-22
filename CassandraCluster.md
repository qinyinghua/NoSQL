# CMPE281 - Personal NoSql Project - Mongo Cluster Sharding

Back to the project main report: 

https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/README.md

## Part II - Cassandra Cluster Experiements and Results

Select CP NoSQL Databsase Cassandra cluster as AWS EC2 Instnaces. 

Deployment archiecture diagram

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/Cassandra-Ring.jpg)

### 1. Setup an EC2 Cassandra Instance and Generate an AMI based on it

Instanciate an EC2 instance with Ubuntu OS. Install Cassandra on Ubuntu 18.04.

Reference: https://dzone.com/articles/install-cassandra-on-ubuntu-1804

Here is the setup step:
- Create one template EC2 instance. 
- We will use this instance to make an image for the clustering 4 Cassandra nodes. 
- This will make our four nodes with same setting. It will be convenient for trouble shooting.
- At the end, we will create a Cassandra cluster with name "casCluster".

1 - Install pre-requisites

    add-apt-repository ppa:webupd8team/java
    sudo apt update
    sudo apt-get install oracle-java8-installer
    sudo apt install python

2 - Download Cassandra

    # wget http://apache.claz.org/cassandra/3.11.3/apache-cassandra-3.11.3-bin.tar.gz
    # tar -xzvf apache-cassandra-3.11.3-bin.tar.gz 
    # mv apache-cassandra-3.11.3 /usr/local/cassandra

3 - Creating a Cassandra User

    #  useradd cassandra
    #  groupadd cassandra
    #  usermod -aG cassandra cassandra
    #  chown root:cassandra -R /usr/local/cassandra/
    #  chmod g+w -R /usr/local/cassandra/

4 - Start cassandra:

    # su - cassandra
    $ /usr/local/cassandra/bin/cassandra -f

5 - Use another user in putty to check whether cassandra is ok

    /usr/local/cassandra/bin/cqlsh localhost
    ubuntu@ip-10-0-2-33:/usr/local/cassandra/bin$ /usr/local/cassandra/bin/cqlsh localhost

    	Connected to Test Cluster at localhost:9042.
    	[cqlsh 5.0.1 | Cassandra 3.11.3 | CQL spec 3.4.4 | Native protocol v4]
    	Use HELP for help.
    	cqlsh>
    	cqlsh> select cluster_name, listen_address from system.local;
    	
    	 cluster_name | listen_address
    	--------------+----------------
    	 Test Cluster |      127.0.0.1
	
    	(1 rows)
    	cqlsh>

6 -  Run as service:
     
     sudo vi /etc/systemd/system/cassandra.service
    
			[Unit]
			Description=Cassandra Database Service
			After=network-online.target
			Requires=network-online.target
			[Service]
			User=cassandra
			Group=cassandra
			ExecStart=/usr/local/cassandra/bin/cassandra -f
			[Install]
			WantedBy=multi-user.target	

    # sudo systemctl daemon-reload
    # sudo systemctl start cassandra.service
    # sudo systemctl enable cassandra.service 
	
7 - Test run as service

    Stop the previous started by command line, ctrl_C will kill the progress in the window.
    
    /usr/local/cassandra/bin$ /usr/local/cassandra/bin/cqlsh localhost
    

8 - Rename the Cluster
    
    cqlsh>
    UPDATE system.local SET cluster_name = 'casCluster' WHERE KEY = 'local';

    sudo vi /usr/local/cassandra/conf/cassandra.yaml
    
    change the "Test Cluster" -->   casCluster   

    /usr/local/cassandra/bin$./nodetool flush system
    sudo systemctl start cassandra.service

    /usr/local/cassandra/bin$ /usr/local/cassandra/bin/cqlsh localhost
    or:
    /usr/local/cassandra/bin$ ./cqlsh -u cassandra -p cassandra

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/00_ec2_imageInstance.gif)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/0_cassandra_first_run.jpg)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/1_cassandra_test_running_ok.jpg)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/4_cassandra_renameCluster_good.gif)


### 2. Form a Cassandra Cluster

Following below article to setup EC2 Cassandra cluster (4 EC2 instances used in the cluster): 
https://linode.com/docs/databases/cassandra/set-up-a-cassandra-node-cluster-on-ubuntu-and-centos/

Steps:
- Creat an EC2 image using the template EC2 Cassandra instance
- Create 4 EC2 instances with the image. 
- The 4 EC2 instances will be used as our Cassandra Cluster.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_ec2_Allinstances.gif)

We need to
- update the cassandra.yaml for each node.
- remove the original data in the template.
- restart each node. 

1 - Update the cassandra.yaml for each node
    sudo systemctl stop cassandra.service
    sudo vi /usr/local/cassandra/conf/cassandra.yaml
    				cluster_name: 'casCluster'
    				authenticator: PasswordAuthenticator (optional)
    				seeds: ¡°node_private_ip_address¡±                      10.0.2.163,10.0.2.44,10.0.2.47,10.0.2.217
    				listen_address:<node_private_ip_address>
    				rpc_address: 0.0.0.0
    				broadcast_rpc_address:<node_private_ip_address>
    				endpoint_snitch: Ec2Snitch
    
    sudo rm -rf /usr/local/cassandra/data/data/system/*
    sudo rm -rf /var/lib/cassandra/data/system/* (not this one)
    sudo systemctl start cassandra.service

2 - Update other nodes: copy the cmpe281.pem to public node
    
    chmod 400 ~/cmpe281.pem
    
    ssh -i "cmpe281.pem" ubuntu@10.0.2.44
    ssh -i "cmpe281.pem" ubuntu@10.0.2.47
    ssh -i "cmpe281.pem" ubuntu@10.0.2.217

3 - Open port in ec2 secrity group

Reference: https://docs.datastax.com/en/cassandra/3.0/cassandra/configuration/secureFireWall.html

    7000	Cassandra inter-node cluster communication.
    7001	Cassandra SSL inter-node cluster communication.
    7199	Cassandra JMX monitoring port.
    9042	Cassandra client port.
    9160	Cassandra client port (Thrift).
    9142	Default for native_transport_port_ssl, useful when both encrypted and unencrypted connections are required

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_createEC2_cluster_openningPort.gif)

Here is the working clustering 4 Cassandra nodes.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/7_createEC2_cluster_nodes_found_work.gif)


### 4.  Test Cassandra Cluster with / without Network Partition

Experiments / Test Cases for Cassandra

- How does the system function during normal mode (i.e. no partition)
- What happens to the nodes during a partition? 
- Can stale data be read from a node during a partition?
- What happens to the system during partition recovery?

Results
- Run the Experiments and Record results.
   
#### Test Case #1: Test the data insert / query without network partition happen 
   
    Create Table and Insert Data to Cassandra

    sudo systemctl start cassandra.service
    
    cd /usr/local/cassandra/bin 
    
    ./cqlsh -u cassandra -p cassandra
    
    //Create keyspace cmpe281
    
    DESCRIBE keyspaces;

    CREATE KEYSPACE cmpe281
      WITH REPLICATION = { 
       'class' : 'SimpleStrategy', 
       'replication_factor' : 1 
      };
  
    Use cmpe281;

Run the CQL script to create tables at Cassandra node #1:  

https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/scripts/bios-schema-cassandra.SQL

Run the CQL script to insert data at Cassandra node #1: 

https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/scripts/bios-data-cassandra.SQL

Result: 
- When there is no network partition, the data insert from 1 node is consistantly rechived from all the 4 nodes in the Cassandra cluster.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/no-partition-all-good.png)

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/descNamespaceCMPE281.png)

#### Test Case #2: Test the data insert / query with network partition happen 

  Go to the Cassandra node #1. 
  Create a network partition at node #1 - Using below command line to have iptable drop all incoming message. 
      sudo iptables-save > $HOME/firewall.txt
      sudo iptables -A INPUT -s 10.0.2.0/24 -j DROP  

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/partition-points.png)

  Check the node ring status
   
    bin/nodetool status
    bin/nodetool -h 127.0.0.1 getendpoints cmpe281 person 1
    bin/nodetool -h 127.0.0.1 getendpoints cmpe281 person 2
    ... ... 
    bin/nodetool -h 127.0.0.1 getendpoints cmpe281 person 7

Find out an sample data at the node 1 which can't be connected to due to network partition.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/data-at-node1.png)
  
  Go to the jumbox node.  Open 4 ssh consoles, each of them connects to a node in Cassandra cluster service remotely through /cqlsh command.  
  
    sudo systemctl start cassandra.service
    
    cd /usr/local/cassandra/bin 
    
    # Connect to a node in Cassandra cluster service remotely through /cqlsh command. 
    
    ./cqlsh 10.0.2.163 -u cassandra -p cassandra
    ./cqlsh 10.0.2.44 -u cassandra -p cassandra
    ./cqlsh 10.0.2.47 -u cassandra -p cassandra
    ./cqlsh 10.0.2.217 -u cassandra -p cassandra
    
  On one console, update the data.    

    Use cmpe281;

    UPDATE person 
    SET first_name = 'Person1_Updated'
    WHERE person_id = 1;

    UPDATE person 
    SET first_name = 'Person7_Updated'
    WHERE person_id = 7;

  On all consoles, query the data.    

    select * from person where person_id =1;
    select * from person where person_id =2;
    select * from person where person_id =7;
    
Result: 
- When there is network partition, the remaining nodes are still available for insert and update. 
- However, the responses from different nodes are not consistent.  See the screen capture below. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/partion-1.png)


#### Test Case #3: Test the data insert / query after fixed/recovered network partition 

  Go to the Cassandra node #1. 
  Recover network partition at node #1 - Using below command line to recovery the iptable. 
      sudo  iptables-restore < $HOME/firewall.txt

  Check the node ring status
   
    bin/nodetool status
  
  Go to the jumbox node.  Open 4 ssh consoles, each of them connects to a node in Cassandra cluster service remotely through /cqlsh command.  
  
    sudo systemctl start cassandra.service
    
    cd /usr/local/cassandra/bin 
    
    # Connect to a node in Cassandra cluster service remotely through /cqlsh command. 
    
    ./cqlsh 10.0.2.163 -u cassandra -p cassandra
    ./cqlsh 10.0.2.44 -u cassandra -p cassandra
    ./cqlsh 10.0.2.47 -u cassandra -p cassandra
    ./cqlsh 10.0.2.217 -u cassandra -p cassandra
    
  On all consoles, query the data to see if that is consistent.    

    use cmpe281;
    
    select * from person where person_id =1;
    select * from person where person_id =2;
    select * from person where person_id =7;
    
Result: 
- When the network partition recovered, the data from all four nodes become consistent eventually. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/partition-recovery.png)