import pandas as pd
import sys
import os
import numpy as np

def concat_id_data(tool_name, id_gene_data):
    print(tool_name)
    file_data = f"{folder}/tools/{tool_name}/{tool_name}_predictions.tsv"
    if not os.path.exists(file_data):
        print(file_data, "doesn't exists")
        return pd.DataFrame([])
    if tool_name == "VARITY":
        col = ["VARITY_R_score", "VARITY_ER_score", "VARITY_R_LOO_score", "VARITY_ER_LOO_score"]
    else:
        col = [f"{tool_name}_score"]
    data = pd.read_csv(file_data, sep="\t", names = ["ID", "Variation"] + col)
    data.ID = data.ID.astype(str)
    data_merged = pd.merge(id_gene_data, data, on = ["ID", "Variation"], how = "inner")    
    data_final = data_merged[["Gene", "Variation", "CS"] + col]    
    return data_final


def concat_gene_data(tool_name, CS_data):
    print(tool_name)
    file_data = f"{folder}/tools/{tool_name}/{tool_name}_predictions.tsv"
    if not os.path.exists(file_data):
        print(file_data, "doesn't exists")
        return pd.DataFrame([])
    if tool_name == "ESM":
        data = pd.read_csv(file_data, sep="\t",
                           names = ["Gene", "Variation", "model1","model2","model3","model4","model5"])
        data[f"ESM1v_score"] = data[["model1","model2","model3","model4","model5"]].mean(axis=1)
        data = data[["Gene", "Variation", f"ESM1v_score"]]
    elif tool_name == "VESPA":
        data = pd.read_csv(file_data, sep="\t", names = ["Gene", "Variation", f"{tool_name}_score"])
        data["Variation"] = data["Variation"].apply(lambda var: f"{var[0]}{int(var[1:-1])}{var[-1]}")
    else:
        data = pd.read_csv(file_data, sep="\t", names = ["Gene", "Variation", f"{tool_name}_score"])
    CS_data = CS_data.astype(str)
    data = data.astype(str)
    data_merged = pd.merge(CS_data, data, on = ["Gene","Variation"], how = "inner")
    return data_merged



def concat_genomic_data(tool_name, genomic_position):
    print(tool_name)
    file_data = f"{folder}/tools/{tool_name}/{tool_name}_predictions.tsv"
    if not os.path.exists(file_data):
        print(file_data, "doesn't exists")
        return pd.DataFrame([])
    data = pd.read_csv(file_data, sep="\t", names = ["chr", "pos", "ref", "alt", f"{tool_name}_score"])    
    data = data.astype(str)    
    genomic_position = genomic_position.astype(str)
    data_merged = pd.merge(genomic_position, data, on = ["chr", "pos", "ref", "alt"], how = "inner").drop_duplicates()
    data_final = data_merged[["Gene","Variation", "CS", f"{tool_name}_score"]]
    return data_final


def concat_perf_data(variant_data, perf_dict):
    concat_data = variant_data[["Gene","Variation","CS"]]
    for key in perf_dict:
        if not perf_dict[key].empty:
            tmp_merge = pd.merge(concat_data, perf_dict[key], on = ["Gene","Variation","CS"], how = "left")
            concat_data = tmp_merge.drop_duplicates(subset=["Gene","Variation","CS"])
    return concat_data



if __name__ == "__main__":
       
       
    folder = sys.argv[1]
    CS_file = sys.argv[2]
    dataname = sys.argv[3]
    
    # Variant data
    gene_var_CS_file = CS_file
    gene_var_file = f"{folder}/input_files/gene_var_tab.txt"
    gene_id_file = f"{folder}/input_files/id_vargene_tab.txt"
    GR38_gene_var_file = f"{folder}/input_files/genomic_position_GR38_gene_var.tsv"
    GR37_gene_var_file = f"{folder}/input_files/genomic_position_GR37_gene_var.tsv"



 
    gene_var_CS_data = pd.read_csv(gene_var_CS_file, sep="\t", names=["Gene","Variation", "CS"])
    gene_var_CS_data["CS"] = gene_var_CS_data["CS"].apply(lambda CS: CS.capitalize())

    gene_idvar_data = pd.read_csv(gene_id_file, sep="\t", names=["Gene", "ID", "Variation"])
    gene_idvar_data = pd.merge(gene_idvar_data, gene_var_CS_data, on = ["Gene", "Variation"], how = "inner")

    GR38_gene_var_data = pd.read_csv(GR38_gene_var_file, delim_whitespace=True, names=["chr","pos","ref","alt","Gene","Variation"])
    GR38_gene_var_data = pd.merge(GR38_gene_var_data, gene_var_CS_data, on = ["Gene", "Variation"], how = "inner")

    GR37_gene_var_data = pd.read_csv(GR37_gene_var_file, delim_whitespace=True, names=["chr","pos","ref","alt","Gene","Variation"])
    GR37_gene_var_data = pd.merge(GR37_gene_var_data, gene_var_CS_data, on = ["Gene", "Variation"], how = "inner")

    GR38_gene_var_data["chr"] = GR38_gene_var_data["chr"].astype(str)
    GR37_gene_var_data["chr"] = GR37_gene_var_data["chr"].astype(str)

    
    
    perf_dict = {}
    

    
    # DBNSFP
    dbNSFP = pd.read_csv(f"{folder}/tools/dbNSFP/dbNSFP_output_clean.tsv.cleaned", sep="\t")
    f = open("/dsimb/glaciere/radjasan/dbNSFP/academic/final_header_modified.txt")
    final_header = [x.strip() for x in f]
    f.close()
    db_col = ["Gene","Variation"] + final_header[9:]
    dbNSFP_final = dbNSFP[db_col]
    dbNSFP_final = dbNSFP_final.drop(["VARITY_R_score", "VARITY_ER_score", "VARITY_R_LOO_score", "VARITY_ER_LOO_score"], axis=1)
    dbNSFP_final = pd.merge(gene_var_CS_data, dbNSFP_final, on = ["Gene", "Variation"], how = "left")
    perf_dict["dbNSFP"] = dbNSFP_final
    
    # ID VAR TOOLS
    list_id_tool = ["AlphaMissense", "Envision", "SuSPect", "VARITY", "PONP2",
                    "DeepSAV", "VESPA", "ESM1b", "VESPA"]
    for tool_name in list_id_tool:
        perf_dict[tool_name] = concat_id_data(tool_name, gene_idvar_data)

    
    # GENE VAR TOOLS
    list_gene_tool = ["CPT", "EVE", "ESM"]
    for tool_name in list_gene_tool:
        perf_dict[tool_name] = concat_gene_data(tool_name, gene_var_CS_data)

    # GENOMIC TOOLS
    dict_tool_name = {"MutFormer":GR37_gene_var_data,
              "MISTIC":GR38_gene_var_data, "InMeRF":GR37_gene_var_data, "LASSIE":GR37_gene_var_data,
              "CAPICE":GR37_gene_var_data, "SIGMA":GR38_gene_var_data, "MutScore":GR38_gene_var_data,
              "UNEECON":GR37_gene_var_data, "PhDSNP":GR38_gene_var_data}
        
        
    for tool_name in dict_tool_name:
        perf_dict[tool_name] = concat_genomic_data(tool_name, dict_tool_name[tool_name])
        
        
        
    concat_data = concat_perf_data(gene_var_CS_data, perf_dict)
    print(concat_data["SIFT_score"].dropna())
    concat_data.to_csv(f"{folder}/{dataname}_predictions.tsv", sep="\t", index=False)
