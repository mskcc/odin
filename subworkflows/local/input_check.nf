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

// Function to get list of [ meta, [ tumorBam, normalBam, assay, normalType ] ]
def create_bam_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.pairId
    meta.assay      = row.assay
    meta.normalType = row.normalType

    // add path(s) of the bam files to the meta map
    def bams = []
    if (!file(row.tumorBam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Tumor BAM file does not exist!\n${row.tumorBam}"
    }
    if (!file(row.normalBam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Normal BAM file does not exist!\n${row.normalBam}"
    }

    def tumorBai = "${row.tumorBam}.bai"
    def normalBai = "${row.normalBam}.bai"

    if (!file(tumorBai).exists()) {
        exit 1, "ERROR: Please verify inputs -> Tumor BAI file does not exist!\n${row.tumorBam}"
    }
    if (!file(normalBai).exists()) {
        exit 1, "ERROR: Please verify inputs -> Normal BAI file does not exist!\n${row.normalBam}"
    }
 
    bams = [ meta, [ file(row.tumorBam), file(row.normalBam) ], [ file(tumorBai), file(normalBai) ] ]
    return bams
}
