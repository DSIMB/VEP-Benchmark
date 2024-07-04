grep "Benign\|Pathogenic" $1 | awk '{print $6"\t"$9}' | awk -F ":" '{print $1"\t"$2}' > $2

