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


run:
  1. bin/test ... this cmd will run loader's unit tests (see: http://docs.zope.org/zope.testrunner/#some-useful-command-line-options-to-get-you-started)
  1. see individual project README's above to see different app runs
  1. and check out the bin/ generated after buildout is run (those binaries are created via buildout & setup.py)
