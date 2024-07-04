folder=$1

vespa_folder=$folder/tools/VESPA/
for file in $vespa_folder/results/*csv; do f="$(basename -- $file)"; protein=${f%.*}; awk -v prot=$protein -F ';'  ' NR>1{print prot"\t"$1"\t"$2}' $file ; done > $vespa_folder/VESPA_predictions.tsv
