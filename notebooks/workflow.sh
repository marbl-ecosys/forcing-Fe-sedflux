#!/usr/bin/env bash
set -e

source activate forcing-Fe-sedflux


echo '---------------------------------------'
echo 'Ensure grid files'
papermill -k python _ensure_grid_files.ipynb _ensure_grid_files.ipynb

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
papermill -k python _poc_flux_bottom_velocity_inputs.ipynb _poc_flux_bottom_velocity_inputs.ipynb

echo


# compute the fesedflux for each grid
for dst_grid in POP_gx1v7 POP_gx3v7; do
    dirout=output/${dst_grid}
    if [ ! -d ${dirout} ]; then
        mkdir -p output/${dst_grid}
    fi
    
    echo '---------------------------------------'
    echo "Computing fesedflux: ${dst_grid}"
    
    papermill -k python _sedfrac_compute.ipynb ${dirout}/_sedfrac_compute.ipynb \
              -p dst_grid ${dst_grid}
              
    papermill -k python Fe_sediment_flux_forcing.ipynb ${dirout}/Fe_sediment_flux_forcing.ipynb \
              -p dst_grid ${dst_grid}

    echo
done