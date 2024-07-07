# Benchmark VEP
Here are scripts and data used for the paper X. 

## Data
Data description

## Pipeline
Provided pipeline allows you to retrieve 65 predictions from Variant Effect Predictors (VEPs) by using dbNSFP database, precomputed predictions or scripts provided by authors for concerned VEPs.

### Requirements
1. Databases
In order to retrieve predictions, you will need to download those from Zenodo:
* Link Zenodo
* Storage Required: Approximately X GB of disk space is needed for the download.
  
3. Conda environments
One main conda environment is required to run almost everything, and a second conda environment is required to retrieve predictions from PhD-SNPg as authors have provided scripts using python2, which is not compatible with others main dependencies.

To set up the main conda environment, use the `environment.yml` file:

```bash
conda env create -f environment.yml
conda activate VEP
```

### Installation

### Usage


#### Input File Format
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
bash ../scripts/all_pipeline_light.sh -f file.tsv -m panno -g 38
```

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
bash ../scripts/all_pipeline_light.sh -f file.tsv -m ganno -g 38
```
If genomic position are from GR37 reference genome, use instead
```bash

bash ../scripts/all_pipeline_light.sh -f file.tsv -m ganno -g 37
```


The pipeline will generate two main folder:
* input_files: Containing all input files necessarily to properly extract predictions 
* predictions: Each folder contain one file with all predictions for the specific VEP. Note that the folder dbNSFP 
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
