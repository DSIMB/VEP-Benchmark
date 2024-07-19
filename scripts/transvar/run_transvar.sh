variant_input_file=$1
output_folder=$2
mode=$3
GR=$4
script_folder=$5

mkdir -p $output_folder

if [ "$mode" == "ganno" ]; then
    if [ "$GR" == "38" ]; then
        transvar $mode  -l $variant_input_file --ensembl --refversion hg38 | awk -F "\t" 'NR > 2 {print $3"\t"$5}' | sort | uniq > $output_folder/clean_transvar_output_GR38.tsv
        python $script_folder/transvar/clean_transvar_output.py $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv
        echo Wrote $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv
    elif [ "$GR" == "37" ]; then
        transvar $mode  -l $variant_input_file --ensembl --refversion hg19 | awk -F "\t" 'NR > 2 {print $3"\t"$5}' | sort | uniq > $output_folder/clean_transvar_output_GR37.tsv
        python $script_folder/transvar/clean_transvar_output.py $output_folder/clean_transvar_output_GR37.tsv $output_folder/genomic_position_GR37.tsv
        echo Wrote $output_folder/clean_transvar_output_GR37.tsv $output_folder/genomic_position_GR37.tsv
    fi
elif [ "$mode" == "panno" ]; then
        transvar $mode  -l $variant_input_file --ensembl --refversion hg38 | awk -F "\t" 'NR > 2 {print $3"\t"$5}' | sort | uniq > $output_folder/clean_transvar_output_GR38.tsv
        python $script_folder/transvar/clean_transvar_output.py $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv
        echo Wrote $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv
fi
