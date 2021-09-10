#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.bucket = "htan-imaging-example-datasets"
params.input = 'example_manifest.csv'

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { it.Filename }
  .randomSample(10)
  .map { file -> tuple(file.simpleName, file)}
  .set { key_ch }

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
