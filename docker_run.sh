docker run --rm -it -e LOCAL_UID=$(id -u $USER) -e LOCAL_GID=$(id -g $USER) -v $(pwd):/data  vep -f time_check/clinvar_10.tsv -m panno -g 38 -n clinvar_10_final -d
