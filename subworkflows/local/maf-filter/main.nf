workflow MAF_FILTER_WORKFLOW {

    take:
    ch_mafs

    main:
    ch_versions = Channel.empty()

    ch_mafs.view()

    MAF_FILTER (
        ch_mafs
    )

    ch_versions = ch_versions.mix(MAF_FILTER.out.versions)

    emit:
    analysis_maf = MAF_FILTER.out.analysis_maf
    data_mutations_extended_file = MAF_FILTER.out.data_mutations_extended_txt
    rejected_file  = MAF_FILTER.out.rejected_maf
    versions = ch_versions

}