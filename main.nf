#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.input = 'example_manifest.csv'
params.bucket = false

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { file(it.Filename) }
  .map { file ->  tuple(file.simpleName, file) }
  .randomSample(10)
  .into { key_ch; view_ch }

view_ch.view()

process get_headers{
  publishDir "$params.outdir", saveAs: {filname -> "${name}.json"}
  //errorStrategy 'ignore'
  echo true
  conda '/home/ubuntu/anaconda3/envs/auto-minerva-author'
  input:
    set name, file(key) from key_ch
  output:
    file "*"
  script:
  if: (params.bucket != false)
  """
  python $projectDir/image-tags2json.py "s3://$bucket/$key" > 'tags.json'
  """
  else:
  """
  python $projectDir/image-tags2json.py $key > 'tags.json'
  """
}
