#################################################################################
# This is a script that will be run periodically as part of a cronjob on the
# Jenkins master (build machine) to check whether there are any updates to the
# e2e folder in the openebs repository (https://github.com/openebs/openebs),
# which contains the test automation code, and apply them to the local working
# repo (via git pull).In the event of any changes, a jenkins CI run is triggered
# to verify the sanity of the latest code.
#
# The script actions are logged into git_update.log, which will be available in
# the same directory as this script
#################################################################################

./git_update.sh 2>&1 | awk '{ print strftime("%c:"),$0; fflush();}' >> git_update.log 
