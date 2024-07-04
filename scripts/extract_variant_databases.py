import sys
import gzip
from tqdm import tqdm
import os
import time
from joblib import Parallel, delayed
import h5py


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
            string_variation = f"{res1},{pos},{res2}"
            if entry not in dict_pattern:
                dict_pattern[entry] = {}
            if database == "EVE":
                value_dict = string_variation
            else:
                value_dict = variation
            dict_pattern[entry][value_dict] = gene
    return dict_pattern


def read_evecpt(database, dict_search_pattern, database_directory, output_directory, position_tqdm):
    if database == "EVE":
        ext = ""
        mode = "r"
        open_fun = open
    else:
        ext = ".gz"
        mode = "rt"
        open_fun = gzip.open

    output_file = f"{output_directory}/{database}/{database}_predictions.tsv"
    if os.path.exists(output_file):
        os.remove(output_file)
    with tqdm(desc=database, position=position_tqdm, dynamic_ncols=True, ncols=10, leave=True, disable=True):
        for entry in dict_search_pattern:
            file_predictions = f"{database_directory}/{entry}.csv{ext}"
            if not os.path.exists(file_predictions):
                continue
            with open_fun(file_predictions, mode, encoding='utf-8') as db_file, open(output_file, "a") as fout:
                for line in db_file:
                    items = line.split(",")
                    if database == "EVE":
                        variation = ",".join(items[:3])
                    else:
                        variation = items[0]
                    if variation in dict_search_pattern[entry]:
                        gene = dict_search_pattern[entry][variation]
                        if database == "EVE":
                            new_line = f"{gene}\t{items[0]}{items[1]}{items[2]}\t{items[10]}\n"
                        else:
                            new_line = f"{gene}\t{items[0]}\t{items[1]}"
                        fout.write(new_line)

def read_vespa(id_var_file, database_file, output_directory, position_tqdm):
    dict_aa = {}
    for i, aa in enumerate("ALGVSREDTIPKFQNYMHWC"):
        dict_aa[aa] = i

    with open(id_var_file) as file_input, open(f"{output_directory}/VESPA/VESPA_predictions.tsv", "w") as file_out, \
            h5py.File(database_file, "r") as vespa_file:
        
        input_content = file_input.readlines()
        for line_input in tqdm(input_content, desc="VESPA", position=position_tqdm, dynamic_ncols=True, ncols=10, leave=True, disable=True):
            items_input = line_input.split()
            ID = items_input[0]
            var = items_input[1]
            res_wt = var[0]
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




def read_esm1b(id_var_file, database_directory, output_directory, position_tqdm):
    with open(id_var_file) as file_input, open(f"{output_directory}/ESM1b/ESM1b_predictions.tsv", "w") as file_out:
        input_content = file_input.readlines()
        for line_input in tqdm(input_content, desc="ESM1b", position=position_tqdm, dynamic_ncols=True, ncols=10, leave=True, disable=True):
            items_input = line_input.split()
            ID = items_input[0]
            var = items_input[1]
            res_wt = var[0]
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


def read_idvar_databases(database, dict_search_pattern, database_file, output_directory, position_tqdm):
    output_file = f"{output_directory}/{database}/{database}_predictions.tsv"
    total_databases = {"AlphaMissense":216175355, "Envision":239574197, "VARITY":68235189,
                       "PONP2":191213818, "DeepSAV":72955138}
    total = total_databases[database]
    N_pattern = len(dict_search_pattern)
    done = 0
    if "gz" in database_file:
        mode = "rt"
        open_fun = gzip.open
    else:
        mode= "r"
        open_fun = open

    with open_fun(database_file, mode, encoding='utf-8') as db_file, open(output_file, "w") as fout:
        with tqdm(total=total, desc=database, position=position_tqdm, dynamic_ncols=True, ncols=10, leave=True, disable=True):
            for line in db_file:
                if line.startswith("#") or line.startswith("UniProt"):
                    continue
                items = line.split()
                ID = items[0]
                var = items[1]
                if database == "Envision":
                    string = items[1]
                elif database in ["AlphaMissense", "VARITY"]:
                    string = f"{ID}_{var}"
                elif database == "DeepSAV":
                    var = f"{items[2]}{items[1]}{items[3]}"
                    string = f"{ID}_{var}"
                elif database == "PONP2":
                    ID = items[-1]
                    var = items[2]
                    string = items[0]

                if string in dict_search_pattern:
                    if database == "AlphaMissense":
                        new_line = f"{ID}\t{var}\t{items[2]}\n"
                    elif database == "Envision":
                        new_line = f"{items[5]}\t{items[7]}\t{items[-1]}\n"
                    elif database == "DeepSAV":
                        new_line = f"{ID}\t{var}\t{items[4]}\n"
                    elif database == "PONP2":
                        new_line = f"{ID}\t{var}\t{items[3]}\n"
                    elif database == "VARITY":
                        new_line = line
                    fout.write(new_line)
                    done += 1
                    if done == N_pattern:
                        break


def read_genomics_databases(database, dict_search_pattern, database_file, output_directory, position_tqdm):
    total_databases = {"SNPred":73692785, "InMeRF":76760498, 
                      "MISTIC":73731466, "MutFormer":72678408,
                      "LASSIE":96585028, "CAPICE":8575974282,
                      "MutScore":71718775, "UNEECON":71488576,
                      "SIGMA":16220653,
                    "CAPICE1":675841863,
                    "CAPICE2":714613554,
                    "CAPICE3":584391405,
                    "CAPICE4":562985028,
                    "CAPICE5":533085780,
                    "CAPICE6":502185198,
                    "CAPICE7":466060989,
                    "CAPICE8":428666766,
                    "CAPICE9":360430293,
                    "CAPICE10":393944214,
                    "CAPICE11":393388548,
                    "CAPICE12":391444179,
                    "CAPICE13":286769634,
                    "CAPICE14":264868620,
                    "CAPICE15":245084298,
                    "CAPICE16":236654259,
                    "CAPICE17":233385630,
                    "CAPICE18":223971687,
                    "CAPICE19":167426949,
                    "CAPICE20":178516560,
                    "CAPICE21":105319926,
                    "CAPICE22":104683635
                        }
    
    if "CAPICE" in database:
        output_file = f"{output_directory}/CAPICE/{database}_predictions.tsv"
    else:
        output_file = f"{output_directory}/{database}/{database}_predictions.tsv"

    total = total_databases[database]

    N_pattern = len(dict_search_pattern)
    done = 0

    if "gz" in database_file:
        mode = "rt"
        open_fun = gzip.open
    else:
        mode= "r"
        open_fun = open
    DONE_nb = 0
    with open_fun(database_file, mode, encoding='utf-8') as db_file, open(output_file, "w") as fout:
        for line in tqdm(db_file, total=total, desc=database, position=position_tqdm, dynamic_ncols=True, ncols=10, leave=True, disable=True):
            if line.startswith("Chr") or line.startswith("#"):
                continue
            items = line.split()
            chrom = items[0]
            pos = items[1]
            nuc1 = items[2]
            nuc2 = items[3]
            string_genomic = f"{chrom}_{pos}_{nuc1}_{nuc2}"
            if string_genomic in dict_search_pattern:
                DONE_nb += 1
                if database == "SIGMA":
                    new_line = f"{chrom}\t{pos}\t{nuc1}\t{nuc2}\t{items[-2]}\n"
                else:
                    new_line = f"{chrom}\t{pos}\t{nuc1}\t{nuc2}\t{items[4]}\n"
                fout.write(new_line)
                done += 1
                if done == N_pattern:
                    break


def run_one_db(output_directory, database, dict_databases, database_directory, position_tqdm):
    N_data = len(dict_databases)
    if 'CAPICE' in database:
        os.makedirs(f"{output_directory}/CAPICE", exist_ok=True)
    else:
        os.makedirs(f"{output_directory}/{database}", exist_ok=True)
        
    input_file, database_file, read_function = dict_databases[database]
    print("Running", database)
    if database in ["EVE", "CPT"]:
        dict_search_pattern = pattern_evecpt(input_file, database)
    else:
        dict_search_pattern = pattern_hash(input_file)
    if database == "ESM1b":
        read_esm1b(input_file, database_directory, output_directory, position_tqdm)
    elif database == "VESPA":
        read_vespa(input_file, database_file, output_directory, position_tqdm)

    else:
        read_function(database, dict_search_pattern, database_file, output_directory, position_tqdm)
    print(database, "done")

if __name__ == "__main__":


    # Folder with input_files and tools folders
    input_directory = sys.argv[1]

    database_directory = "/home/wasabi/radjasan/these/benchmark/variant_databases/"

    AM_data = f"{database_directory}/AlphaMissense/AlphaMissense_aa_substitutions.tsv.gz"
    Envision_data = f"{database_directory}/Envision/Envision_clean.csv"
    InMeRF_data = f"{database_directory}/InMeRF/InMeRF_reduced_hg19_GRCh37.txt"
    MISTIC_data = f"{database_directory}/MISTIC/MISTIC_GRCh38.tsv.gz"
    MutFormer_data = f"{database_directory}/MutFormer/mutformer_data.txt"
    VARITY_data =  f"{database_directory}/VARITY/VARITY_data.tsv"
    LASSIE_data =  f"{database_directory}/LASSIE/LASSIE_fitness_effect_hg19.tsv.gz"
    CAPICE_data =  f"{database_directory}/CAPICE/capice_v1.0_build37_snvs.tsv.gz"

    MutScore_data =  f"{database_directory}/MutScore/mutscore-v1.0-hg38.tsv.gz"
    DeepSAV_data =  f"{database_directory}/DeepSAV/DeepSAV_predictions.txt.gz"
    PONP2_data =  f"{database_directory}/PONP2/ponp_predicion_combined_2.txt"
    UNEECON_data =  f"{database_directory}/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz"
    SIGMA_data =  f"{database_directory}/SIGMA/sigma_scores.sorted.tsv.gz"
    VESPA_data =  f"{database_directory}/VESPA/vespal_human_proteome.h5"

    CPT_data = f"/home/wasabi/radjasan/these/benchmark/CPT/proteome/"
    EVE_data = f"/home/wasabi/radjasan/these/benchmark/EVE/variant_files/"



    start_time = time.time()
    GR38_positions_input = f"{input_directory}/input_files/genomic_position_GR38.tsv"
    GR37_positions_input = f"{input_directory}/input_files/genomic_position_GR37.tsv"
    # GR37_positions_input = f"{input_directory}/input_files/dbnsfp_genomic_position_GR37.tsv"
    id_var_tab_input = f"{input_directory}/input_files/id_var_tab.txt"
    id_var_under_input = f"{input_directory}/input_files/id_var_under.txt"
    uniprot_entry_input = f"{input_directory}/input_files/uniprot_entry.txt"

    output_directory = f"{input_directory}/predictions"


    dict_databases = {"AlphaMissense":[id_var_tab_input, AM_data, read_idvar_databases], 
                      "Envision":[id_var_under_input, Envision_data, read_idvar_databases],
                      "InMeRF":[GR37_positions_input, InMeRF_data, read_genomics_databases], 
                      "MISTIC":[GR38_positions_input, MISTIC_data, read_genomics_databases],
                      "MutFormer":[GR37_positions_input, MutFormer_data, read_genomics_databases],
                      "EVE":[uniprot_entry_input, EVE_data, read_evecpt],
                      "CPT":[uniprot_entry_input, CPT_data, read_evecpt],
                      "LASSIE":[GR37_positions_input, LASSIE_data, read_genomics_databases],
                      "CAPICE":[GR37_positions_input, CAPICE_data, read_genomics_databases],
                      "DeepSAV":[id_var_under_input, DeepSAV_data, read_idvar_databases],
                      "MutScore":[GR38_positions_input, MutScore_data, read_genomics_databases],
                      "PONP2":[id_var_under_input, PONP2_data, read_idvar_databases],
                      "UNEECON":[GR37_positions_input, UNEECON_data, read_genomics_databases],
                      "SIGMA":[GR38_positions_input, SIGMA_data, read_genomics_databases],
                      "ESM1b":[id_var_tab_input, None, read_esm1b],
                      "VESPA":[id_var_tab_input, VESPA_data, read_vespa],
                      "VARITY":[id_var_tab_input, VARITY_data, read_idvar_databases]
                      } 

    list_databases = dict_databases.keys()
    
    list_databases = ["LASSIE"]

    Parallel(n_jobs = len(list_databases),
            prefer="processes")(delayed(run_one_db)(output_directory,
                                                    database,
                                                    dict_databases,
                                                    database_directory,
                                                    pos_tqdm) \
            for pos_tqdm, database in enumerate(list_databases) if database != "CAPICE")
    
    if "CAPICE" in list_databases:
        capice_databases = {}
        for i in range(1, 23):
            capice_databases[f"CAPICE{i}"] = [GR37_positions_input, f"{database_directory}/CAPICE/capice_v1.0_build37_snvs_chr{i}.tsv.gz", read_genomics_databases, i]
        capice_files = capice_databases.keys()
        Parallel(n_jobs = len(capice_files), prefer="processes")(delayed(run_one_db)(output_directory, database, capice_databases, database_directory) for database in capice_files)

        os.system(f"cat {output_directory}/CAPICE/* > {output_directory}/CAPICE/tmp")
        os.system(f"rm {output_directory}/CAPICE/*tsv")
        os.system(f"mv {output_directory}/CAPICE/tmp {output_directory}/CAPICE/CAPICE_predictions.tsv")
