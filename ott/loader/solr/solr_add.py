import os
import datetime

from xml.etree.ElementTree import Element, SubElement, Comment
from xml.etree import ElementTree

from ott.utils import num_utils
from ott.utils import geo_utils

from .solr_del import SolrDel


class SolrAdd(object):
    """ will create an XML document that conforms to SOLR's REST service for adding items to the index
        @see http://lucene.apache.org/solr/quickstart.html#indexing-solr-xml
        @see http://lucene.apache.org/solr/quickstart.html#indexing-json  (@todo maybe move to json)

        @todo investigate using SolrPy (not sure why I didn't think of this before)
        @todo I think using .xml docs is a good short term solution, but better to populate SOLR (or elasticsearch)
        @see https://pypi.python.org/pypi/pysolr/3.5.0
    """
    rec = None
    doc = None
    type = None
    type_name = None
    file_name = None
    file_path = None
    boost='1.0'

    def __init__(self, type, type_name=None, file_name=None, boost='1.0', comment=''):
        self.header(comment)
        self.boost = boost
        self.type = type
        self.type_name = type_name if type_name else self.type
        self.file_name = "{}_add.xml".format(file_name if file_name else self.type_name)

    def header(self, comment):
        self.rec = ElementTree.Element('add')
        cmt_el = ElementTree.Comment(' Generated on {} {} '.format(datetime.date.today(), comment))
        self.rec.append(cmt_el)

    def new_doc(self, id, name=None):
        self.doc = SubElement(self.rec, 'doc', attrib={'boost' : self.boost})
        self.add_field('type', self.type)
        self.add_field('type_name', self.type_name)
        self.add_field('id', id)
        if name is None:
            name = id
        self.add_field('name', name)

    def add_field(self, name, value):
        field = SubElement(self.doc, 'field', attrib={'name':name})
        field.text = value

    def add_point(self, point, add_xy=True):
        coords = point.get('coordinates')
        self.add_lon_lat(lon=coords[0], lat=coords[1], add_xy=add_xy)

    def add_lon_lat(self, lon, lat, add_xy=True):
        self.add_field('lon', str(lon))
        self.add_field('lat', str(lat))
        if add_xy:
            x,y = geo_utils.to_OSPN(lon, lat)
            self.add_x_y(x, y, False)

    def add_x_y(self, x, y, add_ll=True):
        self.add_field('x', str(x))
        self.add_field('y', str(y))
        if add_ll:
            lon,lat = num_utils.to_lon_lat(x, y)
            self.add_lon_lat(lon, lat, False)

    def document_to_string(self):
        return ElementTree.tostring(self.rec, encoding='utf8', method='xml')

    def to_file(self, path=""):
        # step 1: output XML to _add.xml file
        self.file_path = os.path.join(path, self.file_name)
        doc = ElementTree.tostring(self.rec, encoding='utf8', method='xml')
        with open(self.file_path, 'w') as f:
            f.write(doc)

        # step 2: create a _del.xml file to go along with this add
        sd = SolrDel(type=self.type, type_name=self.type_name)
        sd.to_file(path)