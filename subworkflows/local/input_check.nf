//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_bam_channel(it) }
        .set { bams }

    emit:
    bams                                     // channel: [ val(meta), [ bams ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ tumor_bam, normal_bam ] ]
def create_bam_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.tumor_name + "_" + row.normal_name

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.tumor_bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Tumor BAM file does not exist!\n${row.tumor_bam}"
    }
    if (!file(row.normal_bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Normal BAM file does not exist!\n${row.normal_bam}"
    }
    bam_meta = [ meta, [ file(row.tumor_bam), file(row.normal_bam) ] ]
    return bam_meta
}
