#!/usr/bin/env bash

# This script generates a conda lock file, which can be used to create an "exact" replica
# of our analysis kernal environment

conda_env=$(grep name: environment.yml | awk '{print $2}')

source activate ${conda_env}

rm -f pip-version-list.txt
pip_dep=$(python pip_dependencies.py)
for p in ${pip_dep}; do
    conda list ${p} | tail -n 1 >> pip-version-list.txt
done

# generate the lockfiles
conda-lock -f environment.yml -p osx-64 -p linux-64

