#!/usr/bin/env python3
"""Generation of inputs: id_var, gene_var, genevar_seq, ESM, VariPred
Usage:

python generate_input.py file output_dir
file: gene var format file or id var
output_dir: directory to store all inputs files
"""

import os
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description='Generating input files needed to retrieve predictions from Variant Effect Predictors')
    parser.add_argument('-f', '--file',
                        help="Path to the variant file with following columns: Gene|UniprotID, Protein mutation, Label",
                        required=True, type=str)
    parser.add_argument('-s', '--script_folder',
                        help="Directory containing the ESM1v script 'predict.py'",
                        required=True, type=str)
    parser.add_argument('--fasta_file',
                        help="Path to multi-fasta file from UniProt",
                        required=True, type=str)
    parser.add_argument('-o', '--output_folder',
                        help="Directory in which 'input_files' and 'predictions' folders will be created",
                        default=".",
                        required=False, type=str)
    args = parser.parse_args()

    variant_file = args.file
    fasta_file = args.fasta_file
    if not os.path.exists(variant_file):
        sys.exit(f"Variant file '{variant_file}' does not exists. Please provide an existing one.")
    if not os.path.exists(fasta_file):
        sys.exit(f"Fasta file '{fasta_file}' does not exists. Please provide an existing one.")

    return args

def get_gene_infos(list_geneorID, multi_fasta_file):
    dict_ID = {}
    dict_gene = {}
    dict_fasta = {}
    dict_entry = {}
    get = False
    with open(multi_fasta_file) as filin:
        for line in filin:
            if line.startswith(">tr") or 'Alternative' in line:
                get = False
                continue
            elif line.startswith(">sp"):
                items = line.split("|")
                ID = items[1]
                gene = line.split("GN=")[-1].split()[0]
                entry = items[2].split()[0]
                if ID in list_geneorID or gene in list_geneorID:
                    dict_ID[ID] = gene
                    dict_entry[ID] = entry
                    dict_gene[gene] = ID
                    dict_fasta[gene] = ""
                    get = True
                else:
                    get = False
            elif get:
                dict_fasta[gene] += line.strip()
    return dict_ID, dict_gene, dict_fasta, dict_entry


def create_input_files(dict_ID, dict_gene, dict_data, dict_fasta, dict_entry, input_folder, predictions_folder, script_folder):

    # Creating ESM1v folders
    os.makedirs(f"{input_folder}/ESM1v/", exist_ok=True)
    os.makedirs(f"{predictions_folder}/ESM1v/", exist_ok=True)

    # Bash script containing all ESM1v command to run (GPU needed)
    ESM_command = f"{predictions_folder}/ESM1v/run_esm.sh"

    # Different format of input data required by VEPs to retrieve predictions
    # Using UniprotID
    output_idvar_under = f"{input_folder}/id_var_under.txt"
    output_idvar_tab = f"{input_folder}/id_var_tab.txt"
    output_idgene_var_tab = f"{input_folder}/id_vargene_tab.txt"

    # Using gene name
    output_genevar_under = f"{input_folder}/gene_var_under.txt"
    output_genevar_tab = f"{input_folder}/gene_var_tab.txt"
    output_genevar_fasta = f"{input_folder}/gene_var_seq.fasta"

    # Uniprot Entry
    output_uniprot_entry = f"{input_folder}/uniprot_entry.txt"

    # Creating each input files using UniprotID
    with open(output_idvar_under, "w") as file_ID_under, \
         open(output_idvar_tab, "w") as file_ID_tab, \
         open(output_idgene_var_tab, "w") as file_IDGENE_tab, \
         open(output_uniprot_entry, "w") as file_uniprot_entry:
        for ID in dict_ID:
            if ID in dict_data:
                var_list = dict_data[ID]
            else:
                gene = dict_ID[ID]
                var_list = dict_data[gene]
            for var in var_list:
                # ID tab
                file_ID_tab.write(f'{ID}\t{var}\n')
                # ID under
                file_ID_under.write(f'{ID}_{var}\n')
                # ID GENE
                gene = dict_ID[ID]
                file_IDGENE_tab.write(f'{gene}\t{ID}\t{var}\n')
                # UNIPROT ENTRY
                entry = dict_entry[ID]
                file_uniprot_entry.write(f'{gene}\t{entry}\t{var}\n')

    with open(output_genevar_under, "w") as file_gene_under, open(output_genevar_tab, "w") as file_gene_tab, \
        open(output_genevar_fasta, "w") as file_fasta, open(ESM_command, "w") as f_esm_command:
        for gene in dict_gene:
            # ESM
            output_esm = f"{input_folder}/ESM1v/{gene}.txt"


            f_esm = open(output_esm, "w")
            content_ESM = "mutation\n"
            f_esm.write(content_ESM)

            sequence = dict_fasta[gene]

            # put script path to args #####################################################
            command_esm = f"python {script_folder}/predict_ESM.py \
                        --model-location esm1v_t33_650M_UR90S_1 esm1v_t33_650M_UR90S_2 esm1v_t33_650M_UR90S_3 esm1v_t33_650M_UR90S_4 esm1v_t33_650M_UR90S_5 \
                        --sequence {sequence} \
                        --dms-input  {os.path.abspath(output_esm)} \
                        --mutation-col mutation \
                        --dms-output {os.path.abspath(predictions_folder)}/ESM1v/{gene}.csv \
                        --offset-idx 1 \
                        --scoring-strategy wt-marginals\n"
            
            if gene in dict_data:
                var_list = dict_data[gene]
            else:
                ID = dict_gene[gene]
                var_list = dict_data[ID]

            content_genevar_seq = f">{gene} "
            for var in var_list:
                
                # Varipred format
                pos = int(var[1:-1])
                aaref = var[0]
                aaalt = var[-1]
                sequence_mut = list(dict_fasta[gene])
                try:
                    sequence_mut[pos-1]
                except:
                    continue
                if sequence_mut[pos-1] == aaref:
                    sequence_mut[pos-1] = aaalt

                    # ESM
                    content_ESM = f"{var}\n"
                    f_esm.write(content_ESM)

                sequence_mut = "".join(sequence_mut)

                # Gene tab
                file_gene_tab.write(f'{gene}\t{var}\n')
                # Gene under
                file_gene_under.write(f'{gene}_{var}\n')
                # Gene var sequence
                content_genevar_seq += f"{var} "
            content_genevar_seq += f"\n{sequence}\n"

            # Sequence lengths limited to 1024 in ESM1v
            if len(sequence) < 1024:
                f_esm_command.write(command_esm)

            # Needed ? #####################################################
            if len(sequence) < 4000:
                file_fasta.write(content_genevar_seq)

            f_esm.close()

if __name__ == "__main__":
    args = get_args()

    var_file = args.file
    output_folder = args.output_folder
    multi_fasta_file = args.fasta_file
    script_folder = args.script_folder
    # Directory to create the 'input_files' folder
    input_folder = f"{output_folder}/input_files"
    predictions_folder = f"{output_folder}/predictions"

    os.makedirs(input_folder, exist_ok=True)
    os.makedirs(predictions_folder, exist_ok=True)

    dict_data = {}

    with open(var_file) as f:
        for line in f:
            items = line.split()
            geneorID = items[0]
            variation = items[1]
            if geneorID not in dict_data:
                dict_data[geneorID] = []
            dict_data[geneorID].append(variation)

    list_geneorID = list(dict_data.keys())
    dict_ID, dict_gene, dict_fasta, dict_entry = get_gene_infos(list_geneorID, multi_fasta_file)
    create_input_files(dict_ID, dict_gene, dict_data, dict_fasta, dict_entry, input_folder, predictions_folder, script_folder)


    print(f"Input files created in {input_folder}")
    print(f"Script to run ESM1v has been created in {predictions_folder}/ESM1v/")
