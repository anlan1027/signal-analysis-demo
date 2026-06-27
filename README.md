# 2.4 GHz Microstrip Antenna Project

This project contains three MATLAB scripts for a 2.4 GHz microstrip patch antenna:

- `design_24g_microstrip_antenna.m`
  Uses Antenna Toolbox to design a 2.4 GHz patch antenna and export geometry, pattern, S11, and VSWR results.

- `analytical_24g_microstrip_design.m`
  Uses a transmission-line model to estimate patch size, feed point, and approximate radiation patterns.

- `fullwave_24g_microstrip_validation.m`
  Runs a fuller-wave validation workflow and exports the resulting plots and summary data.

- `main.m`
  Unified entry point. By default it runs all three workflows in sequence.

## How to run

1. Open MATLAB in this folder.
2. Run `main.m`.
3. Results are written to:
   - `results/`
   - `results_analytical/`
   - `results_fullwave/`

## Output

- Antenna geometry image
- 3D radiation pattern
- Azimuth and elevation cuts
- S11 and VSWR plots
- Summary text files
- MAT data files

## Requirements

- MATLAB
- Antenna Toolbox

## Notes

If your MATLAB release does not support one of the Antenna Toolbox APIs used here, upgrade to a newer release.