import gzip
import sys
from joblib import Parallel, delayed

def get_ref():
    ref_file = sys.argv[1]
    prev_chrom = ""
    prev_start = ""
    dict_chrom = {}
    with gzip.open(ref_file, "rt") as f:
        for line in f:
            items = line.split()
            chrom = items[0]
            start = items[1]
            if chrom not in dict_chrom:
                dict_chrom[chrom] = [start]
            if chrom != prev_chrom and prev_chrom != "":
                dict_chrom[prev_chrom].append(prev_start)
                print(dict_chrom)
                
                break
            prev_chrom = chrom
            prev_start = start
    print(dict_chrom)

def modif_capice(chrom):
    capice_files = f"/home/wasabi/radjasan/these/benchmark/variant_databases/CAPICE/capice_v1.0_build37_snvs_chr{chrom}.tsv.gz"
    capice_files_output = f"/home/wasabi/radjasan/these/benchmark/variant_databases/CAPICE/capice_reduced_v1.0_build37_snvs_chr{chrom}.tsv.gz"
    start, end = map(int, dict_ref[str(chrom)])
    print(chrom, start, end)
    with gzip.open(capice_files, "rt") as fcapice, gzip.open(capice_files_output, "wt") as out_capice:
        for line in fcapice:
            start_capice = int(line.split()[1])
            if start < start_capice and start_capice < end:
                out_capice.write(line)



dict_ref = {'1': ['69091', '249212558'],
            '10': ['93001', '135440246'],
             '11': ['193100', '134257553'], '12': ['176049', '133810942'],
             '13': ['19748007', '115091753'], '14': ['19377594', '105996127'],
             '15': ['20739500', '102463262'], '16': ['97433', '90142318'], 
             '17': ['63647', '81052317'],'18': ['158699', '78005231'],
            '19': ['110679', '59082756'],
             '2': ['41612', '242815422'], '20': ['68351', '62904950'],
             '21': ['10906908', '48084239'], '22': ['16258189', '51220722'],
             '3': ['361460', '197765535'], '4': ['264892', '190948359'],
             '5': ['140423', '180795222'], '6': ['292540', '170893669'],
             '7': ['193200', '158937463'], '8': ['116090', '146279540'],
             '9': ['116804', '141016448'],
            'X': ['200855', '155240071'],
             'Y': ['2655049', '25316236']}



# list_chrom = sorted(map(int, list(dict_ref.keys())[:-2]))
# sorted_list_chrom = list_chrom + ["X", "Y"]
# print(sorted_list_chrom)

# Parallel(n_jobs = len(dict_ref), prefer="processes")(delayed(modif_capice)(chrom) for chrom in sorted_list_chrom)

# modif_capice()
get_ref()