#!/bin/bash

database_folder="./variant_databases"
transvar_folder="./transvar"

# AlphaMissense (to index)
mkdir -p $database_folder/AlphaMissense
wget https://storage.cloud.google.com/dm_alphamissense/AlphaMissense_hg38.tsv.gz -P $database_folder/AlphaMissense/
zcat $database_folder/AlphaMissense/AlphaMissense_hg38.tsv.gz | sort -k1,1 -k2,2n > $database_folder/AlphaMissense/AlphaMissense_hg38.tsv
rm $database_folder/AlphaMissense/AlphaMissense_hg38.tsv.gz
bgzip $database_folder/AlphaMissense/AlphaMissense_hg38.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/AlphaMissense/AlphaMissense_hg38.tsv.gz

# CAPICE (with index)
mkdir -p $database_folder/CAPICE
wget https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz?download=1 -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz
wget https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz.tbi?download=1 -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz.tbi

# CPT
mkdir -p $database_folder/CPT
wget https://zenodo.org/api/records/7954657/files-archive -P $database_folder/CPT

# DeepSAV
mkdir -p $database_folder/DeepSAV
wget http://prodata.swmed.edu/DBSAV/download/humanSAV.txt.gz -P $database_folder/DeepSAV

# Envision
mkdir -p $database_folder/Envision
wget https://envision.gs.washington.edu/shiny/downloads/human_predicted_combined_20170925.csv.bz2 -P $database_folder/Envision

# EVE
mkdir -p $database_folder/EVE
wget https://evemodel.org/api/proteins/bulk/download/ -O $database_folder/EVE/eve_bulk_download.zip
unzip $database_folder/EVE/eve_bulk_download.zip -d $database_folder/EVE

# InMeRF (to index)
mkdir -p $database_folder/InMeRF
wget https://www.med.nagoya-u.ac.jp/neurogenetics/InMeRF/download/InMeRF_score_hg38.txt.gz -P $database_folder/InMeRF
zcat $database_folder/InMeRF/InMeRF_score_hg38.txt.gz | sort -k1,1 -k2,2n > $database_folder/InMeRF/InMeRF_score_hg38.txt
rm $database_folder/InMeRF/InMeRF_score_hg38.txt.gz
bgzip $database_folder/InMeRF/InMeRF_score_hg38.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/InMeRF/InMeRF_score_hg38.txt.gz

# LASSIE (with index)
mkdir -p $database_folder/LASSIE
wget http://compgen.cshl.edu/LASSIE/data/LASSIE_fitness_effect_hg19.tsv.gz -P $database_folder/LASSIE
wget http://compgen.cshl.edu/LASSIE/data/LASSIE_fitness_effect_hg19.tsv.gz.tbi -P $database_folder/LASSIE

# MISTIC (to index)
mkdir -p $database_folder/MISTIC
wget https://lbgi.fr/mistic/static/data/MISTIC_GRCh38.tsv.gz -P $database_folder/MISTIC
zcat $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz | sort -k1,1 -k2,2n > $database_folder/MISTIC/MISTIC_GRCh38.tsv
rm $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz
bgzip $database_folder/MISTIC/MISTIC_GRCh38.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz

# MutFormer (to index)
mkdir -p $database_folder/MutFormer
wget http://www.openbioinformatics.org/mutformer/hg19_MutFormer.zip -P $database_folder/MutFormer
unzip $database_folder/MutFormer/hg19_MutFormer.zip -d $database_folder/MutFormer
zcat $database_folder/MutFormer/hg19_MutFormer.tsv.gz | sort -k1,1 -k2,2n > $database_folder/MutFormer/hg19_MutFormer_sorted.tsv
rm $database_folder/MutFormer/hg19_MutFormer_sorted.tsv.gz
bgzip $database_folder/MutFormer/hg19_MutFormer_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutFormer/hg19_MutFormer_sorted.tsv.gz

# MutScore (to index)
mkdir -p $database_folder/MutScore
wget https://storage.googleapis.com/rivolta_mutscore/mutscore-v1.0-hg38.tsv.gz -P $database_folder/MutScore
zcat $database_folder/MutScore/mutscore-v1.0-hg38.tsv.gz | sort -k1,1 -k2,2n > $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv
rm $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz
bgzip $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz

# PONP2 (download from Zenodo)
# Create directory
mkdir -p $database_folder/PONP2
# Note: Replace the link below with the actual download link from Zenodo
# wget <zenodo_link> -P $database_folder/PONP2

# SIGMA (to index)
mkdir -p $database_folder/SIGMA
wget https://sigma-pred.org/api/sigma/download?name=sigma_scores -O $database_folder/SIGMA/sigma_scores.txt
zcat $database_folder/SIGMA/sigma_scores.txt | sort -k1,1 -k2,2n > $database_folder/SIGMA/sigma_scores_sorted.txt
rm $database_folder/SIGMA/sigma_scores_sorted.txt.gz
bgzip $database_folder/SIGMA/sigma_scores_sorted.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/SIGMA/sigma_scores_sorted.txt.gz

# UNEECON with index
wget https://drive.usercontent.google.com/download?id=1b9Tce-R0KOWRndYzbcR4D8Ke5DLKxq9U&export=download&authuser=0&confirm=t&uuid=ba1a5e4e-ecc9-4b0a-9e37-12d4d9ffb98f&at=APZUnTXz_uSfrXcXq-6-w-01FSKw:1720446102418  -O $database_folder/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz
wget https://drive.usercontent.google.com/download?id=1pij0eosA13bgNGW9k-vvygkHGLbqNCe-&export=download&authuser=0&confirm=t&uuid=236ba200-1888-4ac4-8596-20b239db6150&at=APZUnTWY7w7U9noy8ynSU9xJfVAF:1720446135459  -O $database_folder/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz.tbi

# VARITY
mkdir -p $database_folder/VARITY
wget http://varity.varianteffect.org/downloads/varity_all_predictions.tar.gz -P $database_folder/VARITY

# VESPA
mkdir -p $database_folder/VESPA
wget https://zenodo.org/records/5905863/files/vespal_human_proteome.zip?download=1 -P $database_folder/VESPA

# dbNSFP4.4a
mkdir $database_folder/dbNSFP
wget https://usf.box.com/shared/static/bvfzmkpgtphvbmmrvb2iyl2jl21o49kc -O $database_folder/dbNSFP/dbNSFP4.4a.zip
unzip $database_folder/dbNSFP/dbNSFP4.4a.zip
rm $database_folder/dbNSFP/dbNSFP4.4a.zip
for chrom in {1..22} X Y; 
do 
    echo "Indexing chromosome $chrom...";
    zcat $database_folder/dbNSFP/dbNSFP4.4a_variant.chr${chrom}.gz  | sort -k1,1 -k2,2n > $database_folder/dbNSFP/dbNSFP4.4a_variant.chr${chrom}
    rm $database_folder/dbNSFP/dbNSFP4.4a_variant.chr${chrom}.gz
    bgzip $database_folder/dbNSFP/dbNSFP4.4a_variant.chr${chrom}
    tabix -p vcf -s 1 -b 2 -e 2 $database_folder/dbNSFP/dbNSFP4.4a_variant.chr${chrom}.gz
done 

# Reference genome hg38
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz -P $transvar_folder/hg38
gunzip $transvar_folder/hg38/hg38.fa.gz

# Reference genome hg19
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz -P $transvar_folder/hg19
gunzip $transvar_folder/hg19/hg19.fa.gz

