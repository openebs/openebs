OpenShift 3 Database Examples
=============================

This directory contains example JSON templates to deploy databases in OpenShift
on OpenEBS volumes. They can be used to immediately instantiate a database and 
expose it as a service in the current project, or to add a template that can be 
later used from the Web Console or the CLI.

The examples can also be tweaked to create new templates.


## Usage

### Instantiating a new database service

Use these instructions if you want to quickly deploy a new database service in
your current project. Instantiate a new database service with this command:

    $ oc new-app /path/to/template.json

Replace `/path/to/template.json` with an appropriate path, that can be either a
local path or an URL. Example:

    $ oc new-app https://raw.githubusercontent.com/openebs/openebs/master/k8s/openshift/examples/db-templates/openebs-mongodb-persistent-template.json

The parameters listed in the output above can be tweaked by specifying values in
the command line with the `-p` option:

    $ oc new-app examples/db-templates/openebs-mongodb-persistent-template.json -p DATABASE_SERVICE_NAME=mydb -p MONGODB_USER=default -p STORAGE_CLASS_NAME=openebs-default

## More information

The usage of each supported database image is further documented in the links
below:

- [MySQL](https://docs.openshift.org/latest/using_images/db_images/mysql.html)
- [PostgreSQL](https://docs.openshift.org/latest/using_images/db_images/postgresql.html)
- [MongoDB](https://docs.openshift.org/latest/using_images/db_images/mongodb.html)
