#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

database_folder="./variant_databases"
transvar_folder="./transvar"
script_folder="./scripts"
mkdir -p $database_folder
mkdir -p $transvar_folder

# CAPICE (with index)
mkdir -p $database_folder/CAPICE
wget "https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz?download=1" -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz
wget "https://zenodo.org/record/3928295/files/capice_v1.0_build37_snvs.tsv.gz.tbi?download=1" -O $database_folder/CAPICE/capice_v1.0_build37_snvs.tsv.gz.tbi

# CPT
mkdir -p $database_folder/CPT
mkdir -p $database_folder/CPT/proteome
wget "https://zenodo.org/api/records/7954657/files-archive" -O $database_folder/CPT/CPT.zip
unzip $database_folder/CPT/CPT.zip -d $database_folder/CPT
unzip $database_folder/CPT/CPT1_score_no_EVE_set_1.zip -d $database_folder/CPT
unzip $database_folder/CPT/CPT1_score_no_EVE_set_2.zip -d $database_folder/CPT
unzip $database_folder/CPT/CPT1_score_EVE_set.zip -d $database_folder/CPT
mv $database_folder/CPT/CPT1_score_no_EVE_set_1/*gz $database_folder/CPT/proteome
mv $database_folder/CPT/CPT1_score_no_EVE_set_2/*gz $database_folder/CPT/proteome
mv $database_folder/CPT/CPT1_score_EVE_set/*gz $database_folder/CPT/proteome
rmdir $database_folder/CPT/CPT1_score_no_EVE_set_1/
rmdir $database_folder/CPT/CPT1_score_no_EVE_set_2/
rmdir $database_folder/CPT/CPT1_score_EVE_set/

# DeepSAV
mkdir -p $database_folder/DeepSAV
wget "http://prodata.swmed.edu/DBSAV/download/humanSAV.txt.gz" -P $database_folder/DeepSAV

# Envision
mkdir -p $database_folder/Envision
wget "https://envision.gs.washington.edu/shiny/downloads/human_predicted_combined_20170925.csv.bz2" -P $database_folder/Envision
# Check if need redirect
bzip2 -d $database_folder/Envision/human_predicted_combined_20170925.csv.bz2
awk -F "," 'NR>2 {print $6"\t"$8"\t"$NF}' $database_folder/Envision/human_predicted_combined_20170925.csv  > $database_folder/Envision/Envision_clean.tsv

# InMeRF (to index)
mkdir -p $database_folder/InMeRF
wget "https://www.med.nagoya-u.ac.jp/neurogenetics/InMeRF/download/InMeRF_score_hg38.txt.gz" -P $database_folder/InMeRF
zcat $database_folder/InMeRF/InMeRF_score_hg38.txt.gz | sort -k1,1 -k2,2n > $database_folder/InMeRF/InMeRF_score_hg38.txt
rm $database_folder/InMeRF/InMeRF_score_hg38.txt.gz
bgzip $database_folder/InMeRF/InMeRF_score_hg38.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/InMeRF/InMeRF_score_hg38.txt.gz

# LASSIE (with index)
mkdir -p $database_folder/LASSIE
wget "http://compgen.cshl.edu/LASSIE/data/LASSIE_fitness_effect_hg19.tsv.gz" -P $database_folder/LASSIE
wget "http://compgen.cshl.edu/LASSIE/data/LASSIE_fitness_effect_hg19.tsv.gz.tbi" -P $database_folder/LASSIE

# MISTIC (to index)
mkdir -p $database_folder/MISTIC
wget "https://lbgi.fr/mistic/static/data/MISTIC_GRCh38.tsv.gz" -P $database_folder/MISTIC
zcat $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz | sed "s/chr//g" | sort -k1,1 -k2,2n > $database_folder/MISTIC/MISTIC_GRCh38.tsv
rm $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz
bgzip $database_folder/MISTIC/MISTIC_GRCh38.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MISTIC/MISTIC_GRCh38.tsv.gz

# MutFormer (to index)
mkdir -p $database_folder/MutFormer
wget "http://www.openbioinformatics.org/mutformer/hg19_MutFormer.zip" -P $database_folder/MutFormer
unzip $database_folder/MutFormer/hg19_MutFormer.zip -d $database_folder/MutFormer
sort -k1,1 -k2,2n $database_folder/MutFormer/hg19_MutFormer.txt > $database_folder/MutFormer/hg19_MutFormer_sorted.tsv
bgzip $database_folder/MutFormer/hg19_MutFormer_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutFormer/hg19_MutFormer_sorted.tsv.gz

# MutScore (to index)
mkdir -p $database_folder/MutScore
wget "https://storage.googleapis.com/rivolta_mutscore/mutscore-v1.0-hg38.tsv.gz" -P $database_folder/MutScore
zcat $database_folder/MutScore/mutscore-v1.0-hg38.tsv.gz | sort -k1,1 -k2,2n > $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv
rm $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz
bgzip $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/MutScore/mutscore-v1.0-hg38_sorted.tsv.gz

# PONP2 (site is down)
# Create directory
mkdir -p $database_folder/PONP2
# wget "<zenodo_link>" -P $database_folder/PONP2

# SIGMA (to index)
mkdir -p $database_folder/SIGMA
wget "https://sigma-pred.org/api/sigma/download?name=sigma_scores" -O $database_folder/SIGMA/sigma_scores.txt
zcat $database_folder/SIGMA/sigma_scores.txt | sort -k1,1 -k2,2n > $database_folder/SIGMA/sigma_scores_sorted.txt
rm $database_folder/SIGMA/sigma_scores_sorted.txt.gz
bgzip $database_folder/SIGMA/sigma_scores_sorted.txt
tabix -p vcf -s 1 -b 2 -e 2 $database_folder/SIGMA/sigma_scores_sorted.txt.gz

# UNEECON with index
mkdir -p $database_folder/UNEECON
wget "https://drive.usercontent.google.com/download?id=1b9Tce-R0KOWRndYzbcR4D8Ke5DLKxq9U&export=download&authuser=0&confirm=t&uuid=ba1a5e4e-ecc9-4b0a-9e37-12d4d9ffb98f&at=APZUnTXz_uSfrXcXq-6-w-01FSKw:1720446102418" -O $database_folder/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz
wget "https://drive.usercontent.google.com/download?id=1pij0eosA13bgNGW9k-vvygkHGLbqNCe-&export=download&authuser=0&confirm=t&uuid=236ba200-1888-4ac4-8596-20b239db6150&at=APZUnTWY7w7U9noy8ynSU9xJfVAF:1720446135459"  -O $database_folder/UNEECON/UNEECON_variant_score_v1.0_hg19.tsv.gz.tbi

# VESPA
mkdir -p $database_folder/VESPA
wget "https://zenodo.org/records/5905863/files/vespal_human_proteome.zip?download=1" -O $database_folder/VESPA/vespal_human_proteome.zip
unzip $database_folder/VESPA/vespal_human_proteome.zip -d $database_folder/VESPA

# dbNSFP4.7a
mkdir $database_folder/dbNSFP
mkdir $database_folder/dbNSFP/tabix_38
mkdir $database_folder/dbNSFP/tabix_19

wget "https://usf.box.com/shared/static/nqgw17r4zzuluk5ginqm33hhopiak26c" -O $database_folder/dbNSFP/dbNSFP4.7a.zip
unzip $database_folder/dbNSFP/dbNSFP4.7a.zip -d $database_folder/dbNSFP/
# rm $database_folder/dbNSFP/dbNSFP4.7a.zip,:;  
for chrom in {1..22} X Y; 
do 
    echo "Indexing chromosome $chrom...";
    zcat $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz | { head -n 1; tail -n +2 | sort -T tmp -k1,1 -k2,2n -k9,9n | awk '$9 != "."'; } > $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}
    bgzip -f $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}
    tabix -p vcf -s 1 -b 2 -e 2 $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz
    mv $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz.tbi $database_folder/dbNSFP/tabix_38
    tabix -p vcf -s 1 -b 9 -e 9 $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz
    mv $database_folder/dbNSFP/dbNSFP4.7a_variant.chr${chrom}.gz.tbi $database_folder/dbNSFP/tabix_19

done 

# Extract headers from dbNSFP files
python $script_folder/dbNSFP/dbnsfp_header.py $database_folder/dbNSFP/dbNSFP4.7a_variant.chr10.gz $script_folder

# Download SuSPect files
mkdir -p ./scripts/suspect/
wget http://www.sbg.bio.ic.ac.uk/~suspect/suspect_package-v1.3.tar.gz -P ./scripts/suspect/
tar -xvf ./scripts/suspect/suspect_package-v1.3.tar.gz -C ./scripts/suspect/
sed "s,/bmm/www/servers/suspect,./scripts/suspect/suspect_package," ./scripts/suspect/suspect_package/suspect.pl -i
sed "s,/suspect_package/data/,data/," ./scripts/suspect/suspect_package/suspect.pl -i
perl -MCPAN -e 'install DBI'
perl -MCPAN -e 'install DBD::SQLite'
 
# Download PhD files


# # Reference genome hg38
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz" -P $transvar_folder/hg38
gunzip $transvar_folder/hg38/hg38.fa.gz
samtools faidx $transvar_folder/hg38/hg38.fa.gz
transvar config -k reference -v $(realpath transvar/hg38/hg38.fa) --refversion hg38
transvar config -k ensembl -v $(realpath transvar/hg38/hg38.ensembl.gtf.gz.transvardb) --refversion hg38

# # Reference genome hg19
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz" -P $transvar_folder/hg19
gunzip $transvar_folder/hg19/hg19.fa.gz
samtools faidx $transvar_folder/hg19/hg19.fa.gz
transvar config -k reference -v $(realpath transvar/hg19/hg19.fa) --refversion hg19
transvar config -k ensembl -v $(realpath transvar/hg19/hg19.ensembl.gtf.gz.transvardb) --refversion hg19


