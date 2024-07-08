
#!/bin/bash

# This script automates the generation of input files and runs various tools for variant effect prediction.
# Usage: ./vep_predictions.sh /path/to. /path/to/variant_file mode genome_reference


# Functions #
usage() {
    echo "Usage: $0 -f /path/to/variant_file -m [panno|ganno] -g [38|37]"
    echo "  -f   File with gene name or Uniprot ID, amino acid variation and label (mode=panno) or chr pos nuc1 nuc2 label (mode=ganno)"
    echo "  -m   Format of variant used as input, either mode 'panno' (protein annotation) or mode 'ganno' (genomic annotation)"
    echo "  -g   Genome reference: 38 or 37 (if 'ganno' choosed as mode)"
    echo "  -n   Name of the output file with predictions"
    exit 1
}


while getopts ":o:f:m:g:n:" opt; do
    case ${opt} in
        f )
            variant_file=$OPTARG
            ;;
        m )
            mode=$OPTARG
            ;;
        g )
            RefGenome=$OPTARG
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
if [ -z "." ] || [ -z "$variant_file" ] || [ -z "$mode" ] || [ -z "$output_name" ]; then
    usage
fi

# Validate mode argument
if [[ "$mode" != "panno" && "$mode" != "ganno" ]]; then
    echo "Invalid mode: $mode. Please choose between ganno or panno."
    usage
fi

if [ "$mode" == "ganno" ]; then
    # Validate genome reference argument
    if [[ "$RefGenome" != "38" && "$RefGenome" != "37" ]]; then
        echo "Invalid genome reference. Please choose between 38 (GR38) or 37 (GR37)."
        usage
    fi
fi


conda_script="/home/wasabi/radjasan/miniconda3/etc/profile.d/conda.sh"
script_folder="/home/wasabi/radjasan/git/BenchVEP/scripts/"
phdsnp_folder="/home/wasabi/radjasan/these/benchmark/PhDSNP/PhD-SNPg/"
suspect_folder="/home/wasabi/radjasan/these/benchmark/SuSPect/suspect_package/"
dbNSFP_data_folder="/dsimb/glaciere/radjasan/dbNSFP/academic/"
input_folder="./input_files/"
predictions_folder="./predictions/"

# Activate conda environment
source $conda_script
conda activate VESPA

# Create necessary directories
mkdir -p $input_folder
mkdir -p $predictions_folder

# # Main Script #

SECONDS=0

if [ "$mode" == "panno" ]; then
    echo "Mode: Protein annotation (panno)"
    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $variant_file -o . 
    echo "Input files Time taken: ${SECONDS} seconds" >> $variant_file.log


    SECONDS=0

    echo "Getting GR38 positions through TransVar"
    awk '{print $1":p."$2}' $input_folder/gene_var_tab.txt > $input_folder/gene_var_tab_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/gene_var_tab_transvar.txt $input_folder $mode $RefGenome
    
    echo "TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    

elif [ "$mode" == "ganno" ]; then
    echo "Mode: Genomic annotation (ganno)"
    awk '{print "chr"$1":g."$2$3">"$4}' $variant_file > $input_folder/input_genomic_transvar.txt
    bash $script_folder/transvar/run_transvar.sh $input_folder/input_genomic_transvar.txt $input_folder $mode $RefGenome
    echo "TRANSVAR Time taken: ${SECONDS} seconds" >> $variant_file.log
    SECONDS=0

    awk '{print $5"\t"$6}' $input_folder/genomic_position_GR${RefGenome}_gene_var.tsv | sort | uniq > $input_folder/gene_var_tab_from_transvar.tsv

    echo "Generating input files: genevar, idvar, geneseq, ESM, VariPred"
    python $script_folder/generate_input.py -f $input_folder/gene_var_tab_from_transvar.tsv -o .
    echo "Input files Time taken: ${SECONDS} seconds" >> $variant_file.log

else
    echo "Invalid mode provided. Please use 'panno' or 'ganno'."
    exit 1
fi
# Precomputed Predictions #

# # dbNSFP
if [ "$mode" == "ganno" ]; then
    variant_file="$input_folder/gene_var_tab_from_transvar.tsv"
fi
dbnsfp_folder="$predictions_folder/dbNSFP"
dbnsfp_output="$dbnsfp_folder/dbNSFP_output.tsv"

SECONDS=0

mkdir  $dbnsfp_folder -p
python $script_folder/dbNSFP/extract_dbnsfp.py -f $input_folder/genomic_position_GR38.tsv \
                                               -o $dbnsfp_output \
                                               -r $RefGenome \
                                               -d $dbNSFP_data_folder

cat $dbnsfp_output.chr* > $dbnsfp_output
rm $dbnsfp_output.chr*
python  $script_folder/dbNSFP/clean_dbnsfp_data.py -f $variant_file \
                                                   -int $script_folder/intermediate_files \
                                                   -df $dbnsfp_output \
                                                   -o $dbnsfp_output.cleaned


awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR37.tsv  > $input_folder/dbnsfp_genomic_position_GR37_tabix.tsv
awk '$2 != "." {print $1":"$2"-"$2"\t"$3"\t"$4}' $input_folder/dbnsfp_genomic_position_GR38.tsv  > $input_folder/dbnsfp_genomic_position_GR38_tabix.tsv

echo "dbNSFP Time taken: ${SECONDS} seconds" >> $variant_file.log

SECONDS=0

# # Variant database
python $script_folder/extract_variant_databases.py -d .
echo "VEP Time taken: ${SECONDS} seconds" >> $variant_file.log

# # Web servers #

SECONDS=0

# # # PhDSNP
conda deactivate
conda activate PHDSNP
mkdir -p $predictions_folder/PhDSNP/
python2 $phdsnp_folder/predict_variants.py $input_folder/genomic_position_GR38_postrand.tsv \
        -g 38  | sort | uniq | awk 'NR > 1 {print $1"\t"$2"\t"$3"\t"$4"\t"$7}' > $predictions_folder/PhDSNP/PhDSNP_predictions.tsv
echo "PHD Time taken: ${SECONDS} seconds" >> $variant_file.log

# # # # SuSPect
SECONDS=0

echo SuSPect
mkdir -p $predictions_folder/SuSPect/
perl $suspect_folder/suspect.pl --input $input_folder/id_var_tab.txt --output $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv
awk  -F "\t" '{print $1"\t"$2"\t"$6}' $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv > $predictions_folder/SuSPect/SuSPect_predictions.tsv
rm $predictions_folder/SuSPect/SuSPect_predictions_tmp.tsv
echo "SuSPECT Time taken: ${SECONDS} seconds" >> $variant_file.log

# GPU predictions #
# Try to run them on separate GPUs


# conda deactivate

# conda deactivate
# conda activate KOPIS
# ESM
#bash $predictions_folder/ESM/run_esm.sh
#bash $script_folder/cleaner/clean_ESM.sh . 

# Concatenate all predictions

python concat_predictions.py -d . -f $variant_file -m $mode -n $output_name

echo "Done"
