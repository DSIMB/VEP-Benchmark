#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

path_data=$1
database_folder="$path_data/variant_databases"
transvar_folder="$path_data/transvar"
script_folder="$path_data/scripts"


# # Reference genome hg38
echo "Configuring reference genome hg38..."
gunzip $transvar_folder/hg38/hg38.fa.gz
samtools faidx $transvar_folder/hg38/hg38.fa
transvar config -k reference -v $(realpath $path_data/transvar/hg38/hg38.fa) --refversion hg38
transvar config -k ensembl -v $(realpath $path_data/transvar/hg38/hg38.ensembl.gtf.gz.transvardb) --refversion hg38

# # Reference genome hg19
echo "Configuring reference genome hg19..."
gunzip $transvar_folder/hg19/hg19.fa.gz
samtools faidx $transvar_folder/hg19/hg19.fa
transvar config -k reference -v $(realpath $path_data/transvar/hg19/hg19.fa) --refversion hg19
transvar config -k ensembl -v $(realpath $path_data/transvar/hg19/hg19.ensembl.gtf.gz.transvardb) --refversion hg19




# # InMeRF (to index)
echo "Configuring InMeRF database..."
bgzip -f $database_folder/InMeRF/InMeRF_score_hg38.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/InMeRF/InMeRF_score_hg38.txt.gz


# Download SuSPect files
echo "Setting up SuSPect database..."
tar -xvf $script_folder/suspect/suspect_package-v1.3.tar.gz -C $script_folder/suspect/
sed "s,/bmm/www/servers/suspect,$script_folder/suspect/suspect_package," $script_folder/suspect/suspect_package/suspect.pl -i
sed "s,/suspect_package/data/,data/," $script_folder/suspect/suspect_package/suspect.pl -i


echo "Setting up PhD-SNPg database..."
mkdir -p $script_folder/phdsnp/
git clone https://github.com/biofold/PhD-SNPg $script_folder/phdsnp
echo "Running $script_folder/phdsnp/setup.py from PhD-SNPg github... \
(can take hours, output text will be in $script_folder/phdsnp/.setup_output if needed)"
eval "$(conda shell.bash hook)"
conda activate phdsnp
python2 $script_folder/phdsnp/setup.py install linux.x86_64 >  $script_folder/phdsnp/.setup_output