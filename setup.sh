bash scripts/download_databases.sh
docker build . -t vep
docker run --rm -it -e LOCAL_UID=$(id -u $USER) -e LOCAL_GID=$(id -g $USER) -v $(pwd):/data  vep -f /data/time_check/clinvar_10.tsv -m panno -g 38 -n clinvar_10_final -d
