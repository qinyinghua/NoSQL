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

## Testing Result: 

### MongoDB

What happens on a Partition?

- Primary node goes down: system becomes unavailable while a new primary is selected.
- Primary node is disconnected from too many Secondary nodes: system becomes unavailable. 
- Other secondaries elect a new Primary while the primary steps down

MongoDB provides strong consistency because it is a single-master system and all writes go to primary by default.

- Automatic failover in case of partitioning
- If a partition occurs the system will stop accepting writes until it believes that it can safely complete them

So, it can continue to work in case of network partitioning and it gives up availability. It¡¯s a CP system!

If a partition occurs, that is, a hardware or network failure, there are two worst-case scenarios for the primary node: 
- the primary node fails, and an election has to occur
- or the secondary nodes can not connect to the primary. 

In both cases availability is sacrificed. I

- In the former, the system is unavailable to handle requests during the duration of the node failure and new master election. 
- In the latter, the data itself is unavailable. 

Thus, availability is sacrificed in light of CAP in spite of the availability the replica sets provide.

Hence, MongoDB is referred to as a consistent and partition (CP) tolerant storage system.

### Cassandra

Cassandra's default conguration classifies it as AP, available and partition. 
According to the CAP theorem, consistency is then sacrificed for 
guaranteed high availability (partition tolerance is a non-selectable option
for distributed databases). As seen in the previous section, the distributed,
peer-to-peer structure ensures that any node can handle requests and no data
loss will occur if a node goes down, hence providing availability at all times.

However, this does not mean that there is no consistency at all. Cassandra
has a special feature regarding consistency, that is, Cassandra has tuneable
consistency. Replication factor and consistency level can be set in such
a way that the user can choose between strong consistency and eventual con-
sistency.

Cassandra uses master-master replication scheme, which means that in case of network partition, all nodes will continue working.
It means that we have an AP system.

      
## Mongo Cluster with Sharding Network Partition Experiements and Results

I refer to the official document to install the MongoDB 3.6 shard clustering, [https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/](https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/).

Here is the architecture of the clustering and the relative running 10 EC2 nodes.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/docImages/MongoDeploy.png)

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/mongodb-cluster-diagram.png)

[[Source: https://docs.mongodb.com/v3.6/core/sharded-cluster-components/]]

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

 
## 9.  Test Mongo Cluster without Network Partition
   
### Test Case #1: Test the data query without network partition happen - Insert data at Master Node
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminals, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
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
   
 ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/good-network-insert-at-slave-not-work.png)

## 10.  Test Mongo Cluster with Network Partition Happening

### Test Case #3: Test the data query with network partition happen - Insert data at Master Node
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Create a network partition - Using below command line to have iptable drop all incoming message. 
  
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
  - The stale data at old master can still be accessed if direct access the old master      

One of the slave nodes will be elected as master. 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-form.png)

The new master and the slave data are consisitant

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-new-master.png)

The stale data at old master can still be accessed if direct access the old master 

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-rs-status-at-old-master.png)
         
## 11.  Test Mongo Cluster with Network Partition Recovery

### Test Case #4: Test the data query after fixed/recovered network partition 
   
  Use the shard rs0 to test the network partition. 
  
  Open 3 bash terminal, each console is connecting to 1 of the 3 nodes on the shard rs0 replica set. 
  
  Recover the network partition - use below command line to recover the iptable drop

      sudo  iptables-restore < $HOME/firewall.txt
     
  Insert data on one node, query the data on all three nodes. 
     
  Result: 

  - When the network partition recovered, the old master has been elected as the new master again. 

  - Check the data on all three nodes, the data are consistent after network partition recovery. 

  - All nodes are with updated data. 
     
  The Mongo DB has make the data eventually consistent after a network partition recovery.    

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/mongoTest/bad-network-recovered-data-consistent.png)
 
## 12.  WOW Factors - Script to Generate 1M Data and Test Sharding Balance

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

## Cassandra Cluster Experiements and Results

Select CP NoSQL Databsase Cassandra cluster as AWS EC2 Instnaces. 

Deployment archiecture diagram

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/Cassandra-Ring.jpg)

### 1. Setup EC2 Cassandra cluster

Following below article to setup EC2 Cassandra cluster (4 EC2 instances used in the cluster): https://linode.com/docs/databases/cassandra/set-up-a-cassandra-node-cluster-on-ubuntu-and-centos/

The chanllege is to configure the cluster nodes. We need to pay attentions to the extract configuration file cassandra.yaml mentioned in the article. 

Here is the setup step:
- Create one template EC2 instance. 
- We will use this instance to make an image for the clustering 4 Cassandra nodes. 
- This will make our four nodes with same setting. It will be convenient for trouble shooting.
- At the end, we will create a template Cassandra cluster with name "casCluster".

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/00_ec2_imageInstance.gif)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/0_cassandra_first_run.jpg)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/1_cassandra_test_running_ok.jpg)
![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/4_cassandra_renameCluster_good.gif)

### 2. Setup the Cassandra Cluster Firewall 

According to firewall port access official doc: https://docs.datastax.com/en/cassandra/3.0/cassandra/configuration/secureFireWall.html, 

we need to setup the EC2 security group to open following ports.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_createEC2_cluster_openningPort.gif)

### 3. Create 4 Cassandra node EC2 instances using the image

Then create a EC2 image using the template EC2 Cassandra instance, then create 4 EC2 instances with the image. 

The 4 EC2 instances will be used as our Cassandra Cluster.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_ec2_Allinstances.gif)

We need to
- update the cassandra.yaml for each node.
- remove the original data in the template.
- restart each node. 

Here is the final working clustering 4 Cassandra nodes.

![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/7_createEC2_cluster_nodes_found_work.gif)

### 4. Network Partition

Make sure to note your approach to creating a "network partition" for experiments.

Experiments / Test Cases for Mongo

- How does the system function during normal mode (i.e. no partition)
- What happens to the nodes during a partition? 
- Can stale data be read from a node during a partition?
- What happens to the system during partition recovery?

Results
- Run the Experiments and Record results.

## Network Partitions

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
