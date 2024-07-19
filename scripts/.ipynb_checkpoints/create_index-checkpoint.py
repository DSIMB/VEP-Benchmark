import gzip
import sys

def create_protein_index(data_file, index_file, database):
    done = {}
    if database == "Envision":
        index_protein_id = 5
    elif database == "DeepSAV":
        index_protein_id = 0
    elif database == "PONP2":
        index_protein_id = -1
                
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
    DB_file = sys.argv[1]
    output_file = sys.argv[2]
    database_name = sys.argv[3]
    create_protein_index(DB_file, output_file, database_name)
