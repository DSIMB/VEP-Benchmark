folder=$1

esm_folder=$folder/tools/ESM/
for file in $esm_folder/*csv; do f="$(basename -- $file)"; protein=${f%.*}; awk -v prot=$protein -F ','  ' NR>1{print prot"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' $file ; done > $esm_folder/ESM_predictions.tsv
