#Outputs

`$ROOT` refers to the path to the top of the output hierarchy and in that folder, files/folders are organized as follows:
##`$ROOT/*txt|*pdf`
* `$ROOT/sample_data_clinical.txt` - Patient/sample data from the investigator
* `$ROOT/sample_mapping.txt` - Maps samples to the folders containing their FASTQs
* `$ROOT/sample_pairing.txt` - Pairs tumors to normals for somatic variant calling

##`$ROOT/bam` 
The fully processed (markduplicated, realigned, recalibrated) BAM files for the project with indices.

##`$ROOT/maf`
* `${sampleID}.svs.pass.vep.maf` - Structural variants (SVs) in MAF format (IMPACT only)
* `${sampleID}.svs.pass.vep.portal.txt`- Same as above but annotated for cBioPortal upload
* `${sampleID}.muts.maf` - Small substitutions and indels in MAF format. False positives have a non-PASS tag in the FILTER column, and “fillout” rows (allele counts per event in other samples) are tagged “None” in the Mutation_Status column. 

##`ROOT/vcf`
* `${sampleID}.vardict.vcf` - Substitutions and indels reported by VarDict in VCF format
* `${sampleID}.mutect.{vcf,txt}` - A MuTect VCF plus its more detailed tab-delimited format
* `${sampleID}.svs.vcf`- Comprehensive VCF of SVs detected by Delly (IMPACT only)
* `${sampleID}.svs.pass.vcf` - Shortlisted VCF of Delly SVs after some basic filtering

##`$ROOT/json`
Contains the input files used for the pipeline

