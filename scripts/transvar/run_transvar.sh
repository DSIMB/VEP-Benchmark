gene_var_inputfile=$1
output_folder=$2
mode=$3
script_folder="/home/wasabi/radjasan/git/BenchVEP/scripts/"

mkdir -p $output_folder

echo Transvar GR38
transvar $mode  -l $gene_var_inputfile --ucsc --refseq --ccds --ensembl --refversion hg38 | awk -F "\t" 'NR > 2 {print $3"\t"$5}' | sort | uniq > $output_folder/clean_transvar_output_GR38.tsv
python $script_folder/transvar/clean_transvar_output.py $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv


echo Transvar GR37
transvar $mode  -l $gene_var_inputfile --ucsc --refseq --ccds --ensembl --refversion hg19 | awk -F "\t" 'NR > 2 {print $3"\t"$5}' | sort | uniq > $output_folder/clean_transvar_output_GR37.tsv
python $script_folder/transvar/clean_transvar_output.py $output_folder/clean_transvar_output_GR37.tsv $output_folder/genomic_position_GR37.tsv



echo Wrote $output_folder/clean_transvar_output_GR38.tsv $output_folder/genomic_position_GR38.tsv
echo Wrote $output_folder/clean_transvar_output_GR37.tsv $output_folder/genomic_position_GR37.tsv

