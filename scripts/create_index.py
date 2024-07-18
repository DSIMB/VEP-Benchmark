import gzip
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description='Generating input files needed to retrieve predictions from Variant Effect Predictors')
    parser.add_argument('-f', '--file',
                        help="Path to file containing genomic positions",
                        required=True, type=str)
    parser.add_argument('-i', '--index',
                        help="Path to file containing genomic positions",
                        required=True, type=int)
    args = parser.parse_args()
    return args


def create_protein_index(data_file, index_file, index_protein_id):
    done = {}
    with gzip.open(data_file, 'rt') as f, open(index_file, 'w') as idx:
        current_position = 0
        for line in f:
            items = line.split()
            try:
                protein_id = items[index_protein_id]
            except:
                print(line)
                continue
            if protein_id not in done:
                idx.write(f"{protein_id}\t{current_position}\n")
                done[protein_id] = 0
            current_position += len(line.encode('utf-8'))

if __name__ == "__main__":
    args = get_args()
    DB_file = args.file
    column_index = args.index
    output_file = f"{DB_file}.tbi"
    create_protein_index(DB_file, output_file, column_index)
