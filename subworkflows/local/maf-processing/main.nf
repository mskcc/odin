
include { VCF2MAF } from '../../../modules/local/vcf2maf/main'
include { REMOVE_VARIANTS } from '../../../modules/local/remove-variants/main'
include { NGS_FILTERS } from '../../../modules/local/ngs-filters/main'
include { FILLOUT as fillout_tumor_normal; FILLOUT as fillout_curated_bams} from '../../../modules/local/fillout/main'


workflow MAF_PROCESSING {

    take:
    ch_vcf                  // meta, path vcf
    ch_fasta_ref            // fasta path
    ch_fasta_fai_ref        // fasta_fai path
    ch_exac_filter          // exac_filter path
    ch_exac_index           // exac_filter index path
    ch_pair_bams            // pair bam list, pair bam index list
    ch_curated_bams         // currated bam list, currated bam index list

    main:
    ch_versions = Channel.empty()

    VCF2MAF (
        ch_vcf,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        ch_exac_filter,
        ch_exac_index
    )

    ch_versions = ch_versions.mix(VCF2MAF.out.versions)

    REMOVE_VARIANTS (
        VCF2MAF.out.maf
    )

    ch_versions = ch_versions.mix(REMOVE_VARIANTS.out.versions)

    ch_fillout_tm_input = join_maf_with_bams(REMOVE_VARIANTS.out.maf, ch_pair_bams)
    fillout_tm_input_curated_bam = Channel.value(false)

    fillout_tumor_normal(
        ch_fillout_tm_input,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        fillout_tm_input_curated_bam
    )

    ch_versions = ch_versions.mix(fillout_tumor_normal.out.versions)

    ch_fillout_curated_bam_input = join_maf_with_curated_bams(fillout_tumor_normal.out.maf, ch_curated_bams)
    fillout_curated_input_curated_bam = Channel.value(true)

    fillout_curated_bams(
        ch_fillout_curated_bam_input,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        fillout_curated_input_curated_bam
    )

    ch_versions = ch_versions.mix(fillout_curated_bams.out.versions)

    NGS_FILTERS (
        fillout_tumor_normal.out.maf,
        fillout_curated_bams.out.fillout
    )

    ch_versions = ch_versions.mix(NGS_FILTERS.out.versions)


    emit:
    maf = NGS_FILTERS.out.maf
    portal_fillout = NGS_FILTERS.out.maf
    versions = ch_versions

}

def join_maf_with_bams(maf,bams) {
        maf_channel = maf
            .map{
                new Tuple(it[0].id,it)
                }
        bams_channel = bams
            .map{
                new Tuple(it[0].id,it)
                }
        mergedWithKey = maf_channel
            .join(bams_channel)
        merged = mergedWithKey
            .map{
                new Tuple(it[1][0],it[1][1],it[2][1],it[2][2])
            }
        return merged

}

def join_maf_with_curated_bams(maf,bams) {
        bam_list = bams
            .map{
                it[1]
            }
            .collect()

        bai_list = bams
            .map{
                it[2]
            }
            .collect()

        merged = maf
            .map{
                new Tuple(it[0], it[1], bam_list.get(), bai_list.get())
            }

        return merged

}

