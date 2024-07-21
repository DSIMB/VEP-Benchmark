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
    cpanminus \
    && apt-get clean
    
RUN conda update -n base -c defaults conda

# Set the working directory in the container
WORKDIR /BenchVEP
RUN echo $(ls -1 /BenchVEP)

# # Copy the dependencies file to the working directory


COPY envs envs

# # Install dependencies using Conda
RUN conda env create -f envs/environment.yml
RUN pip install -U transvar bgzip

# # Command to run on container start
ENTRYPOINT ["conda", "run", "-n", "VEP", "bash", "scripts/all_pipeline_light.sh"]

