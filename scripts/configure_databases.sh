#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

path_data=$1
database_folder="$path_data/variant_databases"
transvar_folder="$path_data/transvar"
script_folder="$path_data/scripts"


# Reference genome hg38
echo "Configuring reference genome hg38..."
gunzip $transvar_folder/hg38/hg38.fa.gz
samtools faidx $transvar_folder/hg38/hg38.fa.gz
transvar config -k reference -v $(realpath $path_data/transvar/hg38/hg38.fa) --refversion hg38
transvar config -k ensembl -v $(realpath $path_data/transvar/hg38/hg38.ensembl.gtf.gz.transvardb) --refversion hg38

# Reference genome hg19
echo "Configuring reference genome hg19..."
gunzip $transvar_folder/hg19/hg19.fa.gz
samtools faidx $transvar_folder/hg19/hg19.fa.gz
transvar config -k reference -v $(realpath $path_data/transvar/hg19/hg19.fa) --refversion hg19
transvar config -k ensembl -v $(realpath $path_data/transvar/hg19/hg19.ensembl.gtf.gz.transvardb) --refversion hg19



# Envision
echo "Configuring Envision database..."
bzip2 -d $database_folder/Envision/human_predicted_combined_20170925.csv.bz2
awk -F "," 'NR>2 && $6 != "" {print $6"\t"$8"\t"$NF}' $database_folder/Envision/human_predicted_combined_20170925.csv | sort -k1,1 -k2,2 > $database_folder/Envision/Envision_clean.tsv
python $script_folder/create_index.py --file $database_folder/Envision/Envision_clean.tsv -i 0

# DeepSAV
echo "Configuring DeepSAV database..."
zcat $database_folder/DeepSAV/humanSAV.txt.gz | awk '{print $1"\t"$3$2$4"\t"$5}' | uniq  | sort -k1,1 -k2,2 | gzip > $database_folder/DeepSAV/humanSAV_light.txt.gz
python $script_folder/create_index.py --file $database_folder/DeepSAV/humanSAV_light.txt.gz -i 0



# InMeRF (to index)
echo "Configuring InMeRF database..."
bgzip -f $database_folder/InMeRF/InMeRF_score_hg38.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/InMeRF/InMeRF_score_hg38.txt.gz

# MISTIC (to index)
echo "Configuring MISTIC database..."
bgzip -f $database_folder/MISTIC/MISTIC_GRCh38.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz

# MutFormer (to index)
echo "Configuring MutFormer database..."
bgzip $database_folder/MutFormer/hg19_MutFormer_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutFormer/hg19_MutFormer_sorted.tsv.gz

# MutScore (to index)
echo "Configuring MutScore database..."
bgzip -f $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz

# SIGMA (to index)
echo "Configuring SIGMA database..."
bgzip -f $database_folder/SIGMA/sigma_scores_sorted.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/SIGMA/sigma_scores_sorted.txt.gz

# dbNSFP4.7a
echo "Configuring dbNSFP4.7a database..."
for chrom in {1..22} X Y; 
do 
    echo "Indexing chromosome $chrom..."
    zcat $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz | { head -n 1; tail -n +2 | sort -k1,1 -k2,2n -k9,9n | awk '$9 != "."'; } > $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}
    bgzip -f $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}
    tabix -p vcf -s 1 -b 2 -e 2 $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz
    mv $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz.tbi $database_folder/dbNSFP/tabix_38
    tabix -p vcf -s 1 -b 9 -e 9 $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz
    mv $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz.tbi $database_folder/dbNSFP/tabix_19
done 

# Extract headers from dbNSFP files
echo "Extracting headers from dbNSFP files..."
python $script_folder/dbNSFP/dbnsfp_header.py $database_folder/dbNSFP/dbNSFP4.7a_variant.chr10.gz $script_folder

# Download SuSPect files
echo "Setting up SuSPect database..."
perl -MCPAN -e 'install DBI'
perl -MCPAN -e 'install DBD::SQLite'

