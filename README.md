# CMPE281 - Personal NoSql Project - Main

## Objective

In this project, I will be testing the Partition Tolerance of MongoDB and Cassandra NoSQL Database. 
  
MongoDB is a CP NoSQL Databases while Cassandra is a AP NoSQL Database.
  
Partition tolerance in CAP means the ability of NoSQL Database system to continue processing data - 
even if a network partition causes communication errors between subsystems. 

https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/CassandraCluster.md
https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/MongoClusterSharding.md
  
Based on the reference artical, we made following hypothesis. The experiments would be built based on this.
  
    1) When network is healthy, the CP and AP NoSQL Database both would be consistent and available.
    
    2) When "network partition" occurs, messages are dropped, CP NoSQL Database would
        -- be able to keep "consistency" / "linearizability" 
        -- not be able to keep all nodes "availability" 
        -- would reject some requests on some nodes.  
    
    3) When "network partition" occurs, messages are dropped, AP NoSQL Database would
        -- not be able to keep "consistency" / "linearizability" 
        -- different nodes can disagree about the order in which operations took place.
        -- be able to keep all nodes "availability" - can handle requests on all nodes.  
      
## Part I - Mongo Cluster with Sharding Network Partition Experiements and Results

I refer to the official document to install the MongoDB 3.6 shard clustering, [https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/](https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/).

Here is the architecture of the clustering and the relative running 10 EC2 nodes.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/docImages/MongoDeploy.png)

[[Source: Yinghua Qin Invidiaul Project at CMPE 281]]

The cluster contains 2 shards - each shard is a replica set containing 3 nodes - installed as EC2 instances.

The cluster contains 1 config server replica set which has 3 nodes - installed as EC2 instances.

The cluster contains 1 Mongo Query Router - installed as EC2 instance. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/00_10_nodes_in_mongoCluster.gif)
  

## 1. Create Mongo EC2 instances

  Image: Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-0bbe6b35405ecebdb
  
  Szie: t2.micro (Variable ECUs, 1 vCPUs, 2.5 GHz, Intel Xeon Family, 1 GiB memory, EBS only)  

  Install Mongo on EC2 Instance
  
  Select the mongodb version, officially ubuntu (the EC2 node's OS) supports Mongodb 3.6.
  
    sudo apt update
    sudo apt install mongodb
    sudo systemctl start mongodb
    sudo systemctl status mongodb
    mongod --version
				
  Install Mongo Replica Set - rs0
  
  Update the mongodb.service file to add " --replSet "rs0" --bind_ip localhost,10.0.2.118 "  
  (replace the 10.0.2.118 with the EC2 instance private IP)
  
    sudo vi /lib/systemd/system/mongodb.service
    ExecStart=/usr/bin/mongod  --replSet "rs0" --bind_ip localhost,10.0.2.118 --unixSocketPrefix=${SOCKETPATH} --config ${CONF} $DAEMON_OPTS
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb
		
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/2b_instance_mongodb_up_version.gif)		
  
## 2. Initiate the Mongo replica set

  Connect a mongo shell to one of the Mongo instances
  
  Run rs.initiate() on just one and only one mongod instance for the replica set.
  
    rs.initiate( {
     _id : "rs0",
     members: [
        { _id: 0, host: "172.31.2.172:27017" },
        { _id: 1, host: "172.31.15.178:27017" },
        { _id: 2, host: "172.31.6.88:27017" }
     ]
    })
    rs.satus()
  Set Up two Replica Sets (rs0 and rs1). Three nodes for each Replica set. 
  
  Repica set #1 - rs0 
  
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/4_mongodb_3nodes_replicaInit_status.gif)

  Repica set #2 - rs1 
  
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/11_mongodb_rs2_init_success_status.gif)

## 3.  Covert the Replica Sets into two Shards

  Step 1: Update the slave nodes

  update to add "--shardsvr" option: mongod --replSet "rs0" --shardsvr --port 27017  
                      
    sudo vi /lib/systemd/system/mongodb.service 
        ExecStart=/usr/bin/mongod --shardsvr --port 27017 --replSet "rs0" --bind_ip localhost,10.0.2.192 --unixSocketPrefix=${SOCKETPATH} --config ${CONF} $DAEMON_OPTS
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb  
                           
  Step 2:Udate the master node

    sudo vi /lib/systemd/system/mongodb.service
    
      ExecStart=/usr/bin/mongod --shardsvr --port 27017 --replSet "rs0" --bind_ip localhost,10.0.2.192 --unixSocketPrefix=${SOCKETPATH} --config ${CONF} $DAEMON_OPTS
    
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb      
                       
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/7_mongodb_shardsvr_secondary_setup.gif)

## 4.  Setup  Config Server Replica Set. It will have 3 nodes.

  Create another 3 EC2 instances as Mongo Config Server replica set.
  
  The config servers use the default data directory /data/configdb and the default port 27019.
  
    sudo apt update
    sudo apt install mongodb
    
  Modify the mongodb.servie to add "--configsvr --replSet configReplSet --port 27019 --bind_ip localhost,10.0.2.116"
  
  (replace the 10.0.2.116 with the node private IP)
  
    sudo vi /lib/systemd/system/mongodb.service 
        mongod  --configsvr --replSet configReplSet --port 27019 --bind_ip localhost,10.0.2.116 
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb 

    #Initiate the configuration replication set
    
    rs.initiate( {
        _id: "configReplSet",
        configsvr: true,
        members: [
            { _id: 0, host: "10.0.2.116:27019" },
            { _id: 1, host: "10.0.2.243:27019" },
            { _id: 2, host: "10.0.2.164:27019" }
        ]
        } )
        
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/8_mongodb_configSrv_init.gif)

## 5.  Setup a Mongo Query Router EC2 node as the console to access the DB

  Mongos for MongoDB Shard, is a routing service for MongoDB shard configurations.
  
  It processes queries from the application layer.  
  
    sudo apt update
    sudo apt install mongodb
    sudo vi /lib/systemd/system/mongodb.service 
       ExecStart=/usr/bin/mongos --port 27017 --configdb configReplSet/10.0.2.116:27019,10.0.2.243:27019,10.0.2.164:27019  --bind_ip localhost,10.0.2.234  --unixSocketPrefix=${SOCKETPATH}
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb
    
    sudo vi /lib/systemd/system/mongos.service
    
    sudo systemctl stop mongod

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/9_mongodb_queryRoute_works.gif)

## 6.  Open the required port in the EC2 security groups.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/5_mongodb_shardsvr_openPort_27018.gif)

## 7.  Form a Mongo Cluster 

  Integrate the two Replica Sets and Config Server Replica Set and Mongo Query Router into one Shard Cluster.
  
  The cluster contains 2 shards - each shard is a replica set containing 3 nodes.
  
  The cluster contains 1 config server replica set which has 3 nodes.
  
  The cluster contains 1 Mongo Query Router. 
  
    Go to the Mongo Query Router instance, run Mongo.
    
    #Add the first shard
    
    mongos> sh.addShard( "rs0/10.0.2.192:27017,10.0.2.173:27017,10.0.2.118:27017" )
    {
            "shardAdded" : "rs0",
            "ok" : 1,
            "$clusterTime" : {
                    "clusterTime" : Timestamp(1542234421, 6),
                    "signature" : {
                            "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                            "keyId" : NumberLong(0)
                    }
            },
            "operationTime" : Timestamp(1542234421, 6)
    }
    mongos>
    
    #Add the second shard

    mongos> sh.addShard( "rs1/10.0.2.237:27017,10.0.2.43:27017,10.0.2.6:27017" )
    {
            "shardAdded" : "rs1",
            "ok" : 1,
            "$clusterTime" : {
                    "clusterTime" : Timestamp(1542304817, 7),
                    "signature" : {
                            "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                            "keyId" : NumberLong(0)
                    }
            },
            "operationTime" : Timestamp(1542304817, 7)
    }
    mongos>sh.status()
  
  Here is the cluster sharding status.
  
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/12_mongodb_queryRouter_shardingStatus.gif)

## 8.  Create Data Collection in MongoDB Cluster with Sharding 

Create the bios data collection. 

Go to Mongo Query Router, run:
  
    mongo localhost:27017/admin 
    use cmpe281B
    db.createCollection("bios")
  
    >> Insert data
  
    mongo localhost:27017/cmpe281B ~/bios.js
  
    db.bios.find( { "name.first": "John" } )
  
I choose the last name as the shading key. Here is the consideration: 

- Must have values for each record
- Have values that are evenly distributed among all documents
- Group documents that are often accessed at the same time into contiguous chunks
- Effective distribution of activity among shards

When query those example data, the first name and last name are two keys having values for each record. 

"Last Name" would be the good one which have values that are evenly distributed among all documents. 

This is a hash based partitioning. Data is partitioned into chunks using a hash function. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/shardingBonus/hashKey.png)

[[Source: https://docs.mongodb.com/v3.6/core/sharding-shard-key/]]

Go to Mongo Query Router, run:

    sh.enableSharding( "cmpe281B" )
    db.bios.ensureIndex({"name.last": "hashed"})
    sh.shardCollection("cmpe281B.bios", { "name.last": "hashed"} )
    db.stats()  

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/shardingBonus/bios2_Hashindex_lastName_work.gif)

 
## 9.  Test Mongo Cluster with / without Network Partition

- How does the system function during normal mode (i.e. no partition)

    Test Case #1: Test the data insert and query without network partition happen 
    Test Case #2: Test the Mongo chararistic without network partition happen - Insert data at Master Node
    Test Case #3: Test the Mongo chararistic without network partition happen - Insert data at Slave Node 
    
- What happens to the master node during a partition? 

    Test Case #4: Test Mongo with network partition happen - drop all incoming message on master node
    - Create a network partition, drop all the incoming message on the master node
    - The master node still up and running but the slave nodes can not connect to master node
    - A new master is elected!!

- Can stale data be read from a slave node during a partition?

    Test Case #5: Test the data query during network partition - Query data from a slave node
    - Query data - no stale data could be read from a slave node  
    
- What happens to the system during partition recovery?

    Test Case #6: Test the data insert and query during network partition recovery 
    - Update and Query data from Mongos Query Router (at this time, there are 2 nodes in the shard)
    - Reovery the network partition
    - The new master is elected back to the old master
    - Query the data to see if the data is the updated version or the stale data  
   
### Test Case #1: Test the data query without network partition happen - Insert / Query data from Mongos Query Router
   
  Use the shard rs0. 
  
  Open a bash terminal, it connects to the Mongos Query Router.
  From there, using the Mongos Query Router as jump box, open bash window for 3 nodes on the shard rs0 replica set. 
  
  Insert data from Mongos Query Router, query the data from Mongos Query Router and all three nodes. 
     
     1) Insert a record . 
        use cmpe281B
        // insert bio - Bob Foo
        db.bios.insert(
        {
        "name" : {
            "first" : "Bob",
            "last" : "Foo"
        },
        "birth" : ISODate("1985-05-19T04:00:00Z"),
        "contribs" : [
            "C"
        ],
        "awards" : [
            {
                "award" : "The Economist Innovation Award",
                "year" : 2003,
                "by" : "The Economist"
            }
        ]})   

     2) Query the record at, Mongo Query Router, node #1, node #2 and node #3. 
   
        rs.slaveOk()
        use cmpe281B
        db.bios.find( { "name.first": "Bob" } )
        db.stats()  

Result: When the network is normal, data insert and data query work well. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/round2/no-partition.png)

### Test Case #2: Test the Mongo chararistic without network partition happen - Insert data at Master Node
   
  Use the shard rs0. 
  
  Open 3 bash terminals, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Insert data on one node, query the data on all three nodes. 

     1) Insert a record to the node #1 (Master / Primary). 
        use cmpe281B
        // insert bio - Tim Foo
        db.bios.insert(
        {
        "name" : {
            "first" : "Tim",
            "last" : "Foo"
        },
        "birth" : ISODate("1985-05-19T04:00:00Z"),
        "contribs" : [
            "C"
        ],
        "awards" : [
            {
                "award" : "The Economist Innovation Award",
                "year" : 2003,
                "by" : "The Economist"
            }
        ]})   

     2) Query the record at node #1, node #2 and node #3. 
   
        rs.slaveOk()
        use cmpe281B
        db.bios.find( { "name.first": "Tim" } )
        db.stats()  

Result: By design, MongoDB is a single-master system and all writes go to primary by default. 
SSH to the Master node to do insert, it works. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/good-network-insert-at-master-work.png)


### Test Case #3: Test the Mongo chararistic without network partition happen - Insert data at Slave Node
   
  Use the shard rs0 to test. 
  
  Open 3 bash terminals, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Insert data on one node, query the data on all three nodes. 
  
  Step 1: Insert a record to the node #2 (secondary/slave). 
            
      use cmpe281B
      
      // insert bio - Tim2 Foo
      
      db.bios.insert(
      {
	      "name" : {
		      "first" : "Tim2",
		      "last" : "Foo"
	      },
	      "birth" : ISODate("1985-05-19T04:00:00Z"),
	      "contribs" : [
		      "C"
	      ],
	      "awards" : [
		      {
		      "award" : "The Economist Innovation Award",
		      "year" : 2003,
		      "by" : "The Economist"
	      }
	      ]})   

  Step 2: Query the record at node #1, node #2 and node #3. 
   
      rs.slaveOk()
      
      use cmpe281B
      
      db.bios.find( { "name.first": "Tim2" } )
   
Result: By design, MongoDB is a single-master system and all writes go to primary by default. If SSH to the slave node to do insert, it won't work. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/good-network-insert-at-slave-not-work.png)

### Test Case #4: Test Mongo with network partition happen - drop all incoming message on master node - Insert / Query from Mongo Query Router
    - Create a network partition, drop all the incoming message on the master node
    - The master node still up and running but the slave nodes can not connect to master node

  Use the shard rs0. 
  
  Open a bash terminal, it connects to the Mongos Query Router.
  From there, using the Mongos Query Router as jump box, open bash window for 3 nodes on the shard rs0 replica set. 

  Create a network partition - Using below command line to have iptable drop all incoming message at master node

      sudo iptables-save > $HOME/firewall.txt
      sudo iptables -A INPUT -s 10.0.2.0/24 -j DROP

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/partition-points.png)

  
  Insert data from Mongos Query Router, query the data from Mongos Query Router and all three nodes. 
     
     1) Insert a record . 
        use cmpe281B
        // insert bio - Test4 Foo
        db.bios.insert(
        {
        "name" : {
            "first" : "Test4",
            "last" : "Foo"
        },
        "birth" : ISODate("1985-05-19T04:00:00Z"),
        "contribs" : [
            "C"
        ],
        "awards" : [
            {
                "award" : "The Economist Innovation Award",
                "year" : 2003,
                "by" : "The Economist"
            }
        ]})   

     2) Query the record at, Mongo Query Router, node #1, node #2 and node #3. 
   
        rs.slaveOk()
        use cmpe281B
        db.bios.find( { "name.first": "Test4" } )
        db.stats()  

Result: 
- The old master is still up and running but the slave nodes can't connect to it anymore. 
- A new master is elected. 
- The insert from Mongos Query rounter found some delay. It works after the new master is elected. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/round2/with--partition.png)


### Test Case #5: Test Mongo with network partition happen - drop all incoming message on master node - Insert data at Master Node and Query data from all nodes
    - Create a network partition, drop all the incoming message on the master node
    - The master node still up and running but the slave nodes can not connect to master node
    - Insert data at Master Node and Query data from all nodes   
  
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Create a network partition - Using below command line to have iptable drop all incoming message at master node
 
      sudo iptables-save > $HOME/firewall.txt
      sudo iptables -A INPUT -s 10.0.2.0/24 -j DROP
  
  Insert data on one node, query the data on all three nodes. 
  
  Step 1: Insert a record to the node #1 (Master / Primary). 
  
        use cmpe281B
        // insert bio - Tim3 Foo
        db.bios.insert(
        {
        "name" : {
            "first" : "Tim3",
            "last" : "Foo"
        },
        "birth" : ISODate("1985-05-19T04:00:00Z"),
        "contribs" : [
            "C"
        ],
        "awards" : [
            {
                "award" : "The Economist Innovation Award",
                "year" : 2003,
                "by" : "The Economist"
            }
        ]})   

  Step 2: Check the replica set status to see if network partition happens or not. 
  
  Go into the mongo slave nodes. One of the slave node became the master now. See screen capture. 
  
  Step 3: On the new master node, update the data. 
  
      use cmpe281B
      db.bios.update(
      {"name.first" : "Tim"},
      {$set: { "name.first" : "Tim_Updated"}});

   
  Step 4: Query the record at node #1 (previous master but now partition), node #2 (new master) and node #3. 
         
      use cmpe281B
      db.bios.find( { "name.first": "Tim" } )  
      db.bios.find( { "name.first": "Tim_Updated" } )

  Result:
  
  - When the network partition happen, one of the slave nodes will be elected as master. 
  - After updated the data on the new master, the new master and the slave data are consisitant
  - The stale data at old master can still be accessed if direct access the old master (just for testing, on reality, the query won't go to old master directly)
  - The stale data won't be accessed from the Mongos Query Rounter      

One of the slave nodes will be elected as master. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-form.png)

The new master and the slave data are consisitant

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-new-master.png)

The stale data can't be access from Mongo Query Rounter. It can can still be accessed if direct access the old master but on reality this direct access is not allowed. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-old-master.png)
         
### Test Case #6: Test the data insert and query during network partition recovery

    - Reovery the network partition
    - The new master is elected back to the old master
    - Query the data I inserted at Test Case #4 during the network partition to see if it is there
       
  Use the shard rs0. 
  
  Open a bash terminal, it connects to the Mongos Query Router.
  From there, using the Mongos Query Router as jump box, open bash window for 3 nodes on the shard rs0 replica set. 

  Query the record at, Mongo Query Router. 
  
        use cmpe281B
        db.bios.find( { "name.first": "Test4" } )

Result: 

  - The result is interesting. The "Test 4" data is missing!!! In another word, the data has been rolled back to the previous version.
  - When the network partition recovered, the old master has been elected as the new master again.
  - Check the data I inserted during the network partition, the data has been rolled back to the previous version. 
  - All nodes are with consistent data. 
 
See the offical document of MongoDB about the rollback during replica set failover
      
      A rollback reverts write operations on a former primary when the member rejoins its replica set after a failover. A rollback is necessary only if the primary had accepted write operations that the secondaries had not successfully replicated before the primary stepped down. When the primary rejoins the set as a secondary, it reverts, or ¡°rolls back,¡± its write operations to maintain database consistency with the other members.
      MongoDB attempts to avoid rollbacks, which should be rare. When a rollback does occur, it is often the result of a network partition. Secondaries that can not keep up with the throughput of operations on the former primary, increase the size and impact of the rollback.
      A rollback does not occur if the write operations replicate to another member of the replica set before the primary steps down and if that member remains available and accessible to a majority of the replica set.

[Source: https://docs.mongodb.com/manual/core/replica-set-rollbacks/]
      

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/round2/RollbackAfterPartitionRecovery.png)
 

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
  
  Try to update this data on node #2. 
  
    sudo systemctl start cassandra.service
    
    cd /usr/local/cassandra/bin 
    
    ./cqlsh -u cassandra -p cassandra
    
    Use cmpe281;

    UPDATE person 
    SET first_name = 'Person7'
    WHERE person_id = 7;

    select * from person where person_id =7;

Result: 
- When there is network partition, ??????????????

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/testCassandra/partion_7.png)


#### Test Case #3: Test the data insert / query after fixed/recovered network partition 


## Part III - WOW Factors - Script to Generate 1M Data and Test Sharding Balance

  I used a script to insert data for shard test.
  
    db.createCollection("shardTest")
    var bulk = db.shardTest.initializeUnorderedBulkOp();
    var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
    var rnum1 ="";
    var rnum2 ="";
    people = ["Marc", "Bill", "George", "Eliot", "Matt", "Trey", "Tracy", "Greg", "Steve", "Kristina", "Katie", "Jeff"];
    for(var i=0; i<1000000; i++){
       user_id = i;
       rnum1 = Math.floor(Math.random() * chars.length);
       rnum2 = Math.floor(Math.random() * chars.length);
       name = "_"+people[Math.floor(Math.random()*people.length)]+"_"+rnum1+rnum2;
       number = Math.floor(Math.random()*10001);
       bulk.insert( { "user_id":user_id, "name":name, "number":number });
    }
    bulk.execute();
  
Create an index on the shard key. We will use "number" as shard key.

    db.shardTest.createIndex( { number : 1 } )
    sh.shardCollection( "cmpe281.shardTest", { "number" : 1 } )

Check status.

    sh.status()
    db.stats()
    db.printShardingStatus()

  Interestingly, after inserting 1M data, the shards seems become balance automatically and works as design.  

  It works and shows balance in two data Replica Sets (rs0 and rs1).
  
  Result after loading 1M data:
  
  ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/16_mongodb_shard_sharded1Mdata_dbstatus_rs0_rs1_balance.gif)


## Network Partition Simulation Technic

  Here is a note about the approach I have been using to creating a "network partition" for experiments in above test cases of Cassandra and Mongo.  

  A network partition is about: 
  
      1) network decomposition into relatively independent subnets for their separate optimization
      
      2) network split due to the failure of network devices. 
  
  In both cases the partition-tolerant behavior of subnets is expected.
  
  In this project, to manually trigger a network partition, I use the iptable to drop message from a given network segement.  

  Create a network partition - Using below command line to have iptable drop all incoming message. 
  
      sudo iptables-save > $HOME/firewall.txt
      sudo iptables -A INPUT -s 10.0.2.0/24 -j DROP
      
  
  Recover the network partition - use below command line to recover the iptable.

      sudo  iptables-restore < $HOME/firewall.txt
