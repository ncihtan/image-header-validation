#!/usr/bin/env nextflow

params.outdir = 'outputs'
params.input = 'example_manifest.csv'
params.bucket = false

if (params.bucket == false){
  Channel
    .fromPath(params.input)
    .splitCsv(header: true)
    .map { it.Filename }
    .map { x -> file(x)}
    .map { file ->  tuple(file.simpleName, file) }
    .randomSample(10)
    .into { key_ch; view_ch }
  }
else {
  Channel
    .fromPath(params.input)
    .splitCsv(header: true)
    .map { it.Filename }
    .map { x -> file("s3://$params.bucket/$x")}
    .map { file -> tuple(file.simpleName, file) }
    .randomSample(10)
    .into { key_ch; view_ch }
}

view_ch.view()

process get_headers{
  publishDir "$params.outdir", saveAs: {filname -> "${name}.json"}
  //errorStrategy 'ignore'
  echo true
  input:
    set name, file(image) from key_ch
  output:
    file "*"
  script:

  """
  python $projectDir/image-tags2json.py $image > 'tags.json'
  """

}
