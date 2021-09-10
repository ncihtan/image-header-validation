#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.input = 'example_manifest.csv'
params.bucket = ""

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
  """
<<<<<<< HEAD
  python $projectDir/image-tags2json.py $key > 'tags.json'
=======
  python $projectDir/image-tags2json.py $key --bucket $bucket > 'tags.json'
>>>>>>> 30b4cb0c8f4cc6a17a96383973feec2b88b55f40
  """
}
