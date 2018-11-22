# CMPE 281 - Personal NoSQL Project - Project Journal

Keep a Project Journal (as a markdown document) recording weekly progress, challenges, tests and test results.
All documentation must be written in GitHub Markdown (including diagrams) and committed to GitHub

## Update on Week of 10/29/2018
Read the article (https://www.infoq.com/articles/jepsen) to understand the full process. Try reproduce locally with the same setting mentioned in the article.
1. create the Clojure and Lein environment.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/leinNewProject.gif)

2. create the emacs ide dev environment for Clojure, integrated with nREPL
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/clojureDevelopEnv.gif)


## Update on Week of 11/5/2018
I will start the EC2 Cassandra cluster this week. 
Following below article to setup EC2 Cassandra cluster (4 EC2 instances used in the cluster): https://linode.com/docs/databases/cassandra/set-up-a-cassandra-node-cluster-on-ubuntu-and-centos/
The chanllege is to configure the cluster nodes. We need to pay attentions to the extract configuration file cassandra.yaml mentioned in the article. 
Here is the setup step:
1. Create one template EC2 instance. We will use this instance to make an image for the clustering 4 Cassandra nodes. 
This will make our four nodes with same setting. It will be convenient for trouble shooting.
At the end, we will create a template Cassandra cluster with name "casCluster".
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/00_ec2_imageInstance.gif)
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/0_cassandra_first_run.jpg)
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/1_cassandra_test_running_ok.jpg)
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/4_cassandra_renameCluster_good.gif)

2. According to firewall port access official doc: https://docs.datastax.com/en/cassandra/3.0/cassandra/configuration/secureFireWall.html, 
we need to setup the EC2 security group to open following ports.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_createEC2_cluster_openningPort.gif)


3. Then create a EC2 image using the template EC2 Cassandra instance, then create 4 EC2 instances with the image. 
The 4 EC2 instances will be used as our Cassandra Cluster.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/8_ec2_Allinstances.gif)
We need to update the cassandra.yaml for each node.
At first, the cluster is not able to run. here is the error log:
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/2_createEC2_cluster_cannot_start_errorlog.gif)
After read the official configuration doc carefully, we need to remove the original data in the template, then restart it. 
Here is the final working clustering 4 Cassandra nodes.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/7_createEC2_cluster_nodes_found_work.gif)

**EC2 Cassandra cluster is created finally. The challenge is how to pinpoint the error when you can't make it work. The easy way is to check the log and then google the solution.**

## Update on Week of 11/11/2018
I start the EC2 Mongodb Shard cluster this week. After finish the clustering, I write down the journey for the hard configuration.
Comparing to Cassandra cluster with 4 EC2 nodes, I have to use 10 EC2 nodes to create a shard cluster. That is a nightmare for the whole procedure, as if you fail one step, you have to re-do again. The challenge is how to orchestrate to configure 10 nodes without any missing step. The solution is You need to check each node status after each modification. Do not rush, be patient. 

I refer to the official document to install the MongoDB 3.6 shard clustering, [https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/](https://docs.mongodb.com/v3.6/tutorial/convert-replica-set-to-replicated-shard-cluster/).
Here is the architecture of the clustering and the relative running 10 EC2 nodes.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/mongodb-cluster-diagram.png)
 
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/00_10_nodes_in_mongoCluster.gif)

The whole configuration covers below step:
1. Select the mongodb version, as official ubuntu (the EC2 node's OS) supports Mongodb 3.6, it is better to use the version, instead of 4.0.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/2b_instance_mongodb_up_version.gif)
2.  Set Up two Replica Sets (rs0 and rs1). we use 3 nodes for one Replica set. In our clustering, it will have 2 set of replica set (rs0 and rs1).
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/4_mongodb_3nodes_replicaInit_status.gif)
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/11_mongodb_rs2_init_success_status.gif)
3.  Covert the Replica Sets into two Shards
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/7_mongodb_shardsvr_secondary_setup.gif)

4.  Setup  Config Server Replica Set. It will have 3 nodes.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/8_mongodb_configSrv_init.gif)

5.  Setup a Mongo Query Router EC2 node as the console to access the DB
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/9_mongodb_queryRoute_works.gif)

6.  Open the required port in the EC2 security groups. If not, those nodes can't communicate to form a cluster.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/5_mongodb_shardsvr_openPort_27018.gif)
7.  Integrate the two Replica Sets and Config Server Replica Set and Mongo Query Router into one Shard Cluster.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/12_mongodb_queryRouter_shardingStatus.gif)

8.  Test the Shard Cluster with 1M data. It works and show balance in two data Replica Sets (rs0 and rs1)
Before the 1M data, I try 10000 data. The shard doesn't look balance.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/15_mongodb_shard_sharded_status_db1.gif)
However, after Insert 1M data, the shard works as design.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installMongo/15_mongodb_shard_sharded_status_db1.gif)

## Update on Week of 11/18/2018
Added more test cases to test the MongoDB with / without network partition. 

- How does the system function during normal mode (i.e. no partition)

    Test Case #1: Test the data insert without network partition happen 
    - Insert data success
    Test Case #2: Test the data query without network partition happen 
    - Query data success
    
- What happens to the master node during a partition? 

    Test Case #3: Test the data query during network partition happen - Insert data from Mongos Query Router 
    - Insert data failed as master node is not available
    
- Can stale data be read from a slave node during a partition?

    Test Case #4: Test the data query during network partition - Query data from Mongos Query Router
    - Query data - no stale data could be read from a slave node  
    
- What happens to the system during partition recovery?

    Test Case #4: Test the data insert and query during network partition recovery - Query data from Mongos Query Router  

## Update on Day of 11/21/2018 (I am glad that no class today so that I could spend more time on working on the lab :) )

I spent much time on testing and re-testing the MongoDB and Cassandra network partition cases. I found some interesting issues on MongoDB. 
One of them is about the "Replica Failover Rollback". 

In my test case #4 of MongoDb:
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

 