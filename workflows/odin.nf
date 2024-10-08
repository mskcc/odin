/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowOdin.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { CALL_VARIANTS } from '../subworkflows/local/variant-calling/main'
include { FIND_COVERED_INTERVALS } from '../subworkflows/local/find_covered_intervals'
include { MAF_PROCESSING } from '../subworkflows/local/maf-processing/main'
include { MAF_FILTER_WORKFLOW } from '../subworkflows/local/maf-filter/main'
include { MAF_ANNOTATE } from '../subworkflows/local/maf-annotate/main'
include { TMB_WORKFLOW } from '../subworkflows/local/tmb/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary

workflow ODIN {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        file(params.input)
    )

    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // TODO: OPTIONAL, you can use nf-validation plugin to create an input channel from the samplesheet with Channel.fromSamplesheet("input")
    // See the documentation https://nextflow-io.github.io/nf-validation/samplesheets/fromSamplesheet/
    // ! There is currently no tooling to help you write a sample sheet schema

    // Run variant callers
    // TODO: Going to assume .bai for each bam is created, but in the future add something that creates index if it doesn't exist
    ch_fasta_ref = Channel.value([ "reference_genome", file(params.fasta) ])
    ref_index_list = []
    for(single_genome_ref in params.fasta_index){
        ref_index_list.add(file(single_genome_ref))
    }
    ch_fasta_fai_ref = Channel.value([ "reference_genome_index",ref_index_list])
    ch_bedfile = Channel.value([ file(params.bed_file) ])
    ch_dbsnp = Channel.value([ "dbsnp", file(params.dbsnp) ])
    ch_cosmic = Channel.value([ "cosmic", file(params.cosmic) ])
    ch_hotspot = Channel.value([ "hotspot", file(params.hotspot) ])
    ch_impact_gene_list = Channel.value([ "impact_gene_list", file(params.impact_gene_list) ])
    ch_exac_filter = Channel.value(["exac_filter", file(params.exac_filter)])
    ch_exac_filter_index = Channel.value(["exac_filter_index", file(params.exac_filter_index)])
    intervals = params.intervals

    input_files = INPUT_CHECK.out.bams
        .branch {
            no_bed: it[3] == null
            bed_provided: it[3] != null
        }

    fci_input = input_files.no_bed
        .map{
            new Tuple(it[0],it[1],it[2])
        }

    FIND_COVERED_INTERVALS (
        fci_input,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        intervals
    )

    generated_beds = join_bams_with_bed(fci_input, FIND_COVERED_INTERVALS.out.bed_file)

    variant_input = input_files.bed_provided.mix(generated_beds)

    CALL_VARIANTS (
        variant_input,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        ch_dbsnp,
        ch_cosmic,
        ch_hotspot
    )

    ch_versions = ch_versions.mix(CALL_VARIANTS.out.versions)

    MAF_PROCESSING (
        CALL_VARIANTS.out.annotate_vcf,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        ch_exac_filter,
        ch_exac_filter_index,
        INPUT_CHECK.out.bams,
        INPUT_CHECK.out.curated_bams
    )

    ch_versions = ch_versions.mix(MAF_PROCESSING.out.versions)

    MAF_FILTER_WORKFLOW (
        MAF_PROCESSING.out.maf
    )

    ch_versions = ch_versions.mix(MAF_FILTER_WORKFLOW.out.versions)

    MAF_ANNOTATE (
        MAF_FILTER_WORKFLOW.out.analysis_maf,
        ch_impact_gene_list
    )

    ch_versions = ch_versions.mix(MAF_ANNOTATE.out.versions)

    TMB_WORKFLOW (
        MAF_FILTER_WORKFLOW.out.data_mutations_extended_file
    )

    ch_versions = ch_versions.mix(TMB_WORKFLOW.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )


}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

def join_bams_with_bed(bams,bed) {
        bam_channel = bams
            .map{
                new Tuple(it[0].id,it)
                }
        bed_channel = bed
            .map{
                new Tuple(it[0].id,it)
                }
        mergedWithKey = bam_channel
            .join(bed_channel)
        merged = mergedWithKey
            .map{
                new Tuple(it[1][0],it[1][1],it[1][2],it[2][1])
            }
        return merged

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
