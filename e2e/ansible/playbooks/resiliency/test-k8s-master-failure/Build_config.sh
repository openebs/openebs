#! /bin/bash


java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080 get-job sample > /var/jenkins_home/template.xml
java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080 create-job Test < /var/jenkins_home/template.xml
java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080 build Test 
    


