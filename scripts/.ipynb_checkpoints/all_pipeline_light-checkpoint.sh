#!/bin/bash
# improve oneline bgzip
# Set path to git folder ?

# This script automates the generation of input files and runs various tools for variant effect prediction.
# Usage: ./vep_predictions.sh /path/to/ /path/to/variant_file mode genome_reference [index]

# Functions #


usage() {
    echo "[INFO] Usage: $0 -f /path/to/variant_file -m [panno|ganno] -g [38|37] -n [output_name] [-d]"
    echo "[INFO]   -f   File with gene name or Uniprot ID, amino acid variation and label (mode=panno) or chr pos nuc1 nuc2 label (mode=ganno)"
    echo "[INFO]   -m   Format of variant used as input, either mode 'panno' (protein annotation) or mode 'ganno' (genomic annotation)"
    echo "[INFO]   -g   Genome reference: 38 or 37 (if 'ganno' chosen as mode)"
    echo "[INFO]   -n   Name of the output file with all predictions"
    echo "[INFO]   -d   Name of the output file with all predictions"
    exit 1
}

docker_flag="false"

while getopts ":f:m:g:n:docker:" opt; do
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
        d )
            docker_flag=true
            ;;
        \? )
            echo "[INFO] Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "[INFO] Option -$OPTARG requires an argument." >&2
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
    echo "[INFO] Invalid mode: $mode. Please choose between ganno or panno."
    usage
fi

if [ "$mode" == "ganno" ]; then
    # Validate genome reference argument
    if [[ "$refgenome" != "38" && "$refgenome" != "37" ]]; then
        echo "[INFO] Invalid genome reference. Please choose between 38 (GR38) or 37 (GR37)."
        usage
    fi
fi


if [ ! -f "$variant_file" ]; then
    echo "Variant file "$variant_file" does not exists. Please provide an existing one."
    if [ "$docker_flag" = true ]; then
        echo "(i) If the variant file is in the current directory (the github folder), please add '/data/' before the name of the file."
        echo "Example: -f example/clinvar.tsv --> -f /data/example/clinvar.tsv\n"
        echo "(ii) If the file is outside the current directory, add the following to the docker run command:"
        echo "Example: -f /path/to/external_folder/clinvar.tsv --> -v /path/to/external_folder/:/ext_data -f /ext_data/clinvar.tsv"
    fi
    exit 1
fi
path_data="."; [ "$docker_flag" = true ] && path_data="/data" 

# Variables #
output_folder="$path_data/$output_name"
script_folder="$path_data/scripts/"
database_folder="$path_data/variant_databases/"
multi_fasta_file="$path_data/uniprot/uniprot_28_2A_29_2-2023.03.28-13.08.10.56.fasta"
input_folder="$output_folder/input_files/"
predictions_folder="$output_folder/predictions/"
phdsnp_folder="$script_folder/phdsnp/"
suspect_folder="$script_folder/SuSPect/suspect_package/"
dbnsfp_folder="$predictions_folder/dbNSFP"
dbnsfp_output="$dbnsfp_folder/dbNSFP_output.tsv"
dbNSFP_data_folder="$database_folder/dbNSFP/"
# Create necessary directories
echo "[INFO] All output files will be generated in the '$output_name' folder"
mkdir -p $input_folder
mkdir -p $predictions_folder


FLAG_FILE="$path_data/.first_run_complete"
if [ ! -f "$FLAG_FILE" ]; then
    echo "[INFO] First run detected. Performing indexing of databases..."
    bash $script_folder/configure_databases.sh $path_data 
    touch "$FLAG_FILE"
    echo "[INFO] Configuration done. If you want to redo this step, please remove the file $path_data/.first_run_complete"
else
    echo "[INFO] Skipping database configuration."
    output_transvar=$(transvar "$mode" --refversion "$refgenome" 2>&1)
    if echo "[INFO] $output_transvar" | grep -q "NoSectionError"; then
        bash $script_folder/configure_transvar.sh $path_data
    fi
fi

# # Main Script #

SECONDS=0

if [ "$mode" == "panno" ]; then
    echo "[INFO] Mode: Protein annotation (panno)"
    echo "[INFO] Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $variant_file \
                                            -o $output_folder  \
                                            -s $script_folder \
                                            --fasta_file $multi_fasta_file

    echo "[INFO] Input files Time taken: ${SECONDS} seconds" >> $variant_file.log


    SECONDS=0

    echo "[INFO] Getting GR38 positions through TransVar"
    awk '{print $1":p."$2}' $input_folder/gene_var_tab.txt > $input_folder/gene_var_tab_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/gene_var_tab_transvar.txt $input_folder $mode $refgenome $script_folder
    
    echo "[INFO] TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    

elif [ "$mode" == "ganno" ]; then
    echo "[INFO] Mode: Genomic annotation (ganno)"
    awk '{print "chr"$1":g."$2$3">"$4}' $variant_file > $input_folder/input_genomic_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/input_genomic_transvar.txt $input_folder $mode $refgenome
    echo "[INFO] TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    SECONDS=0

    awk '{print $5"\t"$6}' $input_folder/genomic_position_GR${refgenome}_gene_var.tsv | sort | uniq > $input_folder/gene_var_tab_from_transvar.tsv

    echo "[INFO] Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $input_folder/gene_var_tab_from_transvar.tsv \
                                            -o $output_folder \
                                            -s $script_folder \
                                            --fasta_file $multi_fasta_file

    echo "[INFO] Input files Time taken: ${SECONDS} seconds" >> $variant_file.log

else
    echo "[INFO] Invalid mode provided. Please use 'panno' or 'ganno'."
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
                                                   -I $script_folder/intermediate_files \
                                                   -d $dbnsfp_output \
                                                   -i $input_folder \
                                                   -o $dbnsfp_output.cleaned \
                                                   -m $multi_fasta_file
                                                   


awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR37.tsv  > $input_folder/dbnsfp_genomic_position_GR37_tabix.tsv
awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR38.tsv  > $input_folder/dbnsfp_genomic_position_GR38_tabix.tsv

echo "[INFO] dbNSFP Time taken: ${SECONDS} seconds" >> $variant_file.log

SECONDS=0

# # Variant database
python $script_folder/extract_variant_databases.py -d $output_folder --databases $database_folder 
echo "[INFO] VEP Time taken: ${SECONDS} seconds" >> $variant_file.log

# # Web servers #


                
# # # # SuSPect
SECONDS=0

# echo S[INFO] uSPect
#ls -lahrt /BenchVEP/scripts/
#ls -lahrt /BenchVEP

mkdir -p $predictions_folder/SuSPect/

if [ -f "$predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv" ]; then
    rm $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv
fi

perl $script_folder/suspect/suspect_package/suspect.pl --input $input_folder/id_var_tab.txt --output $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv

awk  -F "\t" '{print $1"\t"$2"\t"$6}' $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv > $predictions_folder/SuSPect/SuSPect_predictions.tsv
rm $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv
echo "[INFO] SuSPECT Time taken: ${SECONDS} seconds" >> $variant_file.log


# # Concatenate all predictions
SECONDS=0

python $script_folder/concat_predictions.py -d $output_folder \
                                            -f $variant_file \
                                            -m $mode \
                                            -n $output_name \
                                            -I $script_folder/intermediate_files

# python $script_folder/compute_labels.py

echo "[INFO] Concatenation Time taken: ${SECONDS} seconds" >> $variant_file.log

if [ "$esm" = true ]; then
    # GPU predictions #
    echo "\n[INFO] ESM1v runs are quite long."
    echo "[INFO] All extracted variants so far are already in '$output_name/${output_name}_predictions.tsv' file if you want them before finishing ESM1v runs"
    # ESM
    bash $predictions_folder/ESM/run_esm.sh
    bash $script_folder/cleaner/clean_ESM.sh $predictions_folder
fi
SECONDS=0

# # # PhDSNP
mkdir -p $predictions_folder/PhDSNP/
eval "$(conda shell.bash hook)"
conda activate phdsnp
python2 $phdsnp_folder/predict_variants.py $input_folder/dbnsfp_genomic_position_GR38.tsv  \
        -g 38  | sort | uniq | awk 'NR > 1 {print $1"\t"$2"\t"$3"\t"$4"\t"$7}' > $predictions_folder/PhDSNP/PhDSNP_predictions.tsv
echo "[INFO] PHD Time taken: ${SECONDS} seconds" >> $variant_file.log


# python $script_folder/concat_predictions.py -d $output_folder \
#                                             -f $variant_file \
#                                             -m $mode \
#                                             -n $output_name \
#                                             -I $script_folder/intermediate_files

# python $script_folder/compute_labels.py

echo "\n[INFO] Variant extraction done. Find all generated files in the '$output_name' folder"
echo "[INFO] All predictions are in the '$output_name/${output_name}_predictions.tsv' file"
