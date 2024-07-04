import json
import os
import sys

folder=sys.argv[1]

vespa_dir = f"{folder}/tools/VESPA/results/"
dict_vespa = json.load(open(f"{vespa_dir}/map.json"))

for id in dict_vespa:
    protein = dict_vespa[id]
    initial_file = f"{vespa_dir}/{id}.csv"
    protein_file = f"{vespa_dir}/{protein}.csv"
    os.rename(initial_file, protein_file)
