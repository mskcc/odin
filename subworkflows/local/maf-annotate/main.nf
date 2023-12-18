
include { ANNOTATE_ADD_AF } from '../../../modules/local/maf-annotate/add_af'
include { ANNOTATE_ADD_IS_IN_IMPACT } from '../../../modules/local/maf-annotate/add_is_in_impact'
include { ANNOTATE_ADD_MAF_COMMENT } from '../../../modules/local/maf-annotate/add_maf_comment'
include { ANNOTATE_FILTER_MAF_COLS } from '../../../modules/local/maf-annotate/filter_maf_cols'


workflow MAF_ANNOTATE {

    take:
    ch_maf                  // meta, path maf
    ch_impact_gene_list     // impact_gene_list path

    main:
    ch_versions = Channel.empty()

    ANNOTATE_ADD_MAF_COMMENT (
        ch_maf
    )

    ch_versions = ch_versions.mix(ANNOTATE_ADD_MAF_COMMENT.out.versions)

    ANNOTATE_ADD_AF (
        ANNOTATE_ADD_MAF_COMMENT.out.output_maf
    )

    ch_versions = ch_versions.mix(ANNOTATE_ADD_AF.out.versions)

    ANNOTATE_ADD_IS_IN_IMPACT (
        ANNOTATE_ADD_AF.out.output_maf,
        ch_impact_gene_list
    )

    ch_versions = ch_versions.mix(ANNOTATE_ADD_IS_IN_IMPACT.out.versions)

    ANNOTATE_FILTER_MAF_COLS (
        ANNOTATE_ADD_IS_IN_IMPACT.out.output_maf
    )

    ch_versions = ch_versions.mix(ANNOTATE_FILTER_MAF_COLS.out.versions)

    emit:
    maf = ANNOTATE_ADD_IS_IN_IMPACT.out.output_maf
    share_maf = ANNOTATE_FILTER_MAF_COLS.out.output_maf
    versions = ch_versions

}
