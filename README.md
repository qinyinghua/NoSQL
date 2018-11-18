# CMPE281 - Personal NoSql Project - Main

## Objective

  In this project, I will be testing the Partition Tolerance of MongoDB and Cassandra NoSQL Database. 
  
  MongoDB is a CP NoSQL Databases while Cassandra is a AP NoSQL Database.
  
  Partition tolerance in CAP means the ability of NoSQL Database system to continue processing data - 
  even if a network partition causes communication errors between subsystems. 
  
  Based on the reference artical, we made following hypothesis. The experiments would be built based on this.
  
      1) When network is healthy, the CP NoSQL Database Mongo and AP NoSQL Database Cassandra can be both consistent and available.
      
      2) When "network partition" occurs, messages are dropped, CP NoSQL Database would
          -- be able to keep "consistency" / "linearizability" 
          -- not be able to keep all nodes "availability" 
          -- would reject some requests on some nodes.  
      
      3) When "network partition" occurs, messages are dropped, AP NoSQL Database would
          -- not be able to keep "consistency" / "linearizability" 
          -- different nodes can disagree about the order in which operations took place.
          -- be able to keep all nodes "availability" - can handle requests on all nodes.  

## Network Partitions

  A network partition is about: 
  
      1) network decomposition into relatively independent subnets for their separate optimization
      2) network split due to the failure of network devices. 
  
  In both cases the partition-tolerant behavior of subnets is expected.
  
  In this project, to manually trigger a network partition, I would deploy the NoSQL database cluster acrossing a WAN connection. 
  Amazon EC2 Availability Azones are in different physical locations. 
  While looking at the Amazon EC2 Server Region speeds, 
  the highest latency would be between Asia Singapore datacenter and Europe Sao Paulo datacenter. 
  
  It is possible Amazon has good the network connection among all those Availability Zones so the network partitions won't happen. 
  If that is the case, I would use a WAN simulation tools to simulate the network latency between two networks. 


## Mongo Cluster Experiements and Results

	Mongo Cluster with Sharding Setup
    https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/MongoClusterSharding.md
    ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/docImages/MongoDeploy.png)

	Network Partition
		Make sure to note your approach to creating a "network partition" for experiments.

	Experiments / Test Cases for Mongo
		How does the system function during normal mode (i.e. no partition)
		What happens to the master node during a partition? 
		Can stale data be read from a slave node during a partition?
		What happens to the system during partition recovery?

	Results
		Run the Experiments and Record results.

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

