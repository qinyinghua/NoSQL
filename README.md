# cmpe281-qinyinghua Individual NoSql Project

## Update on Week of 10/29/2018
Read the article (https://www.infoq.com/articles/jepsen) to understand the full process. Try reproduce locally with the same setting mentioned in the article.
1. create the Clojure and Lein environment.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/leinNewProject.gif)

2. create the emacs ide dev environment for Clojure, integrated with nREPL
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/clojureDevelopEnv.gif)


## Update on Week of 11/5/2018
We will start the EC2 Cassandra cluster this week. 
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
Here is the final working clusting 4 Cassandra nodes.
## ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/installCassandra/part2_cluster/7_createEC2_cluster_nodes_found_work.gif)




