#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.bucket = "htan-imaging-example-datasets"
params.input = 'synapse_storage_manifest.csv'

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { it.Filename }
  .randomSample(10)
  .set { key_ch }

process stream_headers{
  publishDir "$params.outdir"
  //errorStrategy 'ignore'
  echo true
  conda '/home/ubuntu/anaconda3/envs/auto-minerva-author'
  input:
    val key from key_ch
  output:
    file "*"
  script:
  """
  python $projectDir/stream_headers.py htan-dcc-ohsu $key
  """
}
