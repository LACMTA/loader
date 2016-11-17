# Metro OTP loader
## forked from OpenTransitTools/loader
The loader project contains multiple utilities to load GTFS, OSM and OTP data into various apps and databases. The sub projects are:
1. [gtfs](ott/loader/gtfs/README.md), which contains routines to cache and compare gtfs feeds.
2. [gtfsdb](ott/loader/gtfsdb/README.md), which loads gtfs files into GTFSDB
3. [osm](ott/loader/osm/README.md), which downloads OSM .pdb files, and futher can extract .osm data via OSMOSIS
4. [otp](ott/loader/otp/README.md), which builds graphs (Graph.obj) databases for [OpenTripPlanner](http://opentripplanner.org)
5. [solr](ott/loader/solr/README.md), which pulls geocoder data from the PostgreSQL database

## Let's install the Metro GTFS loader for the Open Trip Planner
Start by installing python 2.7, PostgreSQL 9.1+, PostGIS v2.2+, and git on your system. Then:


### clone three repositories
```
git clone https://github.com/OpenTransitTools/gtfsdb.git
git clone https://github.com/OpenTransitTools/utils.git
git clone https://github.com/LACMTA/loader.git
```

### set up virtualenv but DON'T ACTIVATE

```
cd loader
virtualenv .
```

### run the buildout script
```
bin/pip install zc.buildout
buildout install prod
```

## Set up the OTT projects gtfsdb and utils before loading data
start inside the loader folder

```
cd ../gtfsdb
buildout install prod postgresql

cd ../utils
buildout install prod

cd ../loader
```

### Install the PostGIS extensions.

Create the `ott` table and an ott user:

```
CREATE DATABASE ott;
CREATE USER ott WITH PASSWORD 'ott';
GRANT ALL PRIVILEGES ON DATABASE "ott" to ott;

# \connect ott;
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```


## Build requirements

### Osmosis
Osmosis is a command line Java application for processing OSM data. You may install osmosis with homebrew on OSX, use the install script in `ott/loader/osm/osmosis/`, or do this:

```
cd ../loader
cd ott/loader/osm/osmosis/
bash install.sh

# you should get a message that ends with
# "Full usage details are available at: http://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage"

# back to the loader directory
cd ../../../../
```

### use the scripts to download the GTFS and OSM files listed in config/app.ini

#### load GTFS schedules, OSM address data, and Bikeshare locations

```
bin/load_data -ini config/app.ini
```

#### load the schedule data into the database

```
bin/load_db -ini config/app.ini
```


#### Generate the Graph.obj to introduce to the shaded otp.jar file

```
bin/otp_build --no_tests prod
```

## You now have a working Graph.obj file and you should be able to run the OTP server. Try it!

## Introduce the graph object

```
java -Xmx2G -jar ott/loader/otp/graph/prod/otp.jar \
    --build ott/loader/otp/graph/prod \
    --router prod \
    --basePath ott/loader/otp
```

## Run the server locally as a daemon

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

#### Build and test the OTP Graph.obj file with location and schedules.

```
bin/load_all -ini config/app.ini
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
sudo mv /tmp/Graph.obj /home/otp/graphs/lax/
sudo  /etc/init.d/opentripplanner restart
```

## Load the places into Pelias

```
scp ott/loader/otp/graph/prod/los-angeles_california.osm 52.11.203.105:/tmp/

# then on the server
```

## The OTP server is very fussy about versions. Be sure that your local version matches the server. In this case OTP v1.0.0.

```
wget http://maven.conveyal.com.s3.amazonaws.com/org/opentripplanner/otp/1.0.0/otp-1.0.0-shaded.jar \
  -O ott/loader/otp/graph/prod/otp.jar
```

## rebuild the graph GTFS data arrives

```
java -Xmx2G -jar ott/loader/otp/graph/prod/otp.jar \
    --build ott/loader/otp/graph/prod \
    --router prod \
    --basePath ott/loader/otp
```

## run the server locally as a daemon

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

## *... this is as far as I've gotten using Purcell's loader. The next steps are approximate!*
# get the OTP version,

```
java -Xmx2G -jar ott/loader/otp/graph/prod/otp.jar  -V
```

--------------------------------------------------------------------------------

**original documentation below. this is untested! -doug**

run:
1. bin/test ... this cmd will run loader's unit tests (see: [http://docs.zope.org/zope.testrunner/#some-useful-command-line-options-to-get-you-started](http://docs.zope.org/zope.testrunner/#some-useful-command-line-options-to-get-you-started))
2. see individual project README's above to see different app runs
3. and check out the bin/ generated after buildout is run (those binaries are created via buildout & setup.py)
