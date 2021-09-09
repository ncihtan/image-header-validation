#!/usr/bin/env nextflow

params.outdir = '.'
params.input = 's3://htan-dcc-ohsu/imaging_level_2/synapse_storage_manifest.csv'

Channel
  .fromPath(params.input)
  .splitCsv(header: true)
  .map { it.Filename }
  .view()
