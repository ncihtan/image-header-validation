#!/usr/bin/python

import argparse
import boto3
from tifffile import TiffFile
import sys
import io
from pathlib import Path
import os
import json

parser = argparse.ArgumentParser(description = 'Pull image tags from an streaming s3 object')
parser.add_argument('bucket',
                    type=str,
                    help='name of a s3 bucket that your profile has access to')
parser.add_argument('key',
                    type=str,
                    help='key for an object in the s3 bucket defined by --bucket. Must be a .ome.tiff file')
parser.add_argument('--profile',
                    type=str,
                    help='aws profile to use')
parser.add_argument('--s3_bucket_type',
                    type=str,
                    default="s3",
                    help='S3 bucket type, [s3, gs]')

args = parser.parse_args()

# Define a streaming s3 object file class S3File(io.RawIOBase):
class S3File(io.RawIOBase):
    """
    https://alexwlchan.net/2019/02/working-with-large-s3-objects/
    """
    def __init__(self, s3_object):
        self.s3_object = s3_object
        self.position = 0

    def __repr__(self):
        return "<%s s3_object=%r>" % (type(self).__name__, self.s3_object)

    @property
    def size(self):
        return self.s3_object.content_length

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            self.position = offset
        elif whence == io.SEEK_CUR:
            self.position += offset
        elif whence == io.SEEK_END:
            self.position = self.size + offset
        else:
            raise ValueError("invalid whence (%r, should be %d, %d, %d)" % (
                whence, io.SEEK_SET, io.SEEK_CUR, io.SEEK_END
            ))

        return self.position

    def seekable(self):
        return True

    def read(self, size=-1):
        if size == -1:
            # Read to the end of the file
            range_header = "bytes=%d-" % self.position
            self.seek(offset=0, whence=io.SEEK_END)
        else:
            new_position = self.position + size

            # If we're going to read beyond the end of the object, return
            # the entire object.
            if new_position >= self.size:
                return self.read()

            range_header = "bytes=%d-%d" % (self.position, new_position - 1)
            self.seek(offset=size, whence=io.SEEK_CUR)

        return self.s3_object.get(Range=range_header)["Body"].read()

    def readable(self):
        return True

# Stream the highest level image
print("Loading image")

if args.s3_bucket_type == "s3":
  session = boto3.session.Session(profile_name=args.profile)
  s3 = session.client('s3')
  s3_resource = session.resource('s3')

if args.s3_bucket_type == "gs":
  print("Accessing GCS resource")
  session = boto3.session.Session(profile_name=args.profile)
  s3_resource = session.resource('s3',endpoint_url = "https://storage.googleapis.com")

print("Getting object")
s3_obj = s3_resource.Object(bucket_name=args.bucket, key=args.key)
print("Creating streaming s3 file")
s3_file = S3File(s3_obj)

basename = os.path.basename(args.key)
basename = Path(basename)
extensions = "".join(basename.suffixes)
output_path =str(basename).replace(extensions, ".json")

with TiffFile(s3_file) as tif:
    tif_tags = {}
    for pages in tif.pages:
      for tag in pages.tags.values():
        name, value = tag.name, tag.value
        tif_tags[name] = value


with open(output_path, 'w') as f:
  json.dump(tif_tags, f)
