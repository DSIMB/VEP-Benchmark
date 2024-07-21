import sys
import gzip
dbnsfp_file = sys.argv[1]
script_folder = sys.argv[2]

with gzip.open(dbnsfp_file, "rt") as f:
    header = f.readline().split("\t")


header_score = [x for x in header if "_score" in x]
all_scores = header_score + ["CADD_raw", "Eigen-raw_coding", "Eigen-PC-raw_coding", "GERP++_RS",
                "phastCons100way_vertebrate", "phastCons470way_mammalian", "phastCons17way_primate", "SiPhy_29way_logOdds",
               "bStatistic"]


all_scores_modified = header_score + ["CADD_score", "Eigen_score", "Eigen-PC_score", "GERP++_score",
                "phastCons100way_vertebrate_score", "phastCons470way_mammalian_score", "phastCons17way_primate_score",
                                      "SiPhy_score", "bStatistic_score"]


final_header = ["genename", "aaref", "aapos",
                "aaalt", "#chr","pos(1-based)",
                "hg19_pos(1-based)", "ref",
                "alt"] + all_scores + ["gnomAD_exomes_AF"]

final_header_modified =  ["Gene", "aaref", "aapos",
                          "aaalt", "#chr","pos(1-based)",
                          "hg19_pos(1-based)", "ref",
                          "alt"] + all_scores_modified + ["gnomAD_exomes_AF"]


with open(f"{script_folder}/intermediate_files/header.txt", "w") as f:
    for x in header:
        f.write(f"{x}\n")


with open(f"{script_folder}/intermediate_files/final_header.txt", "w") as f:
    for x in final_header:
        f.write(f"{x}\n")


with open(f"{script_folder}/intermediate_files/final_header_modified.txt", "w") as f:
    for x in final_header_modified:
        f.write(f"{x}\n")

