
//include { MUTECT } from '../../modules/local/mutect/main'
include { VARDICTJAVA } from '../../../modules/local/vardictjava/main'


workflow CALL_VARIANTS {

    take:
    ch_bams           // meta, path bams, path bais, path bed
    ch_bedfile        // bedfile path
    ch_fasta_ref      // fasta path
    ch_fasta_fai_ref  // fasta_fai path
//    ch_dbsnp
//    ch_cosmic


    main:
    ch_versions = Channel.empty()
    vc_input = Channel.empty()

    ch_bams
        .combine(ch_bedfile)
        .set{ vc_input }

    vc_input.view()
    ch_fasta_ref.view()
    ch_fasta_fai_ref.view()

//    MUTECT (
//
//    )
//    ch_versions = ch_versions.mix(MUTECT.out.versions)

    VARDICTJAVA (
        vc_input,
        ch_fasta_ref,
        ch_fasta_fai_ref
    )
    ch_versions = ch_versions.mix(VARDICTJAVA.out.versions)

    emit:
    versions = ch_versions

}