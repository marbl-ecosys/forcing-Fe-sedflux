#!/usr/bin/env bash
set -e

source activate forcing-Fe-sedflux

# ensure that `black` cache dir exists
# https://github.com/ryantam626/jupyterlab_code_formatter/issues/10
# https://github.com/psf/black/issues/1223
# https://github.com/psf/black/pull/1224
black_cache_dir=/glade/u/home/${USER}/.cache/black/19.10b0
if [ ! -d ${black_cache_dir} ]; then
    mkdir -p ${black_cache_dir}
fi

topo_product=etopo1

# hardwire paths that are set elsewhere in the Python workflow
# these would better reside in a single place
dirwork=/glade/work/${USER}/cesm_inputdata/work



echo '---------------------------------------'
echo 'Ensure topograpy files'
papermill -k python -p product ${topo_product} \
    _ensure_etopo_data.ipynb _ensure_etopo_data.ipynb

echo


echo '---------------------------------------'
echo 'Ensure grid files'
papermill -k python \
    _ensure_grid_files.ipynb _ensure_grid_files.ipynb

echo


echo '---------------------------------------'
echo 'Ensure weight files'
# TODO: remove this when regridding is turn-key
gridfile_directory=/glade/work/${USER}/esmlab-regrid
weight_files=(
        etopo1_to_POP_gx1v7_conservative.nc
        etopo1_to_POP_gx3v7_conservative.nc
        etopo1_to_POP_tx0.1v3_conservative.nc
)
err_etopo=0
for file in ${weight_files[@]}; do
  if [ ! -f ${gridfile_directory}/weights/${file} ]; then
    echo "missing: ${file}"
    err_etopo=1
  fi
done

weight_files=(
        POP_gx1v7_to_POP_gx3v7_conservative.nc
        POP_gx1v7_to_POP_tx0.1v3_conservative.nc
        POP_gx3v7_to_POP_gx1v7_conservative.nc
        POP_gx3v7_to_POP_tx0.1v3_conservative.nc
        POP_tx0.1v3_to_POP_gx1v7_conservative.nc
        POP_tx0.1v3_to_POP_gx3v7_conservative.nc
)
err_pop=0
for file in ${weight_files[@]}; do
  if [ ! -f ${gridfile_directory}/weights/${file} ]; then
    echo "missing: ${file}"
    err_pop=1
  fi
done

if [ ${err_etopo} == 1 ]; then
   echo
   echo "run the following:"
   echo "qsub < esmf_gen_weights_etopo1_to_POP.pbs"
   echo
fi
if [ ${err_pop} == 1 ]; then
   echo
   echo "run the following:"
   echo "qsub < esmf_gen_weights_POP_to_POP.pbs"
   echo
fi

if [ ${err_etopo} == 1 ] || [ ${err_pop} == 1 ]; then
  exit 1
fi

echo "All weight files present."
echo

echo '---------------------------------------'
echo 'Process POC flux and Velocity data'
papermill -k python \
    _poc_flux_bottom_velocity_inputs.ipynb _poc_flux_bottom_velocity_inputs.ipynb

echo


# compute the fesedflux for each grid
for dst_grid in POP_tx0.1v3 POP_gx1v7 POP_gx3v7; do
    
    dirout=output/${dst_grid}
    if [ ! -d ${dirout} ]; then
        mkdir -p ${dirout}
    fi
   
    for nb in _sedfrac_compute.ipynb Fe_sediment_flux_forcing.ipynb; do
        echo '---------------------------------------'
        echo "${nb}: ${dst_grid}"

        papermill -k python ${nb} ${dirout}/${nb} -p dst_grid ${dst_grid}
    
        echo
    done
    
done