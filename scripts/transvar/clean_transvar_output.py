#!/usr/bin/env python3
import pandas as pd
import numpy as np
import sys
import os

def get_input(line):
    positions_field = line["position"]
    protein = line["Gene"]
    if "p." not in positions_field:
        return np.NaN
    variation = positions_field.split("p.")[-1]
    if positions_field == "././." or "ins" in positions_field:
        return np.NaN
    chrom = positions_field.split(":")[0].split("chr")[-1].split("_")[0]
    if "alt" in chrom:
        return np.NaN
    genomic_pos = positions_field.split("/")[0].split(".")[-1]
    nuc1 = genomic_pos[-3]
    nuc2 = genomic_pos[-1]
    pos = genomic_pos[:-3]
    if "_" in pos:
        return np.NaN
    return [chrom, pos, nuc1, nuc2, protein, variation]
    


if __name__ == "__main__":
    transvar_file = sys.argv[1]
    output_file = sys.argv[2]
    output_split = os.path.splitext(output_file)
    output_file_genevar = f"{output_split[0]}_gene_var{output_split[-1]}"
    transvar_data = pd.read_csv(transvar_file, sep="\t", names=["Gene", "position"])
    clean_input = transvar_data.apply(lambda line: get_input(line), axis=1).dropna().values.tolist()
    with open(output_file, "w") as f, open(output_file_genevar, "w") as f2:
        for var in clean_input:
            chrom = var[0]
            pos = var[1]
            nuc1 = var[2]
            nuc2 = var[3]
            protein = var[4]
            variation = var[5]
            f.write(f"{chrom} {pos} {nuc1} {nuc2}\n")
            f2.write(f"{chrom} {pos} {nuc1} {nuc2} {protein} {variation}\n")