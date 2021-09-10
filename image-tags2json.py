#!/usr/bin/python

import argparse
from tifffile import TiffFile
import sys
from pathlib import Path
import os
import json

parser = argparse.ArgumentParser(description = 'Pull image tags from an streaming s3 object')
parser.add_argument('input',
                    type=str,
                    help='the file to parse the headers of ')

args = parser.parse_args()

with TiffFile(s3_file) as tif:
    tif_tags = {}
    for pages in tif.pages:
      for tag in pages.tags.values():
        name, value = tag.name, tag.value
        tif_tags[name] = value

json.dump(tif_tags, f)
