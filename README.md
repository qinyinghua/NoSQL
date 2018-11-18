# CMPE281 - Personal NoSql Project

## Requirements 

Select one CP and one AP NoSQL Database.  For example:  Mongo and Riak.
Note: Other NoSQL DBs that can be configured in CP or AP mode are also allowed.

For each Database:
	Set up your cluster as AWS EC2 Instances.  (# of Nodes and Topology is open per your design)
	Make sure to note your approach to creating a "network partition" for experiments.
	Set up the Experiments (i.e. Test Cases) to answer the following questions:
	CP:
		How does the system function during normal mode (i.e. no partition)
		What happens to the master node during a partition? 
		Can stale data be read from a slave node during a partition?
		What happens to the system during partition recovery?
	AP:
		How does the system function during normal mode (i.e. no partition)
		What happens to the nodes during a partition? 
		Can stale data be read from a node during a partition?
		What happens to the system during partition recovery?

Run the Experiments and Record results.

## Mongo Cluster Experiements and Results

Setup
	Select CP NoSQL Databsase Mongo cluster as AWS EC2 Instnaces. 

Network Partition
	Make sure to note your approach to creating a "network partition" for experiments.

Experiments / Test Cases for Mongo
	CP:
		How does the system function during normal mode (i.e. no partition)
		What happens to the master node during a partition? 
		Can stale data be read from a slave node during a partition?
		What happens to the system during partition recovery?

Results
	Results to be added here.

## Mongo Cluster Experiements and Results

Setup
	Select CP NoSQL Databsase Cassandra cluster as AWS EC2 Instnaces. 

Network Partition
	Make sure to note your approach to creating a "network partition" for experiments.

Experiments / Test Cases for Mongo
	AP:
		How does the system function during normal mode (i.e. no partition)
		What happens to the nodes during a partition? 
		Can stale data be read from a node during a partition?
		What happens to the system during partition recovery?

Results
	Results to be added here.
