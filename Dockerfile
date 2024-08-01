# Set base image
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
    
WORKDIR /BenchVEP
ENV PATH="/opt/conda/bin:$PATH"
ENV CONDA_PREFIX="/opt/conda"

# # Copy the dependencies file to the working directory

SHELL ["/bin/bash", "--login", "-c"]

RUN echo "yes" | cpan DBI
RUN echo "yes" | cpan DBD::SQLite

COPY envs envs
# # Install dependencies using Conda
RUN conda env create -f envs/environment.yml

# PhDSNP conda
RUN conda create -n phdsnp python=2 scipy

RUN echo $'#!/bin/bash\n\
USER_ID=${LOCAL_UID:-9001}\n\
GROUP_ID=${LOCAL_GID:-9001}\n\
useradd -u $USER_ID -o -m user\n\
groupmod -g $GROUP_ID user\n\
/data/scripts/all_pipeline_light.sh "$@"' > entrypoint.sh && chmod +x entrypoint.sh

ENTRYPOINT ["conda", "run", "-n", "VEP", "--no-capture-output",  "/BenchVEP/entrypoint.sh" ]


# # Command to run on container start
# ENTRYPOINT ["bash", "scripts/all_pipeline_light.sh"]
# ENTRYPOINT ["conda", "run", "-n", "VEP", "exec", "stdbuf", "-oL", "scripts/all_pipeline_light.sh"]

