Metro OTP loader
======

## forked from OpenTransitTools/loader

The loader project contains multiple utilities to load GTFS, OSM and OTP data into various apps and databases. The sub projects are:
  1. [gtfs](ott/loader/gtfs/README.md), which contains routines to cache and compare gtfs feeds.
  1. [gtfsdb](ott/loader/gtfsdb/README.md), which loads gtfs files into GTFSDB
  1. [osm](ott/loader/osm/README.md), which downloads OSM .pdb files, and futher can extract .osm data via OSMOSIS
  1. [otp](ott/loader/otp/README.md), which builds graphs (Graph.obj) databases for [OpenTripPlanner](http://opentripplanner.org)
  1. [solr](ott/loader/solr/README.md), which pulls data from

## install
install python 2.7 and git. then:

```
# clone three repositories
git clone https://github.com/OpenTransitTools/gtfsdb.git
git clone https://github.com/OpenTransitTools/utils.git
git clone https://github.com/OpenTransitTools/loader.git
cd loader
# set up virtualenv, activate
virtualenv .
. bin/activate
pip install -r requirements.txt
# pip couldn't install the zope stuff. not sure why
easy_install zc.recipe.egg
easy_install zc.recipe.testrunner
buildout install prod
```

I needed to rerun virtualenv after running buildout. Unsure why.

```
deactivate
virtualenv .
```

## set up the gtfsdb and utils repositories

Make sure that you have PostgreSQL (>v9.1) installed locally with the PostGIS extensions (>v2.2).
Once installed you may open the `ott` table and run this query:

`CREATE EXTENSION postgis;`

## Load Data

start inside the loader folder

```
. bin/activate
cd ../gtfsdb
buildout install prod postgresql

cd ../utils
buildout install prod

cd ../loader
```
## load requirements

### install osmosis

Osmosis is a command line Java application for processing OSM data. You may install osmosis with homebrew on OSX, use the install script in `ott/loader/osm/osmosis/` or do this:

```
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
mkdir osmosis ; mv osmosis-latest.tgz osmosis/ ; cd osmosis/
tar xvfz osmosis-latest.tgz ; rm osmosis-latest.tgz
chmod a+x bin/osmosis ; cp bin/osmosis /usr/local/bin/
```



### load some GTFS and OSM files
```
bin/load_data -ini config/app.ini

# put it in the database
bin/load_all -ini config/app.ini
```

## Generate the Graph.obj to introduce to the shaded otp.jar file

```
bin/otp_build --no_tests prod
```

### these are the defaults
```
DEFAULT_SUBWAY_ACCESS_TIME = 2.0
htmlAnnotations = false
maxHtmlAnnotationsPerFile = 1000
transit = true
useTransfersTxt = false
parentStopLinking = false
stationTransfers = false
subwayAccessTime = 2.0
streets = true
embedRouterConfig = true
areaVisibility = false
matchBusRoutesToStreets = false
fetchElevationUS = true
elevationBucket = [AWS S3 bucket configuration: bucketName=ned13 accessKey=AKIAI5DKXIBQAUDA2S3A secretKey=***]
fareServiceFactory = DefaultFareServiceFactory
customNamer = org.opentripplanner.graph_builder.module.osm.PortlandCustomNamer@7a36aefa
staticBikeRental = false
staticParkAndRide = true
staticBikeParkAndRide = false
maxInterlineDistance = 200

...

11:52:43.538 INFO (GraphBuilder.java:174) Graph building took 30.7 minutes.
```

copy the Graph.obj to to the server:

```
scp ott/loader/otp/graph/prod/Graph.obj 52.11.203.105:/tmp/


# then on the server
sudo chown otp:otp /tmp/Graph.obj
sudo chmod 664 /tmp/Graph.obj
sudo cp /home/otp/graphs/lax/Graph.obj /tmp/Graph.obj_works
sudo mv /tmp/Graph.obj /home/otp^Craphs/lax/
sudo  /etc/init.d/opentripplanner restart
```

## Load the places into Pelias

## *... this is as far as I've gotten using Purcell's loader. The next steps are approximate!*



## rebuild the graph when new GTFS data arrives

```
java -Xmx2G -jar ott/loader/otp/graph/prod/otp.jar \
    --build ott/loader/otp/graph/prod \
    --router prod \
    --basePath ott/loader/otp
```

## run the server as a daemon

```
java -Xmx2G -jar ott/loader/otp/graph/prod/otp.jar \
    --graphs ott/loader/otp/graph \
    --basePath ott/loader/otp \
    --server \
    --insecure \
    --router lax \
    --autoScan \
    --autoReload
```
---

**original documentation below. this is untested! -doug**

run:
  1. bin/test ... this cmd will run loader's unit tests (see: http://docs.zope.org/zope.testrunner/#some-useful-command-line-options-to-get-you-started)
  1. see individual project README's above to see different app runs
  1. and check out the bin/ generated after buildout is run (those binaries are created via buildout & setup.py)




 psql -f ott/loader/gtfsdb/create_postgis_db.psql ott -f ott/loader/gtfsdb/create_postgis_db.psql
