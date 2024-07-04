import sys
import gzip
import os
from tqdm import tqdm
import time


def pattern_hash(file):
    dict_pattern = {}
    dict_chrom = {}
    with open(file) as filin:
        for line in filin:
            items = line.split()
            chr = items[0]
            if chr not in dict_chrom:
                dict_chrom[chr] = 0
            dict_chrom[chr] += 1
            pattern = "_".join(items)
            dict_pattern[pattern] = 0
    return dict_pattern, dict_chrom



if __name__ == "__main__":

    start_time = time.time()

    chr_number = sys.argv[1]
    pattern_file = sys.argv[2]

    if not os.path.exists(pattern_file):
        sys.exit("Invalid input file")
        
    output_file = f"{sys.argv[3]}.chr{chr_number}"

    chr_file = f"/dsimb/glaciere/radjasan/dbNSFP/academic/dbNSFP4.4a_variant.chr{chr_number}.gz"


    dict_search_pattern, dict_chrom = pattern_hash(pattern_file)
    if chr_number not in dict_chrom:
        sys.exit(f"Nothing to search in chromosome {chr_number}, skipping")

    N_to_search = dict_chrom[chr_number]
    done = 0

    print(f"Parsing chromosome {chr_number}")
    with gzip.open(chr_file, "rb") as db_file, open(output_file, "w") as fout:
        # Skip header
        db_file.readline()
        for line in db_file:
            try:
                line = line.decode('ascii')
            except:
                continue
            items = line.split()
            chr = items[0]
            nuc2 = items[3]
            nuc1 = items[2]

            # pos37 = items[8]
            # string37 = f"{chr}_{pos37}_{nuc1}_{nuc2}"

            pos38 = items[1]
            string38 = f"{chr}_{pos38}_{nuc1}_{nuc2}"
            
            if string38 in dict_search_pattern:
                fout.write(line)
                done += 1
                if done == N_to_search:
                    break

        print(f"Chr {chr_number} done")
