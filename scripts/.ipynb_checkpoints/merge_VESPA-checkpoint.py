import sys
import gzip
from tqdm import tqdm
import os
import time
from joblib import Parallel, delayed

def pattern_hash(file):
    dict_pattern = {}
    with open(file) as filin:
        for line in tqdm(filin, total=767020):
            items = line.split()
            gene, var = line.split()
            pattern = f"{gene}_{var}"
            dict_pattern[pattern] = 0
    return dict_pattern


def read_idvar_databases(database, dict_search_pattern, database_file, output_directory):

    output_file = f"{output_directory}/{database}/{database}_predictions2.tsv"
    total_databases = {"VESPA":94464841}
    
    total = total_databases[database]

    if "gz" in database_file:
        mode = "rt"
        open_fun = gzip.open
    else:
        mode= "r"
        open_fun = open

    with open_fun(database_file, mode, encoding='utf-8') as db_file, open(output_file, "w") as fout:
        for line in tqdm(db_file, total=total):
            if line.startswith("#"):
                continue

            items = line.split()
            ID = items[0]
            var = items[1]    
            res1 = var[0]
            res2 = var[-1]
            position = int(var[1:-1]) + 1
            new_var = f"{res1}{position}{res2}"
            string = f"{ID}_{new_var}"

            if string in dict_search_pattern:    
                new_line = f"{ID}\t{new_var}\t{items[-1]}\n"
                fout.write(new_line)


if __name__ == "__main__":

    # Folder with input_files and tools folders
    input_directory = sys.argv[1]

    database_directory = "/home/wasabi/radjasan/these/benchmark/variant_databases/"

    start_time = time.time()
    

    gene_var_tab_input = f"{input_directory}/input_files/gene_var_tab.txt"
    VESPA_file = "/home/wasabi/radjasan/these/benchmark/VUS/tools/VESPA/VESPA_predictions_part2.tsv"

    output_directory = f"{input_directory}/tools/"

    dict_pattern_VESPA = pattern_hash(gene_var_tab_input)
    read_idvar_databases("VESPA", dict_pattern_VESPA, VESPA_file, output_directory)

   



