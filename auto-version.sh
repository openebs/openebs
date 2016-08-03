
BUILDTIME=$(date -u)
GITCOMMIT=$(git rev-parse --short HEAD)

if [ ! "$BUILDTIME" ]; then
	exit 1	
fi
sed -i "s/REPBUILDTIME/$BUILDTIME/g" ./version/version_lib.go

if [ ! "$GITCOMMIT" ]; then
	exit 1	
fi
sed -i "s/REPGITCOMMIT/$GITCOMMIT/g" ./version/version_lib.go

