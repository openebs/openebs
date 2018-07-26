#!/bin/bash

sed -i -e 10d -e 11d -e 13d -e 14d -e 15d /var/jenkins_home/config.xml
sed -i 's#FullControlOnceLoggedInAuthorizationStrategy"#AuthorizationStrategy$Unsecured"/#g' /var/jenkins_home/config.xml
sed -i 's#HudsonPrivateSecurityRealm"#SecurityRealm$None"/#g' /var/jenkins_home/config.xml




