# CMPE281 - Personal NoSql Project - Mongo Cluster Sharding

Back to the project main report: 

https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/README.md

## Cassandra Cluster Experiements and Results

### 1. Setup EC2 Cassandra cluster

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
