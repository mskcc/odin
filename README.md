## Introduction

**mskcc/odin** is a bioinformatics pipeline that performs variant analysis on a pair of bams. The output is an annotated maf that is properly filtered and annotated.

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

![ODIN diagram](docs/images/oding_diagram.png)

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

#### Running nextflow @ MSKCC

If you are runnning this pipeline on a MSKCC cluster you need to make sure nextflow is properly configured for the HPC envirornment:

```bash
module load java/jdk-17.0.8
module load singularity/3.7.1
export PATH=$PATH:/path/to/nextflow/binary
export SINGULARITY_TMPDIR=/path/to/network/storage/for/singularity/tmp/files
export NXF_SINGULARITY_CACHEDIR=/path/to/network/storage/for/singularity/cache
```

### Running the pipeline

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
pairId,tumorBam,normalBam,assay,normalType,bedFile
pair_id,tumor.bam,normal.bam,assay,normalType,optional:regions.bed
```

Each row represents a pair of bam files and bait set.

For optional bed file, you can either enter a bed file leave it bank and one will be generated using covered intervals.
To leave the field blank you can use any of these options:

```csv
pair_id,tumor.bam,normal.bam,assay,normalType,NONE
pair_id,tumor.bam,normal.bam,assay,normalType,null
pair_id,tumor.bam,normal.bam,assay,normalType,
```

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

nextflow run

```bash
nextflow run main.nf \
   -profile singularity,test_juno \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Credits

mskcc/odin was originally written by C. Allan Bolipata.

We thank the following people for their extensive assistance in the development of this pipeline:

- Nikhil ([@nikhil](https://github.com/nikhil))

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  mskcc/odin for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
