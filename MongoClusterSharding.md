# CMPE281 - Personal NoSql Project - Mongo Cluster Sharding

    Back to the project main report: 
        https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/README.md

    Mongo Cluster with Sharding Setup
			Select CP NoSQL Databsase Mongo cluster as AWS EC2 Instnaces. 
	    Here is the deployment architecture of MongoDB as CP. Each shard-x will have 3 nodes to form a replica set. 
	    ![](https://github.com/nguyensjsu/cmpe281-qinyinghua/blob/master/IndividualProject/docImages/MongoDeploy.png)

## Create Monggo EC2 instances

    Image: Ubuntu Server 18.04
    Szie: t2.micro (Variable ECUs, 1 vCPUs, 2.5 GHz, Intel Xeon Family, 1 GiB memory, EBS only)  
	
    Install Mongo
    
				sudo apt update
				sudo apt install mongodb
				sudo systemctl status mongodb
				mongod --version
					db version v3.6.3
				sudo systemctl start mongodb
				sudo vi /lib/systemd/system/mongodb.service  
				   /usr/bin/mongod --unixSocketPrefix=${SOCKETPATH} --config ${CONF} $DAEMON_OPTS
				                   --replSet "rs0" --bind_ip localhost,10.0.2.118 
				
				sudo vi /etc/mongodb.conf
				   bind_ip localhost,10.0.2.118
				
				sudo systemctl daemon-reload
				sudo systemctl restart mongodb
				sudo systemctl status mongodb