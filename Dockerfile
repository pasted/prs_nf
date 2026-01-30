FROM continuumio/miniconda3:latest

LABEL maintainer="Genomics Pipeline"
LABEL description="Docker image for PRS-NF pipeline"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install conda packages
RUN conda create -n prs_nf -c conda-forge -c bioconda -y \
    plink2 \
    r-base \
    r-tidyverse \
    r-data.table && \
    conda clean -afy

# Install R packages for PRSice
RUN /opt/conda/envs/prs_nf/bin/Rscript -e "install.packages('optparse', repos='http://cran.r-project.org')"

# Set environment
ENV PATH /opt/conda/envs/prs_nf/bin:$PATH
SHELL ["/bin/bash", "-c"]

# Verify installations
RUN which plink2 && plink2 --version && R --version

WORKDIR /work
