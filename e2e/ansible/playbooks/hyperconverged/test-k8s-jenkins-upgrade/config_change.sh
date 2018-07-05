#!/bin/bash

sed -i '\|<denyAnonymousReadAccess>true</denyAnonymousReadAccess>|d' /var/jenkins_home/config.xml
sed -i '\|</authorizationStrategy>|d' /var/jenkins_home/config.xml 
sed -i '\|<disableSignup>true</disableSignup>|d' /var/jenkins_home/config.xml
sed -i '\|<enableCaptcha>false</enableCaptcha>|d' /var/jenkins_home/config.xml
sed -i '\|</securityRealm>|d' /var/jenkins_home/config.xml
sed -i 's#FullControlOnceLoggedInAuthorizationStrategy"#AuthorizationStrategy$Unsecured"/#g' /var/jenkins_home/config.xml
sed -i 's#HudsonPrivateSecurityRealm"#SecurityRealm$None"/#g' /var/jenkins_home/config.xml




