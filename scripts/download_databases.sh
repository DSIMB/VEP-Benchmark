#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

database_folder="./variant_databases"
transvar_folder="./transvar"
script_folder="./scripts"
# mkdir -p $database_folder
mkdir -p $transvar_folder


# ZENODO database file
wget "https://zenodo.org/records/12804838/files/variant_databases.zip?download=1" -O variant_databases.zip
unzip variant_databases.zip


# # Reference genome hg38
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz" -P $transvar_folder/hg38

# # Reference genome hg19
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz" -P $transvar_folder/hg19


# CAPICE (with index)
mkdir -p $database_folder/CAPICE
wget "https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz?download=1" -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz
wget "https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz.tbi?download=1" -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz.tbi

# InMeRF (to index) (Zenodo)
mkdir -p $database_folder/InMeRF
wget "https://www.med.nagoya-u.ac.jp/neurogenetics/InMeRF/download/InMeRF_score_hg38.txt.gz" -P $database_folder/InMeRF


# Download SuSPect files
mkdir -p $script_folder/suspect/
wget http://www.sbg.bio.ic.ac.uk/~suspect/suspect_package-v1.3.tar.gz -P $script_folder/suspect/

 
# Download PhD files
mkdir -p $script_folder/phdsnp/
git clone https://github.com/biofold/PhD-SNPg $script_folder/phdsnp

