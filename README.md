(github still under development)
# Benchmark VEP
Here are scripts and data used for the paper Assessment of Variant Effect Predictors Unveils Variants Difficulty as a Critical Performance Indicator. 

## Data
Data description

## Pipeline
Provided pipeline allows you to retrieve 65 predictions from Variant Effect Predictors (VEPs) by using dbNSFP database, precomputed predictions or scripts provided by authors for concerned VEPs.

### Requirements

#### Databases

To retrieve predictions, you will need to download each databases required by running the script `download_databases.sh`:

```bash
bash scripts/download_databases.sh
```

- This will download precomputed predictions for: AlphaMissense, CAPICE, CPT, DeepSAV, Envision, EVE, InMeRF, LASSIE, MISTIC, UNEECON, VARITY, VESPA and dbNSFP4.4a.
- The dbNSFP4.4a database contains precomputed predictions for: SIFT, SIFT4G, Polyphen2_HDIV, Polyphen2_HVAR, LRT, MutationTaster, MutationAssessor, FATHMM, PROVEAN, VEST4, MetaSVM, MetaLR, MetaRNN, M-CAP, REVEL, MutPred, MVP, gMVP, MPC, PrimateAI, DEOGEN2, BayesDel_addAF, BayesDel_noAF, ClinPred, LIST-S2, VARITY_R, VARITY_ER, VARITY_R_LOO, VARITY_ER_LOO, DANN, fathmm-MKL_coding, fathmm-XF_coding, GenoCanyon, integrated_fitCons, GM12878_fitCons, H1-hESC_fitCons, HUVEC_fitCons, CADD, Eigen-raw_coding, Eigen-PC-raw_coding, GERP++, phastCons100way_vertebrate, phastCons470way_mammalian, phastCons17way_primate, SiPhy_29way_logOdds, and bStatistic.
- Approximately 80 GB of disk space is needed for the download of databases.
- Some databases support indexing (database with genomic position), this is handled within the script. This index will speed up the retrieving of predictions.

#### Docker
If you are familiar with docker, you can use the docker image provided within this repo to download every necessary packages. To build the image, run:
   
```bash
docker build -t vep . # vep is just the name of the image built, put whatever you want
```

Then, you can direcly run the pipeline script with this example command line (also present in the docker_run.sh script) :

   
```bash
docker run --rm -it -e LOCAL_UID=$(id -u $USER) -e LOCAL_GID=$(id -g $USER) -v $(pwd):/data  vep -f /data/time_check/clinvar_10.tsv -m panno -g 38 -n clinvar_10_final -d
```

Be aware to use the `-d` option, indicating that the main script is running through a docker image. 

If your variant file is in the same folder as the repo (in the `$(pwd)`, please add `/data/` before the path of the variant file, since the repo will be mounted in the docker image. If the file is not in the repo, you need to use the following command line : 

```bash
docker run --rm -it -e LOCAL_UID=$(id -u $USER) -e LOCAL_GID=$(id -g $USER) -v $(pwd):/data -v external_folder:/ext vep -f /ext/time_check/clinvar_10.tsv -m panno -g 38 -n clinvar_10_final -d
```
Changed options are `-v external_folder:/ext vep -f /ext/time_check/clinvar_10.tsv`, which create another mount within the docker image corresponding to the folder containing the variant file. 

Usage of the pipeline script is described below. 

#### Conda Environments

Two Conda environments are required:
1. **Main Environment**: Set up using the `environment.yml` file:
   
```bash
conda env create -f envs/environment.yml
```

2. **Secondary Environment**: Use this environment specifically for retrieving predictions from PhD-SNPg, as it requires Python 2 compatibility:
   
```bash
conda create -n phdsnp python=2 scipy
```

---

#### Tabix
Tabix is used to create index files for large database of genomic positions, which significantly speed up data retrieving. It must be installed using `apt-get install`:
```bash
 sudo apt-get install tabix
```

### Usage

* panno mode
  
If your input file resembles the following format

```bash
B3GALT6 P36T    Benign
ATAD3A  R218W   Pathogenic
ESPN    R113C   Benign
CAMTA1  I589V   Benign
CAMTA1  R1135W  Pathogenic
RERE    H1272R  Benign
ATP13A2 R460Q   Benign
ATP13A2 R76Q    Benign
SDHB    R230C   Pathogenic
SDHB    S163P   Benign
```

Then you want to use the **panno** (protein annotations) mode of the pipeline by running 

```bash
conda activate VEP
bash scripts/all_pipeline_light.sh -f variant_file.tsv -m panno -g 38
```
* ganno mode

Otherwise, if your data are in the following format

```bash
7 143342009 C T Pathogenic
3 25733901 G A  Pathogenic
5 176891149 G A Benign
13 20189344 G A Pathogenic
4 39215732 A T  Benign
4 154565832 C T Pathogenic
17 41725075 T C Benign
16 78099348 C T Benign
2 54649628 G A  Benign
1 167431690 G A Benign
```
Then you want to use the **ganno** (genomic annotations) mode of the pipeline by running 

```bash
bash scripts/all_pipeline_light.sh -f variant_file.tsv -m ganno -g 38
```
If genomic position are from GR37 reference genome, use instead
```bash

bash scripts/all_pipeline_light.sh -f variant_file.tsv -m ganno -g 37
```


The pipeline will generate two main folders:
- **input_files**: Contains all input files necessary to properly extract predictions.
- **predictions**: Each subfolder corresponds to a specific VEP and contains prediction files.
```bash
.
├── input_files
│   └── ESM1v
└── predictions
    ├── AlphaMissense
    ├── CAPICE
    ├── CPT
    ├── dbNSFP
    ├── DeepSAV
    ├── Envision
    ├── ESM1b
    ├── ESM1v
    ├── EVE
    ├── InMeRF
    ├── LASSIE
    ├── MISTIC
    ├── MutFormer
    ├── MutScore
    ├── PhDSNP
    ├── PONP2
    ├── SIGMA
    ├── SuSPect
    ├── UNEECON
    ├── VARITY
    └── VESPA
```


### Suggestions
If you have suggestions for optimizing the pipeline or would like us to add additional databases, please reach out to us by posting on GitHub or sending an email to radja.ragou@gmail.com.

### Reference
paper

