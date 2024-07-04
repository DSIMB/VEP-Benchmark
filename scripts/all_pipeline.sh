
#!/bin/bash

# This script automates the generation of input files and runs various tools for variant effect prediction.
# Usage: ./vep_predictions.sh /path/to/output_folder /path/to/variant_file mode genome_reference


# Functions #
usage() {
    echo "Usage: $0 -o /path/to/output_folder -f /path/to/variant_file -m [panno|ganno] -g [38|37]"
    echo "  -o   Directory where 'input_files' and 'predictions' folders will be created"
    echo "  -f   File with gene name or Uniprot ID, amino acid variation and label (mode=panno) or chr pos nuc1 nuc2 label (mode=ganno)"
    echo "  -m   Format of variant used as input, either mode 'panno' (protein annotation) or mode 'ganno' (genomic annotation)"
    echo "  -g   Genome reference: 38 or 37 (if 'ganno' choosed as mode)"
    exit 1
}


while getopts ":o:f:m:g:" opt; do
    case ${opt} in
        o )
            output_folder=$OPTARG
            ;;
        f )
            variant_file=$OPTARG
            ;;
        m )
            mode=$OPTARG
            ;;
        g )
            GR=$OPTARG
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
if [ -z "$output_folder" ] || [ -z "$variant_file" ] || [ -z "$mode" ]; then
    usage
fi

# Validate mode argument
if [[ "$mode" != "panno" && "$mode" != "ganno" ]]; then
    echo "Invalid mode: $mode. Please choose between ganno or panno."
    usage
fi

if [ "$mode" == "ganno" ]; then
    # Validate genome reference argument
    if [[ "$GR" != "38" && "$GR" != "37" ]]; then
        echo "Invalid genome reference. Please choose between 38 (GR38) or 37 (GR37)."
        usage
    fi
fi


conda_script="/home/wasabi/radjasan/miniconda3/etc/profile.d/conda.sh"
script_folder="/home/wasabi/radjasan/git/BenchVEP/scripts"
phdsnp_folder="/home/wasabi/radjasan/these/benchmark/PhDSNP/PhD-SNPg"
suspect_folder="/home/wasabi/radjasan/these/benchmark/SuSPect/suspect_package"

# Activate conda environment
source $conda_script
conda activate VESPA

# Create necessary directories
mkdir -p $output_folder/input_files
mkdir -p $output_folder/predictions

# Main Script #

if [ "$mode" == "panno" ]; then
    echo "Mode: Protein annotation (panno)"
    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $variant_file -o $output_folder 

    echo "Running Transvar"
    awk '{print $1":p."$2}' $output_folder/input_files/gene_var_tab.txt > $output_folder/input_files/gene_var_tab_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $output_folder/input_files/gene_var_tab_transvar.txt $output_folder/input_files/ $mode

elif [ "$mode" == "ganno" ]; then
    echo "Mode: Genomic annotation (ganno)"
    awk '{print "chr"$1":g."$2$3">"$4}' $variant_file > $output_folder/input_files/input_genomic_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $output_folder/input_files/input_genomic_transvar.txt $output_folder/input_files/ $mode

    awk '{print $5"\t"$6}' $output_folder/input_files/genomic_position_GR${GR}_gene_var.tsv | sort | uniq > $output_folder/input_files/gene_var_tab_from_transvar.tsv
    awk '{print $1":p."$2}' $output_folder/input_files/gene_var_tab_from_transvar.tsv > $output_folder/input_files/gene_var_tab_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $output_folder/input_files/gene_var_tab_transvar.txt $output_folder/input_files/ panno

    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py $output_folder/input_files/gene_var_tab_from_transvar.tsv $output_folder

else
    echo "Invalid mode provided. Please use 'panno' or 'ganno'."
    exit 1
fi


# Precomputed Predictions #

# # dbNSFP
mkdir  $output_folder/predictions/dbNSFP/ -p
bash $script_folder/dbNSFP/parallel_task.sh $output_folder/input_files/genomic_position_GR38.tsv  $output_folder/predictions/dbNSFP/dbNSFP_output_clean.tsv $output_folder/input_files/gene_var_tab.txt $output_folder/input_files


# # Variant database
# python $script_folder/extract_variant_databases.py $output_folder

# # Web servers #


# # # PhDSNP
# conda deactivate
# conda activate PHDSNP
# mkdir -p $output_folder/predictions/PhDSNP/
# python2 $phdsnp_folder/predict_variants.py $output_folder/input_files/genomic_position_GR38_postrand.tsv \
#         -g 38  | sort | uniq | awk 'NR > 1 {print $1"\t"$2"\t"$3"\t"$4"\t"$7}' > $output_folder/predictions/PhDSNP/PhDSNP_predictions.tsv &

# # # # SuSPect
# echo SuSPect
# mkdir -p $output_folder/predictions/SuSPect/
# perl $suspect_folder/suspect.pl --input $output_folder/input_files/id_var_tab.txt --output $output_folder/predictions/SuSPect/SuSPect_predictions_tmp.tsv
# awk  -F "\t" '{print $1"\t"$2"\t"$6}' $output_folder/predictions/SuSPect/SuSPect_predictions_tmp.tsv > $output_folder/predictions/SuSPect/SuSPect_predictions.tsv
# rm $output_folder/predictions/SuSPect/SuSPect_predictions_tmp.tsv

# GPU predictions #
# Try to run them on separate GPUs


# conda deactivate

# conda deactivate
# conda activate KOPIS
# ESM
#bash $output_folder/predictions/ESM/run_esm.sh
#bash $script_folder/cleaner/clean_ESM.sh $output_folder 

# VariPred
# mkdir $output_folder/predictions/VariPred -p
#bash $script_folder/VariPred/VariPred/predict.sh $output_folder/input_files/VariPred $output_folder/predictions/VariPred


echo "Done"
