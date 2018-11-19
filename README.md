# CMPE281 - Personal NoSql Project - Main

## Objective

  In this project, I will be testing the Partition Tolerance of MongoDB and Cassandra NoSQL Database. 
  
  MongoDB is a CP NoSQL Databases while Cassandra is a AP NoSQL Database.
  
  Partition tolerance in CAP means the ability of NoSQL Database system to continue processing data - 
  even if a network partition causes communication errors between subsystems. 
  
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

## Mongo Cluster with Sharding Network Partition Experiements and Results

  Deployment architecture of MongoDB as CP. 
  
  Each shard-x will have 3 nodes to form a replica set. 
  
  ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/docImages/MongoDeploy.png)

## 1. Create 3 Mongo EC2 instances following following steps.

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

1) start from secondary node:

#update to add "--shardsvr" option: mongod --replSet "rs0" --shardsvr --port 27017  
                      
    sudo vi /lib/systemd/system/mongodb.service 
        ExecStart=/usr/bin/mongod --shardsvr --port 27017 --replSet "rs0" --bind_ip localhost,10.0.2.192 --unixSocketPrefix=${SOCKETPATH} --config ${CONF} $DAEMON_OPTS
    sudo systemctl daemon-reload
    sudo systemctl restart mongodb
    sudo systemctl status mongodb  
                           
2)update for primary node

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
    
  #Modify the mongodb.servie to add "--configsvr --replSet configReplSet --port 27019 --bind_ip localhost,10.0.2.116"
  
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

## 8.  Test the Shard Cluster with 1M data

  It works and show balance in two data Replica Sets (rs0 and rs1).

  Insert data for shard test
  
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
  
  Before the 1M data, I try 10000 data. The shard doesn't look balance. 
  
  Result after loading 1K data:
  
  ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/15_mongodb_shard_sharded_status_db1.gif)

  However, after Insert 1M data, the shard works as design.  See the screen capture #2-Result after loading 1M data.
  
  Result after loading 1M data:
  
  ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/16_mongodb_shard_sharded1Mdata_dbstatus_rs0_rs1_balance.gif)
  
## 9.  Test the network partitions
   
### Test Case #1: Test the data query without network partition happen - Insert data at Master Node
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Insert data on one node, query the data on all three nodes. 
     
  Result: When the network is normal, all nodes return the query result appropriatly. 

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

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/good-network-insert-at-master-work.png)


### Test Case #2: Test the data query without network partition happen - Insert data at Slave Node
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminals, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Insert data on one node, query the data on all three nodes. 
  
  Result: It is not allowed to insert into slave nodes. 
  
  1) Insert a record to the node #2 (secondary/slave). 
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

  2) Query the record at node #1, node #2 and node #3. 
   
        rs.slaveOk()
        use cmpe281B
        db.bios.find( { "name.first": "Tim2" } )
        db.stats()  
   
 ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/good-network-insert-at-slave-not-work.png)

### Test Case #3: Test the data query with network partition happen - Insert data at Master Node
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Create a network partition - Using below command line to have iptable drop all incoming message. 
  
  sudo iptables -A INPUT -s 10.0.2.0/24 -j DROP
  
  Insert data on one node, query the data on all three nodes. 
  
  1) Insert a record to the node #1 (Master / Primary). 
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

  2) Check the replica set status to see if network partition happens or not. 
  
  Go into the mongo slave nodes. One of the slave node became the master now. See screen capture. 
  
  3) On the new master node, update the data. 
   
        rs.slaveOk()
        
        On the new master node, update the data. 
        
         use cmpe281B
         db.bios.update(
          {"name.first" : "Tim"},
          {$set: { "name.first" : "Tim_Updated"}});

   
  4) Query the record at node #1 (previous master but now partition), node #2 (new master) and node #3. 
         
         use cmpe281B
         db.bios.find( { "name.first": "Tim" } )  
         db.bios.find( { "name.first": "Tim_Updated" } )

  Result:
  
  - When the network partition happen, one of the slave nodes will be elected as master. 
  
  - After updated the data on the new master, the new master and the slave data are consisitant
  
  - The stale data at old master can still be access if direct access the old master      

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-form.png)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-new-master.png)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-old-master.png)
         
### Test Case #4: Test the data query after fixed/recovered network partition 
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Recover the network partition - use below command line to recover the iptable drop

      sudo iptables -A INPUT -j REJECT 
     
  Insert data on one node, query the data on all three nodes. 
     
  Result: 

  - When the network partition recovered, the old master has been elected as the new master again. 

  - Check the data on all three nodes, the data are consistent after network partition recovery. 

  - All nodes are with updated data. 
     
  The Mongo DB has make the data eventually consistent after a network partition recovery.    

## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-recovered-data-consistent.png)
 
## Cassandra Cluster Experiements and Results

	Setup
		Select CP NoSQL Databsase Cassandra cluster as AWS EC2 Instnaces. 

	Network Partition
		Make sure to note your approach to creating a "network partition" for experiments.

	Experiments / Test Cases for Mongo
		How does the system function during normal mode (i.e. no partition)
		What happens to the nodes during a partition? 
		Can stale data be read from a node during a partition?
		What happens to the system during partition recovery?
	Results
		Run the Experiments and Record results.


## Network Partitions

  A network partition is about: 
  
      1) network decomposition into relatively independent subnets for their separate optimization
      
      2) network split due to the failure of network devices. 
  
  In both cases the partition-tolerant behavior of subnets is expected.
  
  In this project, to manually trigger a network partition, I use the iptable to drop message from a given network segement.  

