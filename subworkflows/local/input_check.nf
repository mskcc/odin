//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { SAMTOOLS_HEADER_VIEW as normal_header; SAMTOOLS_HEADER_VIEW as tumor_header} from '../../modules/local/get_bam_header'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_bam_channel(it) }
        .set { bam_files }
    tumor_sample = bam_files
        .map {
            new Tuple(it[0],it[1][0])
        }
    normal_sample = bam_files
        .map {
            new Tuple(it[0],it[1][1])
        }
    tumor_header( tumor_sample )
    normal_header( normal_sample )

    combined_bams = tuple_join(bam_files, tumor_header.out.sample_name)
    combined_bams = tuple_join(combined_bams,normal_header.out.sample_name )

    bams = combined_bams
        .map{ set_bam_sample_name(it) }


    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)
    ch_versions = ch_versions.mix(tumor_header.out.versions)
    ch_versions = ch_versions.mix(normal_header.out.versions)


    emit:
    bams                                     // channel: [ val(meta), [ bams ] ]
    versions = ch_versions // channel: [ versions.yml ]
}
def tuple_join(first, second) {
    first_channel = first
        .map{
            new Tuple(it[0].id,it)
            }
    second_channel = second
        .map{
            new Tuple(it[0].id,it)
            }
    mergedWithKey = first_channel
        .join(second_channel)
    merged = mergedWithKey
        .map{
            it[1] + it[2][1]
        }
    return merged

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
    def tumorBaiAlt = "${row.tumorBam}".replaceAll('bam$', 'bai')
    def normalBaiAlt = "${row.normalBam}".replaceAll('bam$', 'bai')

    def foundTumorBai = ""
    def foundNormalBai = ""

    if (file(tumorBai).exists()) {
        foundTumorBai = tumorBai
    }
    else{
        if(file(tumorBaiAlt).exists()){
            foundTumorBai = tumorBaiAlt
        }
        else{
        exit 1, "ERROR: Please verify inputs -> Tumor BAI file does not exist!\n${row.tumorBam}"
        }
    }
    if (file(normalBai).exists()) {
        foundNormalBai = normalBai
    }
    else{
        if(file(normalBaiAlt).exists()){
            foundNormalBai = normalBaiAlt
        }
        else{
            exit 1, "ERROR: Please verify inputs -> Normal BAI file does not exist!\n${row.normalBam}"
        }
    }


    bams = [ meta, [ file(row.tumorBam), file(row.normalBam) ], [ file(foundTumorBai), file(foundNormalBai) ] ]
    return bams
}

def set_bam_sample_name(List bams) {
    meta = bams[0]
    def tumorSample = bams[3]
    def tumorBam = bams[1][0]
    def normalSample = bams[4]
    def normalBam = bams[1][1]
    if( tumorSample == null || tumorSample.isEmpty() ){
        exit 1, "ERROR: No sample name found for tumor sample, please make sure the SM tag is set in the bam\n${tumorBam}"
    }
    if( normalSample == null || normalSample.isEmpty() ){
        exit 1, "ERROR: No sample name found for normal sample, please make sure the SM tag is set in the bam\n${normalBam}"
    }
    meta.tumorSampleName = tumorSample.trim()
    meta.normalSampleName = normalSample.trim()
    return [ meta, bams[1], bams[2] ]

}
