#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

# This script automates the generation of input files and runs various tools for variant effect prediction.
# Usage: ./vep_predictions.sh /path/to/ /path/to/variant_file mode genome_reference [index]

# Functions #
usage() {
    echo "Usage: $0 -f /path/to/variant_file -m [panno|ganno] -g [38|37] -n [output_name]"
    echo "  -f   File with gene name or Uniprot ID, amino acid variation and label (mode=panno) or chr pos nuc1 nuc2 label (mode=ganno)"
    echo "  -m   Format of variant used as input, either mode 'panno' (protein annotation) or mode 'ganno' (genomic annotation)"
    echo "  -g   Genome reference: 38 or 37 (if 'ganno' chosen as mode)"
    echo "  -n   Name of the output file with all predictions"
    exit 1
}

while getopts ":f:m:g:n:" opt; do
    case ${opt} in
        f )
            variant_file=$OPTARG
            ;;
        m )
            mode=$OPTARG
            ;;
        g )
            refgenome=$OPTARG
            ;;
        n )
            output_name=$OPTARG
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Ensure all required arguments are provided
if [ -z "$variant_file" ] || [ -z "$mode" ] || [ -z "$output_name" ]; then
    usage
fi

# Validate mode argument
if [[ "$mode" != "panno" && "$mode" != "ganno" ]]; then
    echo "Invalid mode: $mode. Please choose between ganno or panno."
    usage
fi

if [ "$mode" == "ganno" ]; then
    # Validate genome reference argument
    if [[ "$refgenome" != "38" && "$refgenome" != "37" ]]; then
        echo "Invalid genome reference. Please choose between 38 (GR38) or 37 (GR37)."
        usage
    fi
fi

# Variables #
output_folder="./$output_name"
script_folder="./scripts/"
database_folder="./variant_databases/"
input_folder="$output_folder/input_files/"
predictions_folder="$output_folder/predictions/"
phdsnp_folder="${script_folder}/PhDSNP/PhD-SNPg/"
suspect_folder="${script_folder}/SuSPect/suspect_package/"
dbnsfp_folder="$predictions_folder/dbNSFP"
dbnsfp_output="$dbnsfp_folder/dbNSFP_output.tsv"
dbNSFP_data_folder="$database_folder/dbNSFP/"

# Create necessary directories
echo "Creating $input_folder"
mkdir -p $input_folder
mkdir -p $predictions_folder


FLAG_FILE="./.first_run_complete"
if [ ! -f "$FLAG_FILE" ]; then
    echo "First run detected. Performing indexing of databases..."
    bash $script_folder/configure_databases.sh
    touch "$FLAG_FILE"
    echo "Configuration done. If you want to redo this step, please remove the file ./.first_run_complete"
fi


# # Main Script #

SECONDS=0

if [ "$mode" == "panno" ]; then
    echo "Mode: Protein annotation (panno)"
    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $variant_file -o $output_folder 
    echo "Input files Time taken: ${SECONDS} seconds" >> $variant_file.log


    SECONDS=0

    echo "Getting GR38 positions through TransVar"
    awk '{print $1":p."$2}' $input_folder/gene_var_tab.txt > $input_folder/gene_var_tab_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/gene_var_tab_transvar.txt $input_folder $mode $refgenome $script_folder
    
    echo "TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    

elif [ "$mode" == "ganno" ]; then
    echo "Mode: Genomic annotation (ganno)"
    awk '{print "chr"$1":g."$2$3">"$4}' $variant_file > $input_folder/input_genomic_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/input_genomic_transvar.txt $input_folder $mode $refgenome
    echo "TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    SECONDS=0

    awk '{print $5"\t"$6}' $input_folder/genomic_position_GR${refgenome}_gene_var.tsv | sort | uniq > $input_folder/gene_var_tab_from_transvar.tsv

    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $input_folder/gene_var_tab_from_transvar.tsv -o $output_folder
    echo "Input files Time taken: ${SECONDS} seconds" >> $variant_file.log

else
    echo "Invalid mode provided. Please use 'panno' or 'ganno'."
    exit 1
fi
# Precomputed Predictions #

# # # dbNSFP
if [ "$mode" == "ganno" ]; then
    variant_file="$input_folder/gene_var_tab_from_transvar.tsv"
fi

SECONDS=0

awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/genomic_position_GR38.tsv  > $input_folder/genomic_position_GR38_tabix.tsv

mkdir  $dbnsfp_folder -p
python $script_folder/dbNSFP/extract_dbnsfp.py -f $input_folder/genomic_position_GR38_tabix.tsv \
                                               -o $dbnsfp_output \
                                               -r $refgenome \
                                               -d $dbNSFP_data_folder

cat $dbnsfp_output.chr* > $dbnsfp_output
rm $dbnsfp_output.chr*
python  $script_folder/dbNSFP/clean_dbnsfp_data.py -f $variant_file \
                                                   -int $script_folder/intermediate_files \
                                                   -df $dbnsfp_output \
                                                   -inp $input_folder \
                                                   -o $dbnsfp_output.cleaned
                                                   


awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR37.tsv  > $input_folder/dbnsfp_genomic_position_GR37_tabix.tsv
awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR38.tsv  > $input_folder/dbnsfp_genomic_position_GR38_tabix.tsv

echo "dbNSFP Time taken: ${SECONDS} seconds" >> $variant_file.log

SECONDS=0

# # Variant database
python $script_folder/extract_variant_databases.py -d $output_folder --databases $database_folder 
echo "VEP Time taken: ${SECONDS} seconds" >> $variant_file.log

# # Web servers #

SECONDS=0

# # # PhDSNP
# mkdir -p $predictions_folder/PhDSNP/
# python2 $phdsnp_folder/predict_variants.py $input_folder/genomic_position_GR38_postrand.tsv \
#         -g 38  | sort | uniq | awk 'NR > 1 {print $1"\t"$2"\t"$3"\t"$4"\t"$7}' > $predictions_folder/PhDSNP/PhDSNP_predictions.tsv
# echo "PHD Time taken: ${SECONDS} seconds" >> $variant_file.log


# docker run -v /home/your_home:/home/your_home  phd-snpg:full] \
#                 /home/bass/PhD-SNPg/predict_variants.py /home/bass/PhD-SNPg/test/test_short_variants_hg19.tsv -g hg19

                
# # # # SuSPect
SECONDS=0

# echo SuSPect
#ls -lahrt /BenchVEP/scripts/
#ls -lahrt /BenchVEP
mkdir -p $predictions_folder/SuSPect/
perl $script_folder/suspect/suspect_package/suspect.pl --input $input_folder/id_var_tab.txt --output $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsvaa

awk  -F "\t" '{print $1"\t"$2"\t"$6}' $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsvaa > $predictions_folder/SuSPect/SuSPect_predictions.tsv
rm $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv
echo "SuSPECT Time taken: ${SECONDS} seconds" >> $variant_file.log

# # GPU predictions #

# # ESM
# #bash $predictions_folder/ESM/run_esm.sh
# #bash $script_folder/cleaner/clean_ESM.sh . 

# # Concatenate all predictions

# python $script_folder/concat_predictions.py -d . -f $variant_file -m $mode -n $output_name

# echo "Done"
