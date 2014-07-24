#!/bin/bash

#############
# Variables #
#############
# Image exists?
docker images | grep scoop/test-hub > /dev/null
if [ $? == 0 ]; then HAS_HUB=true; else HAS_HUB=false; fi
docker images | grep scoop/test-endpoint > /dev/null
if [ $? == 0 ]; then HAS_ENDPOINT=true; else HAS_ENDPOINT=false; fi
# Container Exists?
docker ps -a | grep hub > /dev/null
if [ $? == 0 ]; then HUB_EXISTS=true; else HUB_EXISTS=false; fi
docker ps -a | grep endpoint > /dev/null
if [ $? == 0 ]; then ENDPOINT_EXISTS=true; else ENDPOINT_EXISTS=false; fi
# Container Running?
docker ps | grep hub > /dev/null
if [ $? == 0 ]; then HUB_RUNNING=true; else HUB_RUNNING=false; fi
docker ps | grep endpoint > /dev/null
if [ $? == 0 ]; then ENDPOINT_RUNNING=true; else ENDPOINT_RUNNING=false; fi

# Counts
ENDPOINT_NUMBER=1

#############
# Functions #
#############
# Build image
#  $1: The tag of the image to build.
#  $2: Location
function build_image () {
  echo
  echo "Building $1"
  docker build -t $1 $2 > /dev/null
  echo "Finished with status: $?"
  echo
}

# Run Container
#  $1: The name of the container.
#  $2: The image to run.
#  $*: Other arguments to pass.
function run_container () {
  echo
  NAME=$1
  shift
  IMAGE=$1
  shift
  echo "Running $NAME as $IMAGE"
  docker run $* --name=$NAME $IMAGE
  echo "Finished with status: $?"
  echo
}
# Builds the necessary images.
function build () {
	if [ HAS_HUB == true ]; then
		docker rmi scoop/test-hub
	fi
	build_image scoop/test-hub scoop-hub/
	if [ HAS_ENDPOINT == false ]; then
		docker rmi scoop/test-endpoint
	fi
	build_image scoop/test-endpoint scoop-endpoint/
}
# Starts all the containers.
function start () {
	# Hub
	if [ HUB_EXISTS == true ]; then
		docker start $(docker ps -a | grep hub | awk '{print $1}')
	else
		if [ HAS_HUB ]; then
			run_container hub scoop/test-hub -d -p 13001:13001 -p 30308:30308 -p 3002:3002 -p 27017
		else
			# TODO: Make more professional.
			echo "Run build to create images!"
			exit 1
		fi
	fi
	# Endpoints
	if [ ENDPOINT_EXISTS == true ]; then
		docker start $(docker ps -a | grep endpoint | awk '{print $1}')
	else
		if [ HAS_ENDPOINT ]; then
			# TODO: Loop and handle many endpoints.
			run_container endpoint-$ENDPOINT_NUMBER scoop/test-endpoint -d -p 3001:3001 -p 22:22 -p 27017 --link hub:hub
		else
			# TODO: Make more professional.
			echo "Run build!"
			exit 1
		fi
		# TODO: Better description.
		echo "Make an account on the hub and make yourself an admin."
		echo "It might take time to start... Be patient."
	fi
}
# Cleans up all related containers.
function clean () {
	if [ ENDPOINT_EXISTS == true ]; then
		docker rm -f $(docker ps -a | grep endpoint | awk '{print $1}')
	else
		echo "No hub to remove."
	fi
	if [ HUB_EXISTS == true ]; then
		docker rm -f $(docker ps -a | grep hub | awk '{print $1}')
	else
		echo "No endpoints to remove."
	fi
}
function populate () {
	echo "Populating hub database with a default user."
	# To do this yourself: docker run --rm -ti --link hub:hub -v $(pwd)/scoop-hub/db:/backup mongo mongodump -p 27017 -h hub -o /backup
	docker run --rm -ti --link hub:hub -v $(pwd)/scoop-hub/db:/backup mongo mongorestore -p 27017 -h hub /backup

	echo "Keys exchanging."
	./inject_key.sh $ENDPOINT_NUMBER
}
#########
# Logic #
#########
if [ "$1" == "build" ]; then
	build
	exit
fi
if [ "$1" == "start" ]; then
	start
	exit
fi
if [ "$1" == "clean" ]; then
	clean
	exit
fi
if [ "$1" == "populate" ]; then
	populate
	exit
fi
