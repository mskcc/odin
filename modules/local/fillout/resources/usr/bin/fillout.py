#!/usr/bin/env python
##########################################################################################
# MSKCC CMO
descr = 'Fillout allele counts for a MAF file using GetBaseCountsMultiSample on BAMs'
##########################################################################################
import os, sys, argparse, csv, subprocess, string, uuid, cmo, pysam
parser = argparse.ArgumentParser(description = descr, formatter_class = argparse.RawTextHelpFormatter)
parser.add_argument('-m', '--maf', help = 'MAF file on which to fillout', required = True)
parser.add_argument('-b', '--bams', help = 'BAM files to fillout with', required = False, nargs='+')
parser.add_argument('-g', '--genome', help = 'Reference assembly name of BAM files', default = "GRCh37", required = False, choices = cmo.util.genomes.keys())
parser.add_argument('-r', '--ref-fasta', help = 'Reference assembly file of BAM files', required = False)
parser.add_argument('-o', '--output', help = 'Filename for output of raw fillout data in MAF/VCF format', required = False)
parser.add_argument('-f', '--format', help = 'Output format MAF(1) or tab-delimited with VCF based coordinates(2)', default = 1, required = False)
parser.add_argument('-p', '--portal-output', help = 'Filename for a portal-friendly output MAF', required = False)
parser.add_argument('-P', '--pairing-file', help = 'Tab separated pairing file, normal tumor', required = False)
parser.add_argument('-F', '--fillout', help = 'Precomputed fillout file from GBCMS (using this skips GBCMS)', required = False)
parser.add_argument('-n', '--n_threads', help = 'Multithreaded GBCMS', default = 8, required = False)
parser.add_argument("-v", '--version', help = 'Version of GBCMS to use to count with...', default = "1.2.2", choices=cmo.util.programs['getbasecountsmultisample'].keys())
args = parser.parse_args()
samtools = cmo.util.programs['samtools']['default']
maf = args.maf
if args.bams is None and args.fillout is None:
    print >> sys.stderr, "ERROR: Please define either --bams or --fillout"
    sys.exit(1)
if args.output is None:
    output = os.path.splitext(os.path.basename(maf))[0]+'.fillout'
else:
    output = args.output
if args.portal_output is None:
    portal_output = os.path.splitext(os.path.basename(maf))[0]+'.fillout.portal.maf'
else:
    portal_output = args.portal_output

### Path to GetBaseCountsMultiSample binary and the reference genome FASTA
gbcmPath = cmo.util.programs['getbasecountsmultisample'][args.version]
if args.ref_fasta != None:
    genomePath = args.ref_fasta
else:
    genomePath = cmo.util.genomes[args.genome]['fasta']
### Extract sample IDs from BAMs unless user provided a GBCMS precomputed fillout
bamString = []
samplelist = list()
dedupBams = dict() # To deduplicate BAMs with the same sample IDs
if args.fillout is None:
    for bam in args.bams:
        sam = pysam.AlignmentFile(bam, "rb" )
        sample_id = sam.header['RG'][0]['SM']
        if sample_id not in samplelist:
            samplelist.append(sample_id)
        sam.close()
        if sample_id not in dedupBams:
            bamString.append('--bam '+sample_id+':'+bam)
        dedupBams[sample_id] = 1
    bamString = string.join(bamString)
### Check if MAF has right genome
mafGenome = subprocess.check_output('grep -v ^# '+maf+' | tail -n1 | cut -f4', shell = True).rstrip()
if mafGenome != args.genome:
    print 'Warning: Argument --genome '+args.genome+' differs from NCBI_Build '+mafGenome+' in MAF file'

### Make a temporary MAF with events deduplicated by genomic loci and ref/alt alleles
tmpMaf = uuid.uuid4().hex+'_tmp.maf'

fh = open(maf, "rb")
reader = csv.DictReader(filter(lambda row: row[0]!='#',fh), delimiter="\t")
header = reader.fieldnames
dedup = dict() # To deduplicate events by genomic loci and ref/alt alleles for use by GBCMS
called = dict() # To lookup events that were called in the input MAF
pair = dict() # To lookup matched normal barcodes for a given tumor sample ID
for line in reader:
    if not line['Tumor_Seq_Allele2'] or line['Reference_Allele'] == line['Tumor_Seq_Allele2']: continue # Fix for rare non-events
    key = ' '.join([ line['Chromosome'], line['Start_Position'], line['End_Position'], line['Reference_Allele'], line['Tumor_Seq_Allele2'] ])
    dedup[key] = line
    # key = ' '.join([ key, line['Tumor_Sample_Barcode'] ])
    key = ' '.join([ line['Chromosome'], line['Start_Position'], line['End_Position'], line['Reference_Allele'], line['Tumor_Seq_Allele2'],line['Tumor_Sample_Barcode'] ])
    called[key] = line
    pair[line['Tumor_Sample_Barcode']] = line['Matched_Norm_Sample_Barcode']
fh.close()
tmpfh = open(tmpMaf, "w")
writer = csv.DictWriter(tmpfh, delimiter="\t", quoting=csv.QUOTE_NONE, fieldnames=header, lineterminator='\n')
writer.writeheader()
for (key, line) in dedup.items():
    writer.writerow(line)
tmpfh.close()

### Call GetBaseCountsMultiSample unless user provided a precomputed fillout
if args.fillout is None:
    gbcmCall = None
    if(int(args.format) == 1):
        gbcmCall = gbcmPath+' --omaf --maq 20 --baq 20 --filter_improper_pair 0 --thread %s --fasta %s --maf %s --output %s %s' % (args.n_threads, genomePath, tmpMaf, output, bamString)
    else:
        gbcmCall = gbcmPath+' --maq 20 --baq 20 --filter_improper_pair 0 --thread %s --fasta %s --maf %s --output %s %s' % (args.n_threads, genomePath, tmpMaf, output, bamString)
    print(gbcmCall)
    subprocess.call(gbcmCall, shell = True)
else:
    print "Using precomputed " + args.fillout + " to generate portal friendly MAF " + portal_output
    output = args.fillout

### Create a portal-friendly MAF where Mutation_Status=None for events absent in the input MAF
if(int(args.format) == 1):
    if args.pairing_file: #pairing mode
        # Assumption:pairing list will always be the normal sample in the first column, and its respective tumor in second column
        print '-----=====pairing mode======-----'
        pairing_list = []
        normlist = []
        tumorlist = []
        with open(args.pairing_file,'r') as pf:
            for i in pf.readlines():
                normal,tumor = i.rstrip().split('\t')
                pairing_list.append((normal,tumor))
                normlist.append(normal)
                tumorlist.append(tumor)
        portaldict = {}
        orderlist = []
        with open(output,'rb') as ofh:
            reader = csv.DictReader(filter(lambda row: row[0]!='#',ofh), delimiter="\t")
            for line in reader:
                if line['Tumor_Sample_Barcode'] in samplelist:
                    samplekey = ' '.join([ line['Chromosome'], line['Start_Position'], line['End_Position'], line['Reference_Allele'], line['Tumor_Seq_Allele1'], line['Tumor_Sample_Barcode'] ])
                    key = ' '.join([ line['Chromosome'], line['Start_Position'], line['End_Position'], line['Reference_Allele'], line['Tumor_Seq_Allele1']])
                    portaldict[samplekey] = line
                    if key not in orderlist:
                        orderlist.append(key)
        ofh = open(output, "rb")
        pfh = open(portal_output, "w")
        reader = csv.DictReader(filter(lambda row: row[0]!='#',ofh), delimiter="\t")
        #instantiate new fields here
        new_header_list = ['fillout_t_depth','fillout_t_ref','fillout_t_alt','fillout_t_forward_depth','fillout_t_forward_ref','fillout_t_forward_alt','fillout_t_reverse_depth','fillout_t_reverse_ref','fillout_t_reverse_alt','fillout_n_depth','fillout_n_ref','fillout_n_alt','fillout_n_forward_depth','fillout_n_forward_ref','fillout_n_forward_alt','fillout_n_reverse_depth','fillout_n_reverse_ref','fillout_n_reverse_alt' ]
        header.extend(new_header_list)
        if 'n_depth' not in header:
            header.append('n_depth')
        writer = csv.DictWriter(pfh, delimiter="\t", quoting=csv.QUOTE_NONE, fieldnames=header, lineterminator='\n')
        writer.writeheader()
        for linekey in orderlist:
            for normal, tumor in pairing_list:
                if normal in samplelist and tumor in samplelist:
                    tumor_samplekey =  ' '.join([ linekey, tumor ])
                    normal_samplekey = ' '.join([ linekey, normal ])
                    # Fetch the full line from the input MAF, and replace sample IDs and allele counts
                    tumor_line = portaldict[tumor_samplekey]
                    normal_line = portaldict[normal_samplekey]
                    full_line1 = dict()
                    if tumor_samplekey in called:
                        for tag in header:
                            if tag not in new_header_list:
                                full_line1[tag] = called[tumor_samplekey][tag]
                    else:
                        for tag in header:
                            if tag not in new_header_list:
                                if tag in dedup[linekey]:
                                    full_line1[tag] = dedup[linekey][tag] #borrow the same fields
                    #the tumor sample has a position tha
                    # if full_line1['Matched_Norm_Sample_Barcode'] != normal:
                    #     pass
                        # print 'Warning: ' + full_line1['Matched_Norm_Sample_Barcode'] + ' will be ovewritten by ' + normal
                    full_line1['Matched_Norm_Sample_Barcode'] = normal
                    full_line1['Tumor_Sample_Barcode'] = tumor

                    # fillout calculations for forward and reverse
                    tumor_total = int(tumor_line['t_total_count'])
                    tumor_ref = int(tumor_line['t_ref_count'])
                    tumor_alt = int(tumor_line['t_alt_count'])
                    tumor_total_forward = int(tumor_line['t_total_count_forward'])
                    tumor_ref_forward = int(tumor_line['t_ref_count_forward'])
                    tumor_alt_forward = int(tumor_line['t_alt_count_forward'])
                    tumor_total_reverse = tumor_total - tumor_total_forward
                    tumor_ref_reverse = tumor_ref - tumor_ref_forward
                    tumor_alt_reverse = tumor_alt - tumor_alt_forward
                    normal_total = int(normal_line['t_total_count'])
                    normal_ref = int(normal_line['t_ref_count'])
                    normal_alt = int(normal_line['t_alt_count'])
                    normal_total_forward = int(normal_line['t_total_count_forward'])
                    normal_ref_forward = int(normal_line['t_ref_count_forward'])
                    normal_alt_forward = int(normal_line['t_alt_count_forward'])
                    normal_total_reverse = normal_total - normal_total_forward
                    normal_ref_reverse = normal_ref - normal_ref_forward
                    normal_alt_reverse = normal_alt - normal_alt_forward
                    #tumor fillout counts
                    full_line1['fillout_t_depth'] = str(tumor_total)
                    full_line1['fillout_t_ref'] = str(tumor_ref)
                    full_line1['fillout_t_alt'] = str(tumor_alt)
                    full_line1['fillout_t_forward_depth'] = str(tumor_total_forward)
                    full_line1['fillout_t_forward_ref'] = str(tumor_ref_forward)
                    full_line1['fillout_t_forward_alt'] = str(tumor_alt_forward)
                    full_line1['fillout_t_reverse_depth'] = str(tumor_total_reverse)
                    full_line1['fillout_t_reverse_ref'] = str(tumor_ref_reverse)
                    full_line1['fillout_t_reverse_alt'] = str(tumor_alt_reverse)
                    #normal fillout counts
                    full_line1['fillout_n_depth'] = str(normal_total)
                    full_line1['fillout_n_ref'] = str(normal_ref)
                    full_line1['fillout_n_alt'] = str(normal_alt)
                    full_line1['fillout_n_forward_depth'] = str(normal_total_forward)
                    full_line1['fillout_n_forward_ref'] = str(normal_ref_forward)
                    full_line1['fillout_n_forward_alt'] = str(normal_alt_forward)
                    full_line1['fillout_n_reverse_depth'] = str(normal_total_reverse)
                    full_line1['fillout_n_reverse_ref'] = str(normal_ref_reverse)
                    full_line1['fillout_n_reverse_alt'] = str(normal_alt_reverse)

                    # For all events retain allele counts from the caller, otherwise use the fillout to backfill
                    if tumor_samplekey not in called or not full_line1['t_alt_count']:  # if columns 40-45 are empty, use fillout to backfill
                        full_line1['t_alt_count'] = tumor_line['t_alt_count']
                        full_line1['t_ref_count'] = tumor_line['t_ref_count']
                        full_line1['t_depth'] = tumor_line['t_total_count']
                        full_line1['n_alt_count'] = normal_line['t_alt_count']
                        full_line1['n_ref_count'] = normal_line['t_ref_count']
                        full_line1['n_depth'] = normal_line['t_total_count']
                    # Set Mutation_Status to None for variants that were not called in the input MAF
                    if tumor_samplekey not in called:
                        full_line1['Mutation_Status'] = "None"
                        # Also blank out most annotations for these non-calls to keep the file size small
                        for tag in "HGVSc HGVSp Transcript_ID Exon_Number all_effects Allele Feature Feature_type cDNA_position CDS_position Protein_position Amino_acids Codons Existing_variation ALLELE_NUM DISTANCE STRAND_VEP STRAND SYMBOL SYMBOL_SOURCE HGNC_ID BIOTYPE CANONICAL CCDS ENSP SWISSPROT TREMBL UNIPARC RefSeq SIFT PolyPhen EXON INTRON DOMAINS GMAF AFR_MAF AMR_MAF ASN_MAF EAS_MAF EUR_MAF SAS_MAF AA_MAF EA_MAF CLIN_SIG SOMATIC PUBMED MOTIF_NAME MOTIF_POS HIGH_INF_POS MOTIF_SCORE_CHANGE IMPACT PICK VARIANT_CLASS TSL HGVS_OFFSET PHENO MINIMISED ExAC_AF_AFR ExAC_AF_AMR ExAC_AF_EAS ExAC_AF_FIN ExAC_AF_NFE ExAC_AF_OTH ExAC_AF_SAS GENE_PHENO variant_id variant_qual ExAC_AF_Adj ExAC_AC_AN_Adj ExAC_AC_AN ExAC_AC_AN_AFR ExAC_AC_AN_AMR ExAC_AC_AN_EAS ExAC_AC_AN_FIN ExAC_AC_AN_NFE ExAC_AC_AN_OTH ExAC_AC_AN_SAS ExAC_FILTER set".split():
                            if tag in header:
                                full_line1[tag] = ""
                    writer.writerow(full_line1)
        ofh.close()
        pfh.close()

    else:
        ofh = open(output, "rb")
        pfh = open(portal_output, "w")
        reader = csv.DictReader(filter(lambda row: row[0]!='#',ofh), delimiter="\t")
        writer = csv.DictWriter(pfh, delimiter="\t", quoting=csv.QUOTE_NONE, fieldnames=header, lineterminator='\n')
        writer.writeheader()
        # ::TODO:: Also fillout counts from the matched normals into n_alt_count, n_ref_count, n_depth
        for line in reader:
            key =' '.join([ line['Chromosome'], line['Start_Position'], line['End_Position'], line['Reference_Allele'], line['Tumor_Seq_Allele1'] ])
            # Fetch the full line from the input MAF, and replace sample IDs and allele counts
            full_line = dict()
            for tag in header:
                full_line[tag] = dedup[key][tag]
            sample_id = line['Tumor_Sample_Barcode']
            full_line['Tumor_Sample_Barcode'] = sample_id
            full_line['Matched_Norm_Sample_Barcode'] = "NORMAL"
            if sample_id in pair:
                full_line['Matched_Norm_Sample_Barcode'] = pair[sample_id]
            # For indels and MNPs, retain allele counts from the caller, if available
            key = ' '.join([ key, sample_id ])
            if full_line['Variant_Type'] == "SNP" or key not in called or not full_line['t_alt_count']:
                full_line['t_alt_count'] = line['t_alt_count']
                full_line['t_ref_count'] = line['t_ref_count']
                full_line['t_depth'] = line['t_total_count']
            # Set Mutation_Status to None for variants that were not called in the input MAF
            if key not in called:
                full_line['Mutation_Status'] = "None"
                # Also blank out most annotations for these non-calls to keep the file size small
                for tag in "HGVSc HGVSp Transcript_ID Exon_Number n_depth n_ref_count n_alt_count all_effects Allele Feature Feature_type cDNA_position CDS_position Protein_position Amino_acids Codons Existing_variation ALLELE_NUM DISTANCE STRAND_VEP STRAND SYMBOL SYMBOL_SOURCE HGNC_ID BIOTYPE CANONICAL CCDS ENSP SWISSPROT TREMBL UNIPARC RefSeq SIFT PolyPhen EXON INTRON DOMAINS GMAF AFR_MAF AMR_MAF ASN_MAF EAS_MAF EUR_MAF SAS_MAF AA_MAF EA_MAF CLIN_SIG SOMATIC PUBMED MOTIF_NAME MOTIF_POS HIGH_INF_POS MOTIF_SCORE_CHANGE IMPACT PICK VARIANT_CLASS TSL HGVS_OFFSET PHENO MINIMISED ExAC_AF_AFR ExAC_AF_AMR ExAC_AF_EAS ExAC_AF_FIN ExAC_AF_NFE ExAC_AF_OTH ExAC_AF_SAS GENE_PHENO variant_id variant_qual ExAC_AF_Adj ExAC_AC_AN_Adj ExAC_AC_AN ExAC_AC_AN_AFR ExAC_AC_AN_AMR ExAC_AC_AN_EAS ExAC_AC_AN_FIN ExAC_AC_AN_NFE ExAC_AC_AN_OTH ExAC_AC_AN_SAS ExAC_FILTER set".split():
                    if tag in header:
                        full_line[tag] = ""
            writer.writerow(full_line)
        ofh.close()
        pfh.close()

### Remove temporary MAFs
subprocess.call('rm -f '+tmpMaf, shell = True)
