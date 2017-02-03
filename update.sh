#!/bin/bash
#
# loader update
# will go from buildout to grabbing proper otp.jar files
# rewritten February 2017
#
# install this in your crontab
# # run the loader each day at 2am and send the log to ~/loader.log
# 0 2 * * *  bash ~/update.sh link > ~/loader.log 2>&1

#
# loader update
# will go from buildout to grabbing proper otp.jar files
# June 2016
#

# set some variables
link=false
if [[ $1 == "link" ]]; then
  link=true
fi

start=$SECONDS
BHOME="/home/ubuntu"
LHOME="$BHOME/loader"
UHOME="$BHOME/utils"
GHOME="$BHOME/gtfsdb"

PROD_OTP_1="52.11.203.105"
PROD_OTP_2="35.162.45.167"
STG_OTP_1="52.89.200.110"


# function to print a log a message
log ()
{
  echo "--------------------------------------"
  printf "$1\n"
  echo "--------------------------------------"
}

# update the local GTFS files
cd /var/www/html/ ;
git clone https://gitlab.com/LACMTA/gtfs_lax.git ;
cd /var/www/html/gtfs_lax ;
git pull ;

if "$link"; then
  log "Great! we will link the big files."
else
  log "Redundant files ahead! consider this instead\nbash update.sh link"
fi

# upgrade the helper code
cd utils ; git pull

# make sure we have what's required
pip install setuptools==33.1.1 ;
pip install pyparsing  ;
pip install packaging ;
pip install zc.buildout ;

env buildout install prod

cd $GHOME ; git pull


env buildout install prod postgresql
cd $BHOME

log "OTT utils and gtfsdb installed"

# destroy the current loader
rm -Rf $LHOME

# checkout the latest loader code
git clone https://github.com/LACMTA/loader.git

# set up the virtualenv
cd $LHOME ;
virtualenv .

# run the buildout script
env buildout install lax

log "loader installed"

# install OSMOSIS if necessary
# OSMOSIS is the OpenStreetMap .pbf to .osm converter and db loader
cd ;
thefile="loader/ott/loader/osm/osmosis/bin/osmosis" ;
if [ -f "$thefile" ];
then
    cd ;
    cd loader/ott/loader/osm/osmosis/
    bash install.sh
    cd -
fi

log "Osmosis installed"

# install the protobuffer file and generate the OSM XML
cd ;
wget https://s3.amazonaws.com/metro-extracts.mapzen.com/los-angeles_california.osm.pbf \
  -O loader/ott/loader/otp/graph/lax/los-angeles_california.pbf ;

cd $BHOME ;
thefile="loader/ott/loader/otp/graph/lax/los-angeles_california.pbf"
if [ -f "$thefile" ];
then
  log "$thefile received"
fi

# remove the old OSM file
cd $BHOME ;
osmfile="loader/ott/loader/otp/graph/lax/los-angeles_california.osm"
if [ -f "$osmfile" ];
then
    rm "$osmfile" ;
fi

cd $BHOME/ott/loader/otp/graph/lax/ ;
osmosis --read-pbf file=los-angeles_california.pbf --write-xml \
  los-angeles_california.osm

# and to save 6.0Gb disk space:
cd ;
if "$link"; then
  ln -s "$LHOME/ott/loader/otp/graph/lax/los-angeles_california.osm" \
    "$LHOME/ott/loader/otp/graph/lax/los-angeles_california.osm" ;
else
    # fpurcell's code
    cp ../cache/osm/*.* ott/loader/osm/cache/
    sleep 5
    touch ott/loader/osm/cache/*.osm
fi

log "$osmfile file is ready"

# get the appropriate otp.jr file
# put it in place
cd $BHOME ;
JARFILE="$LHOME/ott/loader/otp/graph/lax/otp.jar"
if [ -f "$JARFILE" ];
then
    rm "$JARFILE" ;
fi

wget http://maven.conveyal.com.s3.amazonaws.com/org/opentripplanner/otp/1.0.0/otp-1.0.0-shaded.jar \
  -O "$JARFILE" ;

if [ -f "$JARFILE" ];
then
  log "otp.jar file installed"
  # print the otp headers
  cd $BHOME ;
  java -Xmx2G -jar loader/ott/loader/otp/graph/lax/otp.jar  --version
fi

log "let's grab the schedules and load them into the database"

# load GTFS schedules, OSM address data, and Bikeshare locations
cd $LHOME ;
bin/load_data -ini config/app.ini ;

# Generate the Graph.obj to introduce to the shaded otp.jar file
log "let's build the Graph.obj file"

cd $LHOME ;
bin/otp_build --no_tests lax  ;

log "ott/loader/otp/graph/lax/Graph.obj file is ready"

# copy the file to the otp servers
# NOTE: you need add a mechanism to update these IP addresses!
# NOTE: you need the public keys from the remote machines!
scp loader/ott/loader/otp/graph/lax/Graph.obj "$PROD_OTP_1:/tmp/Graph.obj"
scp loader/ott/loader/otp/graph/lax/Graph.obj "$PROD_OTP_2:/tmp/Graph.obj"
scp loader/ott/loader/otp/graph/lax/Graph.obj "$STG_OTP_1:/tmp/Graph.obj"

# do some remote voodoo to move the Graph.obj files into place
ssh -t $PROD_OTP_1 << EOF
  sudo -u root mv /home/otp/graphs/lax/Graph.obj /tmp/Graph.obj.old ;
  sudo -u root chown otp:otp /tmp/Graph.obj ;
  sudo -u root mv /tmp/Graph.obj /home/otp/graphs/lax/Graph.obj ;
  sudo -u root ls -l /home/otp/graphs/lax/Graph.obj ;
  sudo -u root /etc/init.d/opentripplanner stop ;
  sudo -u root /etc/init.d/opentripplanner start ;
EOF

ssh -t $PROD_OTP_2 << EOF
  sudo -u root mv /home/otp/graphs/lax/Graph.obj /tmp/Graph.obj.old ;
  sudo -u root chown otp:otp /tmp/Graph.obj ;
  sudo -u root mv /tmp/Graph.obj /home/otp/graphs/lax/Graph.obj ;
  sudo -u root ls -l /home/otp/graphs/lax/Graph.obj ;
  sudo -u root /etc/init.d/opentripplanner stop ;
  sudo -u root /etc/init.d/opentripplanner start ;
EOF

ssh -t $STG_OTP_1 << EOF
  sudo -u root mv /home/otp/graphs/lax/Graph.obj /tmp/Graph.obj.old ;
  sudo -u root chown otp:otp /tmp/Graph.obj ;
  sudo -u root mv /tmp/Graph.obj /home/otp/graphs/lax/Graph.obj ;
  sudo -u root ls -l /home/otp/graphs/lax/Graph.obj ;
  sudo -u root /etc/init.d/opentripplanner stop ;
  sudo -u root /etc/init.d/opentripplanner start ;
EOF


# how long did that take?
duration=$(( SECONDS - start ))
mins=$((duration/60))
log "Schedule update took $mins minutes"
