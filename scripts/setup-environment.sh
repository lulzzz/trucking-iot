#!/bin/bash

# Variables
projDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"

## Start Kafka, for topic creation (Sandbox only, due to default username/pass)
##curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo":{"context":"_PARSE_.START.KAFKA","operation_level":{"level":"SERVICE","cluster_name":"Sandbox","service_name":"KAFKA"}},"Body":{"ServiceInfo":{"state":"STARTED"}}}' http://sandbox.hortonworks.com:8080/api/v1/clusters/Sandbox/services

# Install SBT if missing
echo "Checking for SBT, installing if missing"
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
yum -y install sbt

# Install Maven if missing
echo "Checking for Maven, installing if missing"
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
yum install -y apache-maven

# Use kafka-topics.sh to create necessary topics
echo "Starting Kafka and creating Kafka topics"
$(find / -type f -wholename '/usr/hd*/kafka' -print -quit) start
kafkaTopicsSh=$(find / -type f -wholename '/usr/hd*/kafka-topics.sh' -print -quit)
$kafkaTopicsSh --create --zookeeper sandbox.hortonworks.com:2181 --replication-factor 1 --partition 1 --topic trucking_data_truckandtraffic

# Move NiFi template into proper location
echo "Importing NiFi template and restart NiFi.  Existing flow is renamed to flow.xml.gz.bak, and NiFi"
mv /var/lib/nifi/conf/flow.xml.gz /var/lib/nifi/conf/flow.xml.gz.bak
cp -f $projDir/trucking-nifi-templates/flow.xml.gz /var/lib/nifi/conf
$(find / -type f -wholename '/usr/hd*/nifi.sh' -print -quit) restart
