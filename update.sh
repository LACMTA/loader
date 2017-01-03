#
# loader update
# will go from buildout to grabbing proper otp.jar files
# rewritten December 2016
#
# install this in your crontab
# # run the loader each day at 2am and send the log to ~/loader.log
# 0 2 * * *  bash ~/update.sh link > ~/loader.log 2>&1

# set some variables
link=false
if [[ $1 == "link" ]]; then
  link=true
fi

start=$SECONDS

# function to print a log a message
log ()
{
  echo "--------------------------------------"
  printf "$1\n"
  echo "--------------------------------------"
}


if "$link"; then
  log "Great! we will link the big files."
else
  log "Redundant files ahead! consider this instead\nbash update.sh link"
fi

# upgrade the helper code
cd utils ; git pull
buildout install prod

cd ../gtfsdb ; git pull
buildout install prod postgresql
cd ..

log "OTT utils and gtfsdb installed"

# destroy the current loader
rm -Rf loader

# checkout the latest loader code
git clone https://github.com/LACMTA/loader.git

# set up the virtualenv
cd ; cd loader ;
virtualenv .

# run the buildout script
bin/pip install zc.buildout
buildout install lax

log "loader installed"

# install OSMOSIS if necessary
# OSMOSIS is the OpenStreetMap .pbf to .osm converter and db loader
cd ;
thefile="loader/ott/loader/osm/osmosis/bin/osmosis"
if [ -f "$thefile" ];
then
    cd ott/loader/osm/osmosis/
    bash install.sh
    cd -
fi

log "Osmosis installed"

# install the protobuffer file and generate the OSM XML
cd ;
wget https://s3.amazonaws.com/metro-extracts.mapzen.com/los-angeles_california.osm.pbf \
  -O loader/ott/loader/otp/graph/lax/los-angeles_california.pbf ;

cd ;
thefile="loader/ott/loader/otp/graph/lax/los-angeles_california.pbf"
if [ -f "$thefile" ];
then
  log "$thefile received"
fi

# remove the old OSM file
cd ;
osmfile="loader/ott/loader/otp/graph/lax/los-angeles_california.osm"
if [ -f "$osmfile" ];
then
    rm "$osmfile" ;
fi

cd ; cd loader/ott/loader/otp/graph/lax/ ;
osmosis --read-pbf file=los-angeles_california.pbf --write-xml \
  los-angeles_california.osm

# and to save 6.0Gb disk space:
cd ;
if "$link"; then
  ln -s loader/ott/loader/otp/graph/lax/los-angeles_california.osm \
    loader/ott/loader/otp/graph/lax/los-angeles_california.osm ;
else
    # fpurcell's code
    cp ../cache/osm/*.* ott/loader/osm/cache/
    sleep 5
    touch ott/loader/osm/cache/*.osm
fi

log "$osmfile file is ready"

# get the appropriate otp.jr file
# put it in place
cd ;
jarfile="loader/ott/loader/otp/graph/lax/otp.jar"
if [ -f "$jarfile" ];
then
    rm "$jarfile" ;
fi

wget http://maven.conveyal.com.s3.amazonaws.com/org/opentripplanner/otp/1.0.0/otp-1.0.0-shaded.jar \
  -O loader/ott/loader/otp/graph/lax/otp.jar ;

if [ -f "$jarfile" ];
then
  log "otp.jar file installed"
  # print the otp headers
  java -Xmx2G -jar ott/loader/otp/graph/lax/otp.jar  --version
fi

log "let's grab the schedules and load them into the database"


# load GTFS schedules, OSM address data, and Bikeshare locations
cd ; cd loader ;
bin/load_data -ini config/app.ini ;

# Generate the Graph.obj to introduce to the shaded otp.jar file
log "let's build the Graph.obj file"

cd ; cd loader ;
bin/otp_build --no_tests lax  ;

log "ott/loader/otp/graph/lax/Graph.obj file is ready"

# copy the file to the otp servers
# NOTE -- you need add a mechanism to update these IP addresses!
scp ott/loader/otp/graph/lax/Graph.obj 52.11.203.105:/tmp/
scp ott/loader/otp/graph/lax/Graph.obj 52.89.200.110:/tmp/

# now, install a script called installgraph.sh on the remote server
# to install the new Graph.obj file

# #!/bin/bash
#
# if [[ '/tmp/Graph.obj' -nt '/home/otp/graphs/lax/Graph.obj' ]]; then
#   mv /home/otp/graphs/lax/Graph.obj /tmp/Graph.obj.old ;
#   chown otp:otp /tmp/Graph.obj ;
#   mv /tmp/Graph.obj /home/otp/graphs/lax/Graph.obj ;
#   /etc/init.d/opentripplanner restart ;
#   echo "Time: $(date -Iseconds) new Graph.obj file installed"
# else
#   echo "Time: $(date -Iseconds) /tmp/Graph.obj file older or doesn't exist"
# fi
#
# and an entry in root's crontab
# 0 4 * * *  bash ~/installgraph.sh >> ~/installgraph.log 2>&1


# how long did that take?
duration=$(( SECONDS - start ))
mins=$((duration/60))
log "Schedule update took $mins minutes"
