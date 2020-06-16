# Compute the iron sediment forcing (`fedsedflux`) supplied to the model

Implements an approach to computing `fesedflux` originally in an IDL routine by J. K. Moore.

`fesedflux` includes two components:
- `fesedflux_oxic`: a constant low background value; increased in regions of high bottom horizontal current speed (sediment resuspenion) by up to a factor of 100.
- `fesedflux_reduce`: source everywhere linearly related to the sinking POC flux by `coef_fesedflux_POC_flux`, except: 
  - source is zero below `POC_flux_gCm2yr_min` (3 gC m$^{-2}$ yr$^{-1}$ in CESM2), and 
  - constant above `POC_flux_gCm2yr_max`.
  - This puts a source on the shelf, and along productive slope/margins, but has little source in the deep ocean, where almost all the remineralization is oxic right on the sediment surface.

`fesedflux` is computed on subgrid-scale bathymetry, using the fraction of each cell that is ocean bottom at each depth: `fesedfrac`. `fesedfrac` is [computed from ETOPO1 bathymetry](notebooks/_sedfrac_compute.ipynb) and modified as follows:
- a minimum percentage of each grid cell that is sediments (`land_adj_sedfrac_min`) is applied to all land-adjacent grid cells.


**Arbitrary modification to this objective scheme:**
- `fesedflux_reduce` is multiplied by 10 in the western equatorial Pacific (135-200E, 15S-15N, above 504 m). 


## Procedure

1. Prepare `fesedfrac`: [sedfrac_compute.ipynb](notebooks/sedfrac_compute.ipynb);

2. Take time mean of `POC_FLUX_IN`, `UVEL`, and `VVLEL` from previous model solution: [_poc_flux_bottom_velocity_inputs.ipynb](notebooks/_poc_flux_bottom_velocity_inputs.ipynb)

3. Compute `fesedflux_reduce`:
   - Read `fesedfrac`, determine land-adjascent points;
   - Create `sedfrac_mod` by applying `land_adj_sedfrac_min`.
   - Read `POC_flux` and convert units; 
   - Where `POC_flux < POC_flux_gCm2yr_min, POC_flux = 0.`;
   - Where `POC_flux > POC_flux_gCm2yr_max, POC_flux = POC_flux_gCm2yr_max`
   - `fesedflux_reduce = POC_flux * coef_fesedflux_POC_flux * sedfrac_mod`
   - Apply ad hoc scaling in to select regions.

4. Compute `fesedflux_oxic`:
   - Read `UVEL` and `VVEL` and compute `current_speed`
   - Where `current_speed < 1.0: current_speed = 1.0`
   - Where `current_speed > 10.0: current_speed = 10.0` 
   - `fesedflux_oxic = coef_fesedflux_current_speed * sedfrac * current_speed**2`
   

5. Output `fesedflux_oxic` and `fesedflux_reduce` in model units: µmol/m^2/d
   
