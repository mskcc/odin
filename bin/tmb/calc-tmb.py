#!/usr/bin/env python3

### Source: https://github.com/mskcc/odin-tmb/blob/master/compute-tmb.py

import json
import argparse
import sys

try:
    # from pandas import read_csv as read_csv
    import pandas as pd
except:
    sys.exit('Pandas is required')

"""
Script to calculated tmb, intended to take analysis.maf
 usage:
     compute-tmb inputMaf outputFile tumorId assay normalType

     Assay should be one of from assayDb file
     normalType: Can be matched or unmatched. Unmatched will return NA as tmb value
     matched to POOLEDNORMAL is considered unmatched
"""

def write_output(output_filename,tmb_score,sampleId):
    output_message = 'CMO_TMB_SCORE\tSAMPLE_ID\n'+ str(tmb_score)+'\t'+sampleId+'\n'
    open(output_filename,'w').write(output_message)
    return


def main():
    """
    Script to calculate TMB (tumor mutational burden) value
    """
    parser = argparse.ArgumentParser(description='Script to calculate TMB (tumor mutational burden) value')
    parser.add_argument("--maf_file",         required=True, dest = 'maf_file',         help="Input maf file")
    parser.add_argument("--output_filename",  required=False,dest = 'output_filename',  help="output_filename")
    parser.add_argument("--tumorId",          required=True, dest = 'tumorId',          help="tumorId")
    parser.add_argument("--assay",            required=True, dest = 'assay',            help="Assay should be one of from assayDb file'")
    parser.add_argument("--normalType",       required=True, dest = 'normalType',       help="normalType: matched/unmatched. Unmatched will return NA")
    parser.add_argument("--assayDb_file",     required=False,dest = 'assayDb_file', default = 'data/tmbAssayDb.json', help="assayDb_file")

    args = parser.parse_args()

    if args.normalType.lower() == 'unmatched':
        write_output(args.output_filename,'NA',args.tumorId)
        sys.exit(0)
    elif args.normalType.lower() == 'matched':
        print('Calculating TMB')
    else:
        print('normalType should be matched or unmatched')
        sys.exit('normalType should be matched or unmatched')

    try:
        with open(args.assayDb_file, 'r') as f:
            assayDb = json.load(f)
    except:
        print('Error: This assayDb_file file can not be found:',args.assayDb_file)
        sys.exit('Error: This assayDb_file file can not be found: '+args.assayDb_file)

    if not args.assay in assayDb:
        write_output(args.output_filename,'NA',args.tumorId)
        sys.exit(0)

    maf_df = pd.read_csv(args.maf_file, sep='\t',comment='#',usecols=['Tumor_Sample_Barcode', 'Hugo_Symbol'])

    # we get matched and unmatched mixed project, below requires additional input file, may turn on later
    # if args.tumorId == 'ALL':
    #     #Note that if a sample in the project had no mutations, running it self will give 0 tmb value but it won't be included in ALL mode
    #     print('All samples mode')
    #     mutations_counts=maf_df[ (maf_df['Hugo_Symbol'].isin(assayDb[args.assay]['genes']))]['Tumor_Sample_Barcode'].value_counts()
    #     result_df=pd.DataFrame({'CMO_TMB_SCORE': mutations_counts.values/assayDb[args.assay]['genomicSize']*1000000,
    #                             'SAMPLE_ID':mutations_counts.index})

    #     result_df.round(2).to_csv(args.output_filename, index=False, sep='\t')
    #     print('Done')
    #     sys.exit(0)

    filtered_maf_df=maf_df[ (maf_df['Tumor_Sample_Barcode'] == args.tumorId)  &
                            (maf_df['Hugo_Symbol'].isin(assayDb[args.assay]['genes']))
                            ] #only filtering out genes that are not included in the assay panel

    number_of_mutataions=maf_df.shape[0]
    number_of_on_target_mutataions=filtered_maf_df.shape[0]
    number_of_discarded=number_of_mutataions-number_of_on_target_mutataions
    tmb_val=round(number_of_on_target_mutataions/assayDb[args.assay]['genomicSize']*1000000,2)

    print('Total number of mutations for this sample:',number_of_mutataions)
    print('Number of on-target mutations:',number_of_on_target_mutataions)
    print('Number of off-target mutations:',number_of_discarded)
    print('TMB values is calculated by Number of on-target mutations/Assay length*1,000,000')
    print('TMB value:',tmb_val)

    if args.output_filename is not None:
        write_output(args.output_filename,tmb_val,args.tumorId)

if __name__ == '__main__':
    main()
