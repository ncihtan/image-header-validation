#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.input = 's3://htan-dcc-ohsu/imaging_level_2/synapse_storage_manifest.csv'

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { it.Filename }
  .map {file -> tuple(file.simpleName, file) }
  .randomSample(10)
  .set { key_ch }

process stream_headers{
  publishDir "$params.outdir"
  //errorStrategy 'ignore'
  conda '/home/ubuntu/anaconda3/envs/auto-minerva-author'
  input:
    set name, key from key_ch
  output:
    file("${name}.json")
  script:
  """
  python $projectDir/stream_headers.py \
    htan-dcc-ohsu $key \
    sandbox-developer s3
  """
}
