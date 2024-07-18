# Set base image
FROM ubuntu:22.04
FROM continuumio/miniconda3

LABEL program="VEP-Benchmark"
LABEL description="Title"
LABEL version="1.0"
LABEL maintainer="radja.ragou@gmail.com"

# Install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    curl \
    git \
    tabix \
    gcc \
    && apt-get clean

# Set the working directory in the container
WORKDIR /BenchVEP

# Copy the dependencies file to the working directory
COPY envs/environment.yml .

# Install dependencies using Conda
RUN conda env create -f environment.yml

 # Ensure the conda environment is activated
SHELL ["conda", "run", "-n", "VEP", "/bin/bash", "-c"]


# RUN conda activate VEP

# Copy the content of the local scripts directory to the working directory
COPY scripts/download_databases.sh .

# Install databases
RUN bash download_databases.sh



# Command to run on container start
ENTRYPOINT ["conda", "run", "-n", "VEP", "--no-capture-output", "./scripts/all_pipeline_light.sh"]
CMD ["--help"]
