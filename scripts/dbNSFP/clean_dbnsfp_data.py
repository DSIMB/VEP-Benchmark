import pandas as pd
import numpy as np
import sys
import os
import argparse


def get_args():
    parser = argparse.ArgumentParser(description='Generating input files needed to retrieve predictions from Variant Effect Predictors')
    parser.add_argument('-f', '--file',
                        help="Path to file containing genomic positions",
                        required=True, type=str)
    # Faire + simple
    parser.add_argument('-int', '--intermediate_folder',
                        help="Path to directory containing all dbNSFP files",
                        required=True, type=str)
    parser.add_argument('-df', '--dbnsfp_file',
                        help="Path to file to create",
                        default="./predictions/dbNSFP/dbNSFP_output.tsv",
                        required=False, type=str)
    parser.add_argument('-o', '--output_file',
                        help="Choose the reference genome to consider between 38 and 37 (default:38)",
                        default="./predictions/dbNSFP/dbNSFP_output_clean.tsv",
                        required=False, type=str)
    parser.add_argument('-inp', '--input_folder',
                        help="Path to directory containing all dbNSFP files",
                        default="./input_files",
                        required=False, type=str)
    
    args = parser.parse_args()
    variant_file = args.file
    if not os.path.exists(variant_file):
        sys.exit(f"[dbNSFP] Variant file '{variant_file}' does not exists. Please provide an existing one.")
    return args


def get_correct_index(line, dict_fasta, dict_variation):
    df_gene = pd.DataFrame((line["Gene"].split(";"))).value_counts()
    index_gene = df_gene.argmax()
    gene = df_gene.index[index_gene][0]

    pos_field = str(line["aapos"]).split(";")
    aaref = line["aaref"]
    aaalt = line["aaalt"]
    correct_index = []
    if gene in dict_fasta:
        sequence = dict_fasta[gene]
        for i in range(len(pos_field)):
            position = int(pos_field[i])
            variation = f"{aaref}{position}{aaalt}"
            if gene in dict_variation:
                if variation in dict_variation[gene]:
                    if position - 1 < len(sequence):
                        true_residue = sequence[position - 1]
                        if true_residue == aaref:
                            correct_index.append(i)
    return correct_index


def clean_line(line, dict_fasta, dict_variation):
    correct_index = get_correct_index(line, dict_fasta, dict_variation)
    if len(correct_index) == 0:
        return np.NaN
    new_line = []
    for i, field in enumerate(line):
        if i in [1, 3, 4, 5, 6, 7, 8]:
            new_line.append(field)
            continue
        # Gene
        if i == 0:
            items = str(field).split(";")
            df_gene = pd.DataFrame((items)).value_counts()
            index_gene = df_gene.argmax()
            gene = df_gene.index[index_gene][0]
            new_line.append(gene)
            continue
        # Pos
        if i == 2:
            items = str(field).split(";")
            new_line.append(items[correct_index[0]])
            continue
        if field == ".":
            new_line.append(np.NaN)
            continue
        items = str(field).split(";")
        if len(items) >= max(correct_index) + 1:
            scores = np.array(items, dtype=object)[correct_index]
            if (scores == ".").sum() != len(correct_index):
                scores[scores == "."] = np.NaN
                scores = scores.astype(float)
                new_line.append(np.nanmean(scores))
            else:
                new_line.append(np.NaN)
        elif ";" in str(field):
            new_line.append(items[0])
        else:
            new_line.append(field)
    return np.array(new_line)



def get_sequences(list_gene):
    multi_fasta_file = "/dsimb/wasabi/radjasan/these//benchmark/Uniprot/uniprot-compressed_true_download_true_format_fasta_query__28_2A_29_2-2023.03.28-13.08.10.56.fasta"
    get = False
    dict_seq = {}
    with open(multi_fasta_file) as filin:
        for line in filin:
            if line.startswith(">tr"):
                get = False
                continue
            elif line.startswith(">sp"):
                gene = line.split("GN=")[-1].split()[0]
                if gene in list_gene:
                    get = True
                    if gene not in dict_seq:
                        dict_seq[gene] = ""
                else:
                    get = False
            else:
                if get:
                    dict_seq[gene] += line.strip()
    return dict_seq


def get_dict_variation(gene_var_file):
    dict_variation = {}
    with open(gene_var_file) as f:
        for line in f:
            items = line.split()
            if len(items) < 2:
                continue
            gene = items[0]
            if gene not in dict_variation:
                dict_variation[gene] = {}
            variation = items[1]
            dict_variation[gene][variation] = 0
    return dict_variation

def get_list_genes(line):
    df_gene = pd.DataFrame((line.split(";"))).value_counts()
    index_gene = df_gene.argmax()
    gene = df_gene.index[index_gene][0]
    return gene



if __name__ == "__main__":
    args = get_args()
    print("[dbNSFP] Cleaning dbNSFP outputs...")
    intermediate_folder = args.intermediate_folder
    gene_var_file = args.file
    dbnsfp_file = args.dbnsfp_file
    clean_dbnsfp_file_output = args.output_file
    input_folder = args.input_folder


    header_file = f"{intermediate_folder}/header.txt"
    final_header_file = f"{intermediate_folder}/final_header.txt"
    final_header_modified_file = f"{intermediate_folder}/final_header_modified.txt"

    header_GR38 = ["#chr", "pos(1-based)", "ref", "alt"]
    header_GR37 = ["#chr", "hg19_pos(1-based)", "ref", "alt"]

    with open(header_file) as f1, open(final_header_file) as f2, open(final_header_modified_file) as f3:
        header = [x.strip() for x in f1]
        final_header = [x.strip() for x in f2]
        final_header_modified = [x.strip() for x in f3]

    dbnsfp_dtf = pd.read_csv(dbnsfp_file, sep="\t", names=header)
    list_gene = list(set(dbnsfp_dtf["genename"].apply(lambda line: get_list_genes(line)).values))
    dict_variation = get_dict_variation(gene_var_file)
    dict_fasta = get_sequences(list_gene)
    
    dbnsfp_dtf = dbnsfp_dtf[final_header]
    dbnsfp_dtf.columns = final_header_modified
    clean_dbnsfp_dtf = dbnsfp_dtf.apply(lambda line: clean_line(line, dict_fasta, dict_variation), axis=1).dropna()
    final_dbnsfp = pd.DataFrame(clean_dbnsfp_dtf.to_dict()).T
    final_dbnsfp.columns = final_header_modified
    variation = final_dbnsfp["aaref"].values + final_dbnsfp["aapos"].values + final_dbnsfp["aaalt"].values
    final_dbnsfp["Variation"] = variation
    final_dbnsfp = final_dbnsfp.replace("nan", np.NaN)
    final_dbnsfp.reset_index(drop=True, inplace=True)
    final_dbnsfp["NA"] = final_dbnsfp.isna().sum(axis = 1)
    clean_data = final_dbnsfp.iloc[final_dbnsfp.groupby(["Gene","Variation"])["NA"].idxmin().values]
       
    clean_data.drop("NA", axis=1).to_csv(clean_dbnsfp_file_output, sep="\t", index=False)

    clean_data[header_GR38 + ["Gene", "Variation"]].to_csv(f"{input_folder}/dbnsfp_genomic_position_GR38_gene_var.tsv", sep="\t", header=False, index=False)
    clean_data[header_GR38].to_csv(f"{input_folder}/dbnsfp_genomic_position_GR38.tsv", sep="\t", header=False, index=False)

    clean_data[header_GR37 + ["Gene", "Variation"]].to_csv(f"{input_folder}/dbnsfp_genomic_position_GR37_gene_var.tsv", sep="\t", header=False, index=False)
    clean_data[header_GR37].to_csv(f"{input_folder}/dbnsfp_genomic_position_GR37.tsv", sep="\t", header=False, index=False)
    
    print("[dbNSFP] Cleaning done")
    print(f"[dbNSFP] Genomic positions from dbNSFP output have been saved in both GR38 and GR37 reference genome in folder '{input_folder}'")
