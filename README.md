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
  1. install python 2.7 and git
  2. `git clone https://github.com/OpenTransitTools/gtfsdb.git`
  3. `git clone https://github.com/OpenTransitTools/utils.git`
  1. `git clone https://github.com/OpenTransitTools/loader.git`
  1. `cd loader`
  2. `virtualenv . ; . bin/activate`
  2. `pip install -r requirements.txt`
  3. `easy_install zc.recipe.egg`	# but pip couldn't install the zope stuff. not sure why
  4. `easy_install zc.recipe.testrunner`
  1. `buildout install prod`

I needed to rerun virtualenv after running buildout. Unsure why. 

```
deactivate
virtualenv .
```

## load requirements

### osmosis

Osmosis is a command line Java application for processing OSM data.

1. `wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz`
2. `mkdir osmosis ; mv osmosis-latest.tgz osmosis/ ; cd osmosis/`
3. tar xvfz osmosis-latest.tgz ; rm osmosis-latest.tgz
4. chmod a+x bin/osmosis ; cp bin/osmosis /usr/local/bin/

or on OSX: `brew install osmosis`

1. cd ott/loader/osm/osmosis/ ; bash install.sh

### load some GTFS and OSM files

1. `bin/load_data -ini config/app.ini`
2. 



run:
  1. bin/test ... this cmd will run loader's unit tests (see: http://docs.zope.org/zope.testrunner/#some-useful-command-line-options-to-get-you-started)
  1. see individual project README's above to see different app runs
  1. and check out the bin/ generated after buildout is run (those binaries are created via buildout & setup.py)
