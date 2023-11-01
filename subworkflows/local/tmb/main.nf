include { TMB } from '../../../modules/local/tmb/main'

workflow TMB_WORKFLOW {

    take:
    ch_mafs

    main:
    ch_versions = Channel.empty()

    TMB (
        ch_mafs
    )

    ch_versions = ch_versions.mix(TMB.out.versions)

    emit:
    tmb = TMB.out.tmb
    versions = ch_versions

}
