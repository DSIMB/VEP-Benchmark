import sys
import os
import time
import argparse
from joblib import Parallel, delayed
import pysam

def get_args():
    parser = argparse.ArgumentParser(description='Generating input files needed to retrieve predictions from Variant Effect Predictors')
    parser.add_argument('-f', '--file',
                        help="Path to file containing genomic positions",
                        required=True, type=str)
    parser.add_argument('-o', '--output_file',
                        help="Path to file to create",
                        default="./predictions/dbNSFP/dbNSFP_output.tsv",
                        required=False, type=str)
    parser.add_argument('-r', '--reference',
                        help="Choose the reference genome to consider between 38 and 37 (default:38)",
                        default="38",
                        required=False, type=str)
    parser.add_argument('-d', '--data_path',
                        help="Path to directory containing all dbNSFP files",
                        default="/dsimb/glaciere/radjasan/dbNSFP/academic/",
                        required=False, type=str)
    args = parser.parse_args()

    variant_file = args.file
    if not os.path.exists(variant_file):
        sys.exit(f"[dbNSFP] Variant file '{variant_file}' does not exists. Please provide an existing one.")
    return args

def pattern_hash(file):
    dict_chrom = {}
    with open(file) as filin:
        for line in filin:
            chr = line.split(":")[0]
            if chr not in dict_chrom:
                dict_chrom[chr] = 0
            dict_chrom[chr] += 1
    return  dict_chrom



def process_one_chr(chromosome, args):
    print(f"[dbNSFP] Parsing chromosome {chromosome}")
    input_file = args.file
    output_file = args.output_file
    reference_genome = args.reference
    path_data = args.data_path

    fulloutput_file = f"{output_file}.chr{chromosome}"

    chr_file = f"{path_data}/dbNSFP4.4a_variant.chr{chromosome}.gz"
    
    if reference_genome == "38":
        index_file = f"{path_data}/tabix_38/dbNSFP4.4a_variant.chr{chromosome}.gz.tbi"
    else:
        index_file = f"{path_data}/tabix_37/dbNSFP4.4a_variant.chr{chromosome}.gz.tbi"

    print(index_file, fulloutput_file)
    tabix_file = pysam.TabixFile(chr_file, index=index_file, encoding="utf8")

    with open(input_file) as in_file, open(fulloutput_file, "w") as fout:
        for line in in_file:
            if line.split(":")[0] != chromosome:
                continue
            items = line.split()
            region = items[0]
            nuc1 = items[1]
            nuc2 = items[2]
            for record in tabix_file.fetch(region=region):
                items_record = record.split()
                nuc1_record = items_record[2]
                nuc2_record = items_record[3]
                if nuc1 == nuc1_record and nuc2 == nuc2_record:
                    fout.write(record)
    print(f"[dbNSFP] Chr{chromosome} done")

if __name__ == "__main__":

    start_time = time.time()
    args = get_args()
    output_folder = os.path.dirname(args.output_file)
    os.makedirs(output_folder, exist_ok=True)
    pattern_file = args.file
    dict_chrom = pattern_hash(pattern_file)
    Parallel(n_jobs = len(dict_chrom), prefer="processes")(delayed(process_one_chr)(chromosome, \
                                                                     args) for chromosome in dict_chrom)
