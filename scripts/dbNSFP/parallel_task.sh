# Usage
# bash parallel_task.sh /home/wasabi/radjasan/these/benchmark/VariBench/DeepSav/input_data/global/clingen_dbNSFP_all.txt /home/wasabi/radjasan/these/benchmark/VariBench/DeepSav/input_data/global/dbNSFP_output.txt /home/wasabi/radjasan/these/benchmark/VariBench/DeepSav/input_data/global/gene_var.tsv

# Input with chr pos ref alt GR38
dbnsfp_input=$1

# Output file name
dbnsfp_output=$2

# Gene Variation file
genevar_file=$3

# Input file
input_folder=$4

f() {
	python /home/wasabi/radjasan/git/BenchVEP/scripts/dbNSFP/extract_dbnsfp.py "$1" "$2" "$3"
}


for i in {1..22} X Y; do
	f $i $dbnsfp_input $dbnsfp_output &
done
wait


cat ${dbnsfp_output}.chr* > ${dbnsfp_output}
rm ${dbnsfp_output}.chr*


python  /home/wasabi/radjasan/git/BenchVEP/scripts/dbNSFP/clean_dbnsfp_data.py $genevar_file $dbnsfp_output ${dbnsfp_output}.cleaned $input_folder



