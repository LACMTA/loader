import os
import sys
from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
README = open(os.path.join(here, 'README.md')).read()
CHANGES = open(os.path.join(here, 'CHANGES.txt')).read()

requires = [
    'gtfsdb',
    'ott.utils',
    'ott.gbfsdb',
    'simplejson',
    'mako',
    'pyparsing',
    'psycopg2',
]

extras_require = dict(
    dev=[],
)

#
# eggs that you need if you're running a version of python lower than 2.7
#
if sys.version_info[:2] < (2, 7):
    requires.extend(['argparse>=1.2.1', 'unittest2>=0.5.1'])

setup(
    name='ott.loader',
    version='0.1.0',
    description='Open Transit Tools - OTT Loader',
    long_description=README + '\n\n' + CHANGES,
    classifiers=[
        "Programming Language :: Python",
        "Topic :: Internet :: WWW/HTTP",
    ],
    author="Open Transit Tools",
    author_email="info@opentransittools.org",
    dependency_links=[
        'git+https://github.com/OpenTransitTools/utils.git#egg=ott.utils-0.1.0',
        'git+https://github.com/OpenTransitTools/gbfsdb.git#egg=ott.gbfsdb-1.0.0',
        'git+https://github.com/OpenTransitTools/gtfsdb.git#egg=gtfsdb-1.0.0',
    ],
    license="Mozilla-derived (http://opentransittools.com)",
    url='http://opentransittools.com',
    keywords='ott, otp, gtfs, gtfsdb, data, database, services, transit',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    install_requires=requires,
    extras_require=extras_require,
    tests_require=requires,
    test_suite="ott.loader.tests",
    # find ott | grep py$ | xargs grep "def.main"
    entry_points="""
        [console_scripts]
        load_data = ott.loader.loader:load_data
        load_db = ott.loader.loader:load_db
        load_all = ott.loader.loader:load_all
        deploy_all = ott.loader.loader:deploy_all

        osm_update = ott.loader.osm.osm_cache:OsmCache.load

        gtfs_update = ott.loader.gtfs.gtfs_cache:main
        gtfs_info = ott.loader.gtfs.info:main
        gtfs_fix = ott.loader.gtfs.fix:main
        gtfs_fix_tm = ott.loader.gtfs.fix:rename_trimet_agency

        gtfsdb_load = ott.loader.gtfsdb.gtfsdb_loader:GtfsdbLoader.load

        otp_build = ott.loader.otp.graph.build:main
        otp_deploy = ott.loader.otp.graph.deploy:main
        otp_run = ott.loader.otp.graph.run:Run.run
        otp_static_server = ott.loader.otp.graph.run:Run.static_server
        otp_preflight = ott.loader.otp.preflight.test_runner:main
        otp_stress_test = ott.loader.otp.preflight.stress.stress_tests:main
        otp_test_urls = ott.loader.otp.preflight.tests_to_urls:main

        sum_update = ott.loader.sum.sum_cache:SumCache.load

        solr_load = ott.loader.solr.solr_loader:SolrLoader.load
    """,
)
