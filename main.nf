#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.bucket = ""
params.input = 'example_manifest.csv'

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { it.Filename }
  .map { val ->  tuple(file(val).simpleName, val) }
  .randomSample(10)
  .into { key_ch; view_ch }

view_ch.view()

process get_headers{
  publishDir "$params.outdir", saveAs: {filname -> "${name}.json"}
  //errorStrategy 'ignore'
  echo true
  conda '/home/ubuntu/anaconda3/envs/auto-minerva-author'
  input:
    set name, key from key_ch
  output:
    file "*"
  script:
  """
  python $projectDir/image-tags2json.py $params.bucket $key > 'tags.json'
  """
}
