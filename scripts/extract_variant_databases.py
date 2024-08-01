import gzip
import os
import time
from joblib import Parallel, delayed
import h5py
import argparse
import pysam
import sys


def get_args():
    parser = argparse.ArgumentParser(description='Generating input files needed to retrieve predictions from Variant Effect Predictors')
    parser.add_argument('-d', '--directory',
                        help="Path to file containing genomic positions",
                        required=True, type=str)
    parser.add_argument('--databases',
                        help="Path to file to create",
                        required=True, type=str)
    
    parser.add_argument('--cpus',
                        help="Path to file to create",
                        default=-1,
                        required=False, type=int)
    args = parser.parse_args()
    return args


def pattern_hash(file):
    dict_pattern = {}
    with open(file) as filin:
        for line in filin:
            pattern = "_".join(line.split())
            dict_pattern[pattern] = 0
    return dict_pattern

def pattern_evecpt(file, database):
    dict_pattern = {}
    with open(file) as filin:
        for line in filin:
            items = line.split()
            gene = items[0]
            entry = items[1]
            variation = items[2]
            res1 = variation[0]
            res2 = variation[-1]
            pos = variation[1:-1]
            if entry not in dict_pattern:
                dict_pattern[entry] = {}
            value_dict = variation
            dict_pattern[entry][value_dict] = gene
    return dict_pattern


def read_evecpt(database, dict_search_pattern, database_directory, predictions_directory):
    output_file = f"{predictions_directory}/{database}/{database}_predictions.tsv"
    if os.path.exists(output_file):
        os.remove(output_file)
    for entry in dict_search_pattern:
        file_predictions = f"{database_directory}/{database}/proteome/{entry}.csv.gz"
        if not os.path.exists(file_predictions):
            continue
        with gzip.open(file_predictions, "rt", encoding='utf-8') as db_file, open(output_file, "a") as fout:
            for line in db_file:
                items = line.split(",")
                variation = items[0]
                if variation in dict_search_pattern[entry]:
                    gene = dict_search_pattern[entry][variation]
                    new_line = f"{gene}\t{items[0]}\t{items[1]}"
                    fout.write(new_line)

def read_vespa(id_var_file, database_file, predictions_directory):
    dict_aa = {}
    for i, aa in enumerate("ALGVSREDTIPKFQNYMHWC"):
        dict_aa[aa] = i

    with open(id_var_file) as file_input, open(f"{predictions_directory}/VESPA/VESPA_predictions.tsv", "w") as file_out, \
            h5py.File(database_file, "r") as vespa_file:
        
        input_content = file_input.readlines()
        for line_input in input_content:
            items_input = line_input.split()
            ID = items_input[0]
            var = items_input[1]
            res_mut = var[-1]
            res_pos = int(var[1:-1])
            if res_mut not in dict_aa:
                continue
            index_pos = dict_aa[res_mut]
            index_sequence = res_pos - 1
            try:
                vespa_score = vespa_file[ID]["VESPAl"][index_sequence, index_pos]
            except:
                vespa_score = "."
            new_line = f'{ID}\t{var}\t{vespa_score}\n'
            file_out.write(new_line)


def read_esm1b(id_var_file, database_directory, predictions_directory):
    with open(id_var_file) as file_input, open(f"{predictions_directory}/ESM1b/ESM1b_predictions.tsv", "w") as file_out:
        input_content = file_input.readlines()
        for line_input in input_content:
            items_input = line_input.split()
            ID = items_input[0]
            var = items_input[1]
            res_mut = var[-1]
            res_pos = int(var[1:-1])

            database_file = f"{database_directory}/ESM1b/content/ALL_hum_isoforms_ESM1b_LLR/{ID}_LLR.csv"
            if not os.path.exists(database_file):
                # print(database_file, 'does not exists')
                continue
            with open(database_file) as db_file:
                for line in db_file:
                    if line[0] != res_mut:
                        continue
                    items = line.split(",")
                    try:
                        esm_score = items[res_pos]
                    except:
                        esm_score = "."

                    new_line = f'{ID}\t{var}\t{esm_score}\n'
                    file_out.write(new_line)


# def read_idvar_databases(database, dict_search_pattern, database_file, predictions_directory):
#     start_time = time.time()
#     output_file = f"{predictions_directory}/{database}/{database}_predictions.tsv"
#     if "gz" in database_file:
#         mode = "rt"
#         open_fun = gzip.open
#     else:
#         mode= "r"
#         open_fun = open

#     with open_fun(database_file, mode, encoding='utf-8') as db_file, open(output_file, "w") as fout:
#         for line in db_file:
#             if line.startswith("#") or line.startswith("UniProt"):
#                 continue
#             items = line.split()
#             ID = items[0]
#             var = items[1]
#             if database in ["Envision", "DeepSAV"]:
#                 score = items[-1]
#                 string = f"{ID}_{var}"
#             elif database == "PONP2":
#                 ID = items[-1]
#                 var = items[2]
#                 string = items[0]
#                 score = items[3]
#             if string in dict_search_pattern and dict_search_pattern[string] == 0:
#                 new_line = f"{ID}\t{var}\t{score}\n"
#                 fout.write(new_line)
#                 dict_search_pattern[string] = 1
#     print("TIME", database, time.time() - start_time)


def load_index(index_file):
    with open(index_file, 'r') as f:
        index = {protein_id: int(offset) for protein_id, offset in 
                 (line.strip().split() for line in f)}
    return index

def read_idvar_databases(database, dict_search_pattern, database_file, predictions_directory):
    output_file = f"{predictions_directory}/{database}/{database}_predictions.tsv"
    if "gz" in database_file:
        mode = "rt"
        open_fun = gzip.open
    else:
        mode= "r"
        open_fun = open

    index_file = f"{database_file}.tbi"
    index = load_index(index_file)
    queries = list(dict_search_pattern.keys())
    prot_done = {}
    with open_fun(database_file, mode, encoding='utf-8') as db_file, open(output_file, "w") as fout:
        for query in queries:
            protein_id, variation = query.split("_")
            if protein_id in prot_done:
                continue
            if protein_id in index:
                db_file.seek(index[protein_id])
                for line in db_file:
                    line = line.strip()
                    items = line.split()
                    record_protein_id = items[0]
                    var = items[1]
                    record_variation = f"{record_protein_id}_{var}"
                    score = items[-1]
                    if record_variation in dict_search_pattern and dict_search_pattern[record_variation] == 0:
                        new_line = f"{record_protein_id}\t{var}\t{score}\n"
                        fout.write(new_line)
                        dict_search_pattern[record_variation] = 1
                    elif record_protein_id != protein_id:
                        prot_done[protein_id] = 0
                        break


def read_genomics_databases(input_file, database, database_file, predictions_directory):
    output_file = f"{predictions_directory}/{database}/{database}_predictions.tsv"
    tabix_file = pysam.TabixFile(database_file)
    with open(input_file, encoding='utf-8') as in_file, open(output_file, "w") as fout:
        for line in in_file:
            items = line.split()
            region = items[0]
            nuc1 = items[1]
            nuc2 = items[2]
            for record in tabix_file.fetch(region=region):
                items_record = record.split()
                chrom_record = items_record[0]
                pos_record = items_record[1]
                nuc1_record = items_record[2]
                nuc2_record = items_record[3]
                if nuc1 == nuc1_record and nuc2 == nuc2_record:
                    if database == "SIGMA":
                        score = items_record[-2]
                    elif database == "InMeRF":
                        score = items_record[-1]
                    else:
                        score = items_record[4]
                    new_line = f"{chrom_record}\t{pos_record}\t{nuc1_record}\t{nuc2_record}\t{score}\n"
                    fout.write(new_line)


def run_one_db(predictions_directory, database, dict_databases, database_directory):
    os.makedirs(f"{predictions_directory}/{database}", exist_ok=True)
    input_file, database_file = dict_databases[database]
    if database_file:
        if not os.path.exists(database_file):
            print(database_file, "does not exists")
            return
    print(f"[precomputed_VEP] Extracting {database} predictions...")
    if database in ["EVE", "CPT"]:
        dict_search_pattern = pattern_evecpt(input_file, database)
        read_evecpt(database, dict_search_pattern, database_directory, predictions_directory)
    elif database in ["Envision","DeepSAV","PONP2"]:
        dict_search_pattern = pattern_hash(input_file)
        read_idvar_databases(database, dict_search_pattern, database_file, predictions_directory)
    elif database == "ESM1b":
        read_esm1b(input_file, database_directory, predictions_directory)
    elif database == "VESPA":
        read_vespa(input_file, database_file, predictions_directory)
    else:
        read_genomics_databases(input_file, database, database_file, predictions_directory)
    print(f"[precomputed_VEP] {database} done")

if __name__ == "__main__":

    args = get_args()
    directory = args.directory
    input_directory = f"{directory}/input_files"
    predictions_directory = f"{directory}/predictions"
    database_directory = args.databases
    n_cpu = args.cpus

    VESPA_data =  f"{database_directory}/VESPA/vespal_human_proteome.h5"
    CPT_data = f"{database_directory}/CPT/proteome/"
    EVE_data = f"{database_directory}/EVE/variant_files/"
    Envision_data = f"{database_directory}/Envision/Envision_clean.tsv.gz"
    DeepSAV_data =  f"{database_directory}/DeepSAV/humanSAV_light.txt.gz"
    PONP2_data =  f"{database_directory}/PONP2/ponp2_clean.tsv.gz"
    AM_data = f"{database_directory}/AlphaMissense/AlphaMissense_hg38.tsv.gz"
    MutScore_data =  f"{database_directory}/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz"
    SIGMA_data =  f"{database_directory}/SIGMA/sigma_scores_sorted.txt.gz"
    LASSIE_data =  f"{database_directory}/LASSIE/LASSIE_fitness_effect_hg19.tsv.gz"
    UNEECON_data =  f"{database_directory}/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz"
    InMeRF_data = f"{database_directory}/InMeRF/InMeRF_score_hg38.txt.gz"
    MISTIC_data = f"{database_directory}/MISTIC/MISTIC_GRCh38.tsv.gz"
    MutFormer_data = f"{database_directory}/MutFormer/hg19_MutFormer_sorted.tsv.gz"
    CAPICE_data = f"{database_directory}/CAPICE/capice_v1.0_build37_snvs.tsv.gz"



    start_time = time.time()
    GR38_positions_input = f"{input_directory}/dbnsfp_genomic_position_GR38_tabix.tsv"
    GR37_positions_input = f"{input_directory}/dbnsfp_genomic_position_GR37_tabix.tsv"
    id_var_tab_input = f"{input_directory}/id_var_tab.txt"
    id_var_under_input = f"{input_directory}/id_var_under.txt"
    uniprot_entry_input = f"{input_directory}/uniprot_entry.txt"



    dict_databases = {
                      "VESPA":[id_var_tab_input, VESPA_data],
                      "CPT":[uniprot_entry_input, CPT_data],
                      "Envision":[id_var_under_input, Envision_data],
                      "DeepSAV":[id_var_under_input, DeepSAV_data],
                      "PONP2":[id_var_under_input, PONP2_data],
                      "MutScore":[GR38_positions_input, MutScore_data],
                      "SIGMA":[GR38_positions_input, SIGMA_data],
                      "LASSIE":[GR37_positions_input, LASSIE_data],
                      "UNEECON":[GR37_positions_input, UNEECON_data],
                      "InMeRF":[GR38_positions_input, InMeRF_data], 
                      "MISTIC":[GR38_positions_input, MISTIC_data],
                      "MutFormer":[GR37_positions_input, MutFormer_data],
                      "CAPICE":[GR37_positions_input, CAPICE_data],
                      } 

    list_databases = dict_databases.keys()
    
    # list_databases = ["Envision"]

    s = time.time()
    if n_cpu == -1:
        n_jobs = len(list_databases)
    else:
        # check max cpu
        n_jobs = n_cpu
    Parallel(n_jobs = n_jobs,
            prefer="processes")(delayed(run_one_db)(predictions_directory,
                                                    database,
                                                    dict_databases,
                                                    database_directory) \
                                                    for database in list_databases)


    print(time.time() - s)
