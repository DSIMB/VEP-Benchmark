
path_data=$1
transvar config -k reference -v $(realpath $path_data/transvar/hg38/hg38.fa) --refversion hg38
transvar config -k ensembl -v $(realpath $path_data/transvar/hg38/hg38.ensembl.gtf.gz.transvardb) --refversion hg38

transvar config -k reference -v $(realpath $path_data/transvar/hg19/hg19.fa) --refversion hg19
transvar config -k ensembl -v $(realpath $path_data/transvar/hg19/hg19.ensembl.gtf.gz.transvardb) --refversion hg19