include { GATK_FINDCOVEREDINTERVALS } from '../../modules/local/gatk-findCoveredIntervals/main'
include { CAT } from '../../modules/local/cat/main'
include { LIST2BED } from '../../modules/local/list2bed/main'

workflow FIND_COVERED_INTERVALS {
    take:
    ch_bams // meta, path bams, path bais
    ch_fasta_ref      // fasta path
    ch_fasta_fai_ref  // fasta_fai path
    intervals // interval list

    main:

    interval_channel = Channel.fromList(intervals)
    distributed_intervals = interval_channel.collate(10)

    GATK_FINDCOVEREDINTERVALS (
        ch_bams,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        distributed_intervals
    )

    interval_files = GATK_FINDCOVEREDINTERVALS.out.fci
        .map{
            new Tuple(it[0].id,it[0],it[1])
        }
        .groupTuple()
        .map{
            output_file = it[0] + ".list"
            new Tuple(it[1][0],output_file, it[2])
        }

    CAT (
        interval_files
    )

    LIST2BED (
        CAT.output.combined
    )


    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(GATK_FINDCOVEREDINTERVALS.out.versions)
    ch_versions = ch_versions.mix(CAT.out.versions)
    ch_versions = ch_versions.mix(LIST2BED.out.versions)


    emit:
    bed_file = LIST2BED.out.bed_file
    versions = ch_versions // channel: [ versions.yml ]
}
