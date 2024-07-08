
gunzip transvar/hg38/hg38.fa
transvar config -k reference -v $(realpath transvar/hg38/hg38.fa) --refversion hg38
transvar config -k ensembl -v $(realpath transvar/hg38/hg38.ensembl.gtf.gz.transvardb) --refversion hg38

gunzip transvar/hg19/hg19.fa
transvar config -k reference -v $(realpath transvar/hg19/hg19.fa) --refversion hg19
transvar config -k ensembl -v $(realpath transvar/hg19/hg19.ensembl.gtf.gz.transvardb) --refversion hg19


