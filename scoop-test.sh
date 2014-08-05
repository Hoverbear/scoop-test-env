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

# Starts the hub container.
function start_hub () {
  # Hub
  echo $HUB_EXISTS
  if [ HUB_EXISTS ]; then
    docker start $(docker ps -a | grep hub | awk '{print $1}')
  else
    echo "No hub exists, make a hub."
  fi
}
# Starts all the endpoint containers.
function start_ep () {
  # Endpoints
  if [ ENDPOINT_EXISTS ]; then
    # TODO: List/count them.
    docker start $(docker ps -a | grep endpoint | awk '{print $1}')
  else
    echo "No endpoints exists, make endpoints."
  fi
}

# Generates the hub.
function generate_hub () {
  # Hub
  if [ HUB_EXISTS == true ]; then
    docker start $(docker ps -a | grep hub | awk '{print $1}')
    echo "No new hub made, started the existing hub."
  else
    if [ HAS_HUB ]; then
      run_container hub scoop/test-hub -d -p 13001:13001 -p 30308:30308 -p 3002:3002 -p 27017
    else
      # TODO: Make more professional.
      echo "No hub image, run build to create images!"
      exit 1
    fi
  fi
  echo "Run populate next!"
}

# Generates the endpoints.
function generate_ep () {
  # Endpoints
  if [ HAS_ENDPOINT ]; then
    if [ "$1" != "" ]; then
      if [ "$1" -lt "1" ]; then
        # TODO: More professional.
        echo "Shtap with the negativity!"
        exit 1
      else
        NUMBER_OF_ENDPOINTS=$1
      fi
    else
      NUMBER_OF_ENDPOINTS=1
    fi
    echo "Making $NUMBER_OF_ENDPOINTS endpoints."
    for ENDPOINT_NUMBER in `seq 1 $NUMBER_OF_ENDPOINTS`; do
      echo "Building endpoint #$ENDPOINT_NUMBER"
      run_container endpoint-$ENDPOINT_NUMBER scoop/test-endpoint -d -p 3001:3001 -p 27017 --link hub:hub
    done
  else
    # TODO: Make more professional.
    echo "No endpoint image, run build!"
    exit 1
  fi
  # TODO: Better description.
  echo "Run populate next!"
}

# Removes the hub container.
function clean_hub () {
  if [ HUB_EXISTS == true ]; then
    docker rm -f $(docker ps -a | grep hub | awk '{print $1}')
  else
    echo "No endpoints to remove."
  fi
}

# Removes endpoint containers.
function clean_ep () {
  if [ ENDPOINT_EXISTS == true ]; then
    docker rm -f $(docker ps -a | grep endpoint | awk '{print $1}')
  else
    echo "No hub to remove."
  fi
}

function populate () {
  echo "Populating hub database with a default user."
  # To do this yourself: docker run --rm -ti --link hub:hub -v $(pwd)/scoop-hub/db:/backup mongo mongodump -p 27017 -h hub -o /backup
  docker run --rm -ti --link hub:hub -v $(pwd)/scoop-hub/db:/backup mongo mongorestore -p 27017 -h hub /backup

  if [ "$1" != "" ]; then
    if [ "$1" -lt "1" ]; then
      # TODO: More professional.
      echo "Shtap with the negativity!"
      exit 1
    else
      NUMBER_OF_ENDPOINTS=$1
    fi
  else
    NUMBER_OF_ENDPOINTS=1
  fi

  for ENDPOINT_NUMBER in `seq 1 $NUMBER_OF_ENDPOINTS`; do
    echo "Keys exchanging between hub and $NUMBER_OF_ENDPOINTS endpoints."
    ./inject_key.sh $ENDPOINT_NUMBER
  done
}

function help () {
  echo "Help! Available Args"
  echo "build - checks if a hub/ep image exist and if not builds them. Could take a while."
  echo "start -hub|-ep - starts stopped containers, only mostly works."
  echo "generate -hub|-ep [num_of_eps| default=1] - creates containers, if making endpoints can specify # to make."
  echo "populate [num_of_eps| default=1] - Creates default admin user (admin - hunter22) and exchanges keys between hub and endpoints. Links endpoint-1 to endpoint-[num_of_endpoints]"
  echo "clean -hub|-ep - Removes containers, not working yet, just use docker."

}


#########
# Logic #
#########
if [ "$1" == "build" ]; then
  build
  exit
fi
if [ "$1" == "start" ]; then
  if [ "$2" == "-hub" ]; then
    start_hub
    exit
  fi
  if [ "$2" == "-ep" ]; then
    start_ep
    exit
  fi
  echo "Select hub or endpoint option with -hub or -ep"
  exit
fi
if [ "$1" == "generate" ]; then
  if [ "$2" == "-hub" ]; then
    generate_hub $3
    exit
  fi
  if [ "$2" == "-ep" ]; then
    generate_ep $3
    exit
  fi
  echo "Select hub or endpoint option with -hub or -ep"
  exit
fi
if [ "$1" == "clean" ]; then
  if [ "$2" == "-hub" ]; then
    clean_hub
    exit
  fi
  if [ "$2" == "-ep" ]; then
    clean_ep
    exit
  fi
  echo "Select hub or endpoint option with -hub or -ep"
  exit
fi
if [ "$1" == "populate" ]; then
  populate $2
  exit
fi
if [ "$1" == "-h" ]; then
  help
  exit
fi
if [ "$1" == "-help" ]; then
  help
  exit
fi
