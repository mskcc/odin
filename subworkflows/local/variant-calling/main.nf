
include { MUTECT } from '../../modules/local/mutect/main'
include { VARDICTJAVA } from '../../modules/nf-core/vardictjava/main'


workflow CALL_VARIANTS {

    take:
    ch_bams          // meta, path bams, path bais, path bed
    ch_fasta_ref     // meta2, fasta path
    ch_fasta_fai_re  // meta3, fasta_fai path
    ch_dbsnp
    ch_cosmic


    main:
    ch_versions = Channel.empty()

    MUTECT (

    )
    ch_versions = ch_versions.mix(MUTECT.out.versions)

    VARDICTJAVA (

    )
    ch_versions = ch_version.mix(VARDICTJAVA.out.versions)

    emit:



}