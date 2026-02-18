# Model 1. Multicompartment PK/PD

This is a toy model for DigiPop project. It describess the three-compartment PK/PD model with a oral dose administration and Emax model for the PD part in target compartment.

## Formats

Model code: Heta code
Scipting: Julia
Data: CSV

## Scenarios

`pool-1.csv` - multiple dose oral administration, 0, 10, 30, 100 units each 12 h.
`pool-2.csv` - multiple dose oral administration, 30, 100 units each 24 h.

## Cohorts

`profile-1` - 1024 virtual patients with variability (log-normal) for 7 parameters.
