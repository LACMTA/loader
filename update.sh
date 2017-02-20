#!/bin/bash
#
# loader update
# will go from buildout to grabbing proper otp.jar files
# rewritten February 2017
#
# needs a lot of room. It completes on a 32GB EC2.
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

OSMBIN="$LHOME/ott/loader/osm/osmosis/bin/osmosis" ;
PBFILE="$LHOME/ott/loader/otp/graph/lax/los-angeles_california.pbf"
OSMFILE="$LHOME/ott/loader/otp/graph/lax/los-angeles_california.osm"
JARFILE="$LHOME/ott/loader/otp/graph/lax/otp.jar"

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

if "$link"; then
  log "Great! we will link the big files."
else
  log "Redundant files ahead! consider this instead\nbash update.sh link"
fi

# make sure we have what's required
sudo apt install -y libpq-dev libssl-dev gcc postgresql postgresql-contrib postgresql-client python-pip virtualenv ;
sudo apt-get install default-jre ;

sudo pip install setuptools==33.1.1 ;
sudo pip install pyparsing  ;
sudo pip install packaging ;
sudo pip install zc.buildout ;
sudo pip install --upgrade pip ;

# create the db user and tables for the loader
sudo -u postgres psql -c "CREATE USER ott WITH PASSWORD 'ott' ;"
sudo -u postgres -c "CREATE DATABASE ott WITH OWNER ott ;"

# destroy the current loader
rm -Rf $LHOME

# checkout the latest loader code adn utils
git clone https://github.com/LACMTA/loader.git ;
git clone https://github.com/OpenTransitTools/utils.git ;
git clone https://github.com/OpenTransitTools/gtfsdb ;

# upgrade the helper code
cd $UHOME ; git pull
env buildout install prod

cd $GHOME ; git pull
env buildout install prod postgresql

cd $BHOME
log "OTT utils and gtfsdb installed"

# set up the virtualenv
cd $LHOME ;
virtualenv .

# run the buildout script
env buildout install lax

log "loader installed"

# install OSMOSIS if necessary
# OSMOSIS is the OpenStreetMap .pbf to .osm converter and db loader
cd $LHOME/ott/loader/osm/osmosis/ ;
bash install.sh
sudo ln -s $LHOME/ott/loader/osm/osmosis/bin/osmosis /usr/bin/ ;

log "Osmosis installed"

# install the protobuffer file and generate the OSM XML
wget https://s3.amazonaws.com/metro-extracts.mapzen.com/los-angeles_california.osm.pbf -O $PBFILE ;

if [ -f "$PBFILE" ];
then
  log "$PBFILE received"
fi

# remove the old OSM file
if [ -f "$OSMFILE" ];
then
    rm "$OSMFILE" ;
fi

cd $LHOME/ott/loader/otp/graph/lax/ ;
# either generate the OSM file or download the one from Mapzen
# osmosis --read-pbf file=$PBFILE --write-xml $OSMFILE
wget https://s3.amazonaws.com/metro-extracts.mapzen.com/los-angeles_california.osm.bz2 -O $OSMFILE.bz2 ;
bunzip2 $OSMFILE.bz2 ;

# and to save 6.0Gb disk space:
cd $BHOME ;
if "$link"; then
  ln -s "$OSMFILE" "$LHOME/ott/loader/otp/graph/lax/los-angeles_california.osm" ;
else
    # fpurcell's code
    cp ../cache/osm/*.* ott/loader/osm/cache/
    sleep 5
    touch ott/loader/osm/cache/*.osm
fi

log "$OSMFILE file is ready"

# get the appropriate otp.jar file
# put it in place
cd $BHOME ;
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
  java -Xmx2G -jar $JARFILE  --version
fi

log "let's grab the schedules and load them into the database"

# load GTFS schedules, OSM address data, and Bikeshare locations
# NOTE this runs the osmosis pieline and recreates the OSM file
cd $LHOME ;
bin/load_data -ini config/app.ini ;

# Generate the Graph.obj to introduce to the shaded otp.jar file
log "let's build the Graph.obj file"

cd $LHOME ;
bin/otp_build --no_tests lax  ;

log "ott/loader/otp/graph/lax/Graph.obj file is ready"


# how long did that take?
duration=$(( SECONDS - start ))
mins=$((duration/60))
log "Schedule update took $mins minutes"
