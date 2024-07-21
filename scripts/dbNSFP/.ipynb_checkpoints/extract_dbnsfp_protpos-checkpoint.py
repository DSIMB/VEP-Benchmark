import sys
import gzip
from tqdm import tqdm
import os
import time


def pattern_hash(file):
    dict_pattern = {}
    with open(file) as filin:
        for line in filin:
            pattern = line.split()[1]
            dict_pattern[pattern] = 0
    return dict_pattern



if __name__ == "__main__":

    start_time = time.time()

    chr_number = sys.argv[1]
    pattern_file = sys.argv[2]
    if not os.path.exists(pattern_file):
        sys.exit("Invalid input file")
    output_file = f"{sys.argv[3]}.chr{chr_number}"

    chr_file = f"/dsimb/glaciere/radjasan/dbNSFP/academic/dbNSFP4.4a_variant.chr{chr_number}.gz"

    print(chr_file, pattern_file, output_file)
    # pattern_file = "/dsimb/wasabi/radjasan/these/benchmark/scripts/dbNSFP/test_db.txt"
    # output_file = "/dsimb/wasabi/radjasan/these/benchmark/scripts/dbNSFP/output_db.txt"

    dict_search_pattern = pattern_hash(pattern_file)
    with gzip.open(chr_file, "rb") as db_file, open(output_file, "w") as fout:
        db_file.readline()
        for line in tqdm(db_file):
            try:
                line = line.decode('ascii')
            except:
                continue
            items = line.split()
            res1 = items[4]
            res2 = items[5]
            res_pos = items[7]  
            gene = items[12]
            string38 = f"{res1}{res_pos}{res2}"
            if ";" in gene:
                list_gene = gene.split(";")
            else:
                list_gene = [gene]
            
            if "CYP2C9" in list_gene and string38 in dict_search_pattern:
                fout.write(line)


    print(f"Chr {chr_number} done in {time.time() - start_time}")
