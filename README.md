# Paleoclimate Model Comparison

A point-extraction and comparison tool for four heterogeneous paleoclimate temperature
archives. Given a latitude/longitude, it extracts a temperature time series from each
archive, harmonises their incompatible time axes, spatial grids and units, and produces
comparison plots and global difference heatmaps.

The four archives agree on the first-order signal (a cold Last Glacial Maximum followed by
deglacial warming into the Holocene) but disagree on absolute temperature by several
degrees, with the largest systematic differences at high northern latitudes. The point of
the tool is to make those differences directly comparable and to show *where* and *by how
much* the archives diverge.

## What you get

- Per-dataset inspection report (dimensions, time convention, spatial grid, units)
- Near-surface air-temperature (and, where available, soil-temperature) time series
  overlaid at any requested point
- Side-by-side temporal-coverage bars and a grid-cell map (each archive's returned cell
  drawn at its true size)
- Global pairwise mean-difference heatmaps for every dataset pair

## Datasets

| Dataset | Variables | Coverage | Time step | Native resolution | Format |
|---|---|---|---|---|---|
| **Beyer2020/21** (figshare v4) | air temp | 120–0 ka BP | 1–2 kyr | 0.5° | NetCDF |
| **PalMod2** (MPI-ESM1.2-CR) | air temp, soil temp | 25–0 ka BP | annual | ~3.7° (T31) | NetCDF |
| **TraCE-21k** (CCSM3) | air temp, soil temp | 22–0 ka BP | decadal | ~3.7° (T31) | NetCDF |
| **CHELSA-TraCE21k-centennial** | air temp | 22–0 ka BP | 100 yr | 30 arcsec (~0.0083°, ~1 km) | GeoTIFF → NetCDF |

Total download is on the order of **1 TB**, dominated by the ~1 km CHELSA GeoTIFFs.

Two of the archives are raw coupled GCM output (TraCE-21k, PalMod2); two are
high-resolution, observation-anchored downscaling products (Beyer2020/21, CHELSA). The
variables are physically close but not identical: TraCE `TSA` and PalMod2 `tas` are model
2 m air temperatures, Beyer `temperature` is a downscaled bias-corrected monthly mean, and
CHELSA `tasmean` is the mean of downscaled daily extremes `(tasmin + tasmax) / 2`.

## Quick start

```bash
git clone https://github.com/LevinGiersch/paleoclimate_model_comparison.git
cd paleoclimate_model_comparison

conda env create -f environment.yml   # creates the `palclim` environment
conda activate palclim
```

Then add your WDCC credentials (see below) and run the three notebooks in order:

1. `data_downloader.ipynb`
2. `data_processer.ipynb`
3. `paleoclimate_comparison.ipynb`  ← the main comparison tool

In `paleoclimate_comparison.ipynb`, set the coordinate(s) you want in the **Configuration**
/ **Points of interest** cells, then run top to bottom.

## Notebooks

Run in order:

1. **`data_downloader.ipynb`:** downloads all four archives. TraCE-21k and Beyer2020
   download over plain HTTP; CHELSA downloads in parallel from EnviDat (32 threads, atomic
   `.part` rename); PalMod2 uses the `jblob` CLI with WDCC credentials. The downloader
   skips files that already exist, so it is safe to re-run.
2. **`data_processer.ipynb`:** converts the CHELSA GeoTIFFs to NetCDF (one file per
   variable, then `tasmean = (tasmin + tasmax) / 2`), and runs CDO preprocessing on
   PalMod2 (`cdo yearmean`, then `cdo mergetime`). TraCE-21k and Beyer2020 are already
   analysis-ready NetCDF and are passed through unchanged.
3. **`paleoclimate_comparison.ipynb`:** the main comparison tool. Produces the inspection
   reports, the point time-series overlay, the coverage/grid-cell summary, and the global
   difference heatmaps.

> `data_exploration.ipynb` is an earlier scratch version of notebook 3 and is not part of
> the pipeline. Use `paleoclimate_comparison.ipynb`.

## Setup

### Requirements

- ~1 TB free disk space
- [CDO](https://code.mpimet.mpg.de/projects/cdo) (used by `data_processer.ipynb` for
  PalMod2; installed via `environment.yml`)
- [Conda](https://docs.conda.io/en/latest/miniconda.html)
- A [WDCC account](https://www.wdc-climate.de/ui/login) for PalMod2 (registration may take
  a few days)

### PalMod2 credentials

PalMod2 is the only archive that requires authentication. Create
`PalMod2_credentials.txt` in the notebook directory:

```
your_wdcc_username
your_wdcc_password
```

## Data layout

The notebooks expect the following structure (created automatically by the downloader and
processor):

```
data/
├── Beyer2020/data/
│   └── LateQuaternary_Environment.nc
├── PalMod2/
│   ├── data/          # raw monthly files from WDCC
│   └── output/        # merged annual-mean files (data_processer.ipynb)
│       ├── PMMXMCRTDGr111Amtasgn30201_1-250.nc   # air temp (tas)
│       └── PMMXMCRTDGr111Lmtslgn30201_1-250.nc   # soil temp (tsl)
├── TraCE-21k/data/
│   ├── trace.01-36.22000BP.clm2.TSA.*.nc         # air temp
│   └── trace.01-36.22000BP.clm2.TSOI.*.nc        # soil temp
└── CHELSA-TraCE21k-centennial/
    ├── data/          # raw GeoTIFFs from EnviDat (tasmin, tasmax)
    └── output/        # data_processer.ipynb
        ├── tasmin.nc  # intermediate
        ├── tasmax.nc  # intermediate
        └── tasmean.nc # used by the comparison notebook
```

## Key implementation notes

**Time axis:** every archive uses a different convention. `time_to_ka_bp()` in `paleoclimate_comparison.ipynb` normalises all four to *ka BP (past = positive,
present = 0)*. For the two `days since` archives only the elapsed time before the most
recent sample matters, so the conversion anchors on `vals.max()`; the ~0.5 ka rounding
this can introduce is invisible on a 0–120 ka axis.

| Dataset | Raw units | Conversion |
|---|---|---|
| Beyer2020 | `years since present`, negative = past | `-vals / 1000` |
| PalMod2 | `days since 1-1-1`, increasing toward present | `(max − vals) / 365250` |
| TraCE-21k | `ka BP`, stored as negative values | `-vals` |
| CHELSA | `days since −20010-07-01`, increasing toward present | `(max − vals) / 365250` |

(`365250 = 1000 × 365.25` days = 1 kyr in a proleptic-Gregorian calendar.)

**Spatial selection:** nearest-neighbour grid-cell lookup via
`xarray.sel(method="nearest")`, recording the actual cell-centre coordinates. Longitude
conventions (0–360° vs −180–180°) are reconciled automatically before the query. Axes are
detected by name, not by their `units` string, which matters because the published
Beyer2020 NetCDF has its longitude/latitude `units` attributes transposed (longitude
labelled `degrees_north`, latitude `degrees_east`).

**Unit conversion:** PalMod2, TraCE-21k and CHELSA store temperature in kelvin; Beyer2020
uses °C. All series are converted to °C before plotting or differencing.

## Caveats

- **Nearest-neighbour, no area weighting.** Both the point extraction and the heatmaps use
  nearest-neighbour selection. In the heatmaps the high-resolution archives are sampled at
  the coarse TraCE grid-cell centres (one representative pixel per ~3.7° cell), so the maps
  compare point samples, not true area means.
- **Variable definitions differ.** See the note above; a model 2 m diagnostic, a downscaled
  monthly mean and the mean of downscaled daily extremes are close but not interchangeable.
- **Coarse-cell land/sea mixing.** A ~3.7° GCM cell can straddle land and ocean, which
  biases it relative to the high-resolution land-only archives at coastal points.
- **Land-only products.** Beyer and CHELSA are terrestrial only (Beyer also excludes
  latitudes south of ~60° S; CHELSA tops out near 84° N), so their ocean cells are blank.
- **Single example point.** The bundled results are for one mid-latitude continental
  location; the tool is meant to be re-run anywhere.

## Data sources

| Dataset | Reference | DOI
|---|---|---|
| TraCE-21k | Otto-Bliesner & Rosenbloom (2021), NCAR GDEX d651050 | [10.5065/CXB5-TV56](https://doi.org/10.5065/CXB5-TV56)
| CHELSA-TraCE21k (paper) | Karger et al. (2023), *Clim. Past* 19, 439–456 | [10.5194/cp-19-439-2023](https://doi.org/10.5194/cp-19-439-2023)
| CHELSA-TraCE21k (data) | Karger et al. (2020), EnviDat | [10.16904/envidat.211](https://doi.org/10.16904/envidat.211)
| Beyer2020 (paper) | Beyer, Krapp & Manica (2020), *Sci. Data* 7, 236 | [10.1038/s41597-020-0552-1](https://doi.org/10.1038/s41597-020-0552-1)
| Beyer2021 (addendum) | Beyer, Krapp & Manica (2021), *Sci. Data* 8, 262 | [10.1038/s41597-021-01051-1](https://doi.org/10.1038/s41597-021-01051-1)
| Beyer2021 (data, v4) | Beyer, Krapp & Manica (2021), figshare | [10.6084/m9.figshare.12293345.v4](https://doi.org/10.6084/m9.figshare.12293345.v4)
| PalMod2 | Mikolajewicz et al. (2023), WDCC at DKRZ | [10.26050/WDCC/PMMXMCRTDGP111](https://doi.org/10.26050/WDCC/PMMXMCRTDGP111)

If you use this tool, please cite the underlying datasets above and this repository.