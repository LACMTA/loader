import os
import logging
log = logging.getLogger(__file__)

from ott.utils import object_utils
from ott.utils import db_utils
from ott.utils import file_utils
from ott.utils.cache_base import CacheBase
from ott.loader.gtfs.gtfs_cache import GtfsCache
from gtfsdb.api import database_load

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__file__)


class GtfsdbLoader(CacheBase):
    """ load GTFS data into a gtfsdb
    """
    feeds = []
    db_url = None
    is_geospatial = False

    def __init__(self):
        super(GtfsdbLoader, self).__init__(section='gtfs')

        self.feeds   = self.config.get_json('feeds', section='gtfs')
        self.db_url  = self.config.get('url', section='db', def_val='postgresql+psycopg2://127.0.0.1:5432/ott')
        self.is_geospatial = self.config.get_bool('is_geospatial', section='db')

    def check_db(self, force_update=False):
        ''' check the local cache, and decide whether we should update or not
        '''
        reload = force_update
        if GtfsCache.check_feeds_against_cache(self.feeds, self.cache_dir, force_update):
            reload = True

        if reload:
            db_utils.check_create_db(self.db_url, self.is_geospatial)
            self.load_feeds()

    def load_feeds(self):
        ''' insert feeds into configured db (see config/app.ini)
        '''
        #import pdb; pdb.set_trace()
        print("load_feeds")
        ret_val = True
        err_ext = "-error_loading"

        # get rid of any previously cached error files
        file_utils.purge(self.cache_dir, ".*" + err_ext)

        for f in self.feeds:
            # get cached feed path and feed name (see 'feeds' in config/app.ini)
            feed_path = os.path.join(self.cache_dir, f['name'])
            feed_name = f['name'].rstrip(".zip")

            # make args for gtfsdb
            kwargs = {}
            kwargs['url'] = self.db_url
            if "sqlite:" not in self.db_url:
                kwargs['is_geospatial'] = self.is_geospatial
                kwargs['schema'] = feed_name

            # load this feed into gtfsdb
            log.info("loading {} ({}) into gtfsdb {}".format(feed_name, feed_path, self.db_url))
            try:
                database_load(feed_path, **kwargs)
            except Exception, e:
                ret_val = False
                file_utils.mv(feed_path, feed_path + err_ext)
                log.error("DATABASE ERROR : {}".format(e))
        return ret_val

    @classmethod
    def load(cls):
        ''' run the gtfsdb loader against all the specified feeds from config/app.ini
            NOTE: this is effectively a main method for downloading, caching and db loading new/updated gtfs feeds
        '''
        #import pdb; pdb.set_trace()
        db = GtfsdbLoader()
        db.check_db(force_update=object_utils.is_force_update())
