# Paleoclimate Model Comparison

A point-extraction and comparison tool for four heterogeneous paleoclimate datasets. Given a latitude/longitude, the tool extracts temperature time series from each dataset, harmonises the incompatible time axes and spatial grids, and produces comparison plots and global difference heatmaps.

## Datasets

| Dataset | Variables | Time coverage | Time step | Spatial resolution | Format |
|---|---|---|---|---|---|
| **Beyer2020** (v4) | air temp | 120–0 ka BP | 1–2 kyr | 0.5° | NetCDF |
| **PalMod2** | air temp, soil temp | 25–0 ka BP | annual | ~3.75° (T31) | NetCDF |
| **TraCE-21k** | air temp, soil temp | 22–0 ka BP | decadal | ~3.75° (T31) | NetCDF |
| **CHELSA-TraCE21k-centennial** | air temp | 21–0 ka BP | 100 yr | ~1 km (0.01°) | GeoTIFF → NetCDF |

Total download size is approximately 800 GB (dominated by CHELSA).

## Notebooks

Run in order:

1. **`data_downloader.ipynb`** — downloads all datasets. TraCE-21k and Beyer2020 download automatically; CHELSA downloads in parallel from EnviDat; PalMod2 uses the `jblob` CLI with WDCC credentials.

2. **`data_processer.ipynb`** — converts CHELSA GeoTIFFs to NetCDF and computes the mean of tasmin/tasmax to obtain a single air-temperature file. Runs CDO preprocessing on PalMod2 (yearly means, merge).

3. **`data_exploration.ipynb`** — the main comparison tool. Produces:
   - Per-dataset inspection report (dimensions, time convention, spatial grid)
   - Temperature time series overlay at any requested point
   - Side-by-side temporal coverage and grid-cell map
   - Global mean-temperature difference heatmaps for every dataset pair

## Setup

### Requirements

- ~800 GB free disk space
- [Conda](https://docs.conda.io/en/latest/miniconda.html)
- A [WDCC account](https://www.wdc-climate.de/ui/login) for PalMod2 (registration may take a few days)

### Installation

```bash
conda env create -f environment.yml
conda activate paleoclimate
```

### PalMod2 credentials

Create `PalMod2_credentials.txt` in the notebook directory:

```
your_wdcc_username
your_wdcc_password
```

## Data layout

The notebooks expect the following directory structure (created automatically by `data_downloader.ipynb`):

```
data/
├── Beyer2020/data/
│   └── LateQuaternary_Environment.nc
├── PalMod2/
│   ├── data/          # raw monthly files from WDCC
│   └── output/        # merged annual-mean files produced by data_processer.ipynb
│       ├── PMMXMCRTDGr111Amtasgn30201_1-250.nc   # air temp
│       └── PMMXMCRTDGr111Lmtslgn30201_1-250.nc   # soil temp
├── TraCE-21k/data/
│   ├── trace.01-36.22000BP.clm2.TSA.*.nc
│   └── trace.01-36.22000BP.clm2.TSOI.*.nc
└── CHELSA-TraCE21k-centennial/output/
    └── tasmean.nc
```

## Key implementation notes

**Time axis** — every dataset uses a different convention. `time_to_ka_bp()` in `data_exploration.ipynb` normalises all four to *ka BP (past = positive, present = 0)*:

| Dataset | Raw units | Conversion |
|---|---|---|
| Beyer2020 | `years since present`, negative = past | `-vals / 1000` |
| PalMod2 | `days since 1-1-1`, increasing toward present | `(max − vals) / 365250` |
| TraCE-21k | `ka BP`, but stored as negative values | `-vals` |
| CHELSA | `days since −20010-07-01`, increasing toward present | `(max − vals) / 365250` |

**Spatial selection** — nearest-neighbour grid-cell lookup via `xarray.sel(method="nearest")`. Longitude conventions (0–360 vs −180–180) are handled automatically before the query.

**Unit conversion** — PalMod2, TraCE-21k, and CHELSA store temperature in Kelvin; Beyer2020 uses °C. All outputs are converted to °C.
