# Get HadUK weather data using R

<!-- badges: start -->

<!-- badges: end -->

Met Office HadUK weather data is freely available for academic use via the CEDA archive https://catalogue.ceda.ac.uk/uuid/4dc8450d889a491ebb20e724debe2dfb/

These data are organised by month and variable. E.g. rainfall/day/v20240514/rainfall_hadukgrid_uk_1km_day_20151001-20151031.nc contains 1 month of daily rainfall data for the UK. These data and are stored in NetCDF files. This can make accessing the data finicky in R.

This function provides an easy way to get 1km / daily resolution weather data (rainfall, max temp, min temp) from the CEDA archive via https. The function takes your CEDA username and password and requests an access token from CEDA. It then finds the correct NetCDF file, downloads it using the token to a temporary directory using https. It then extracts the requested variable value at the nearest 1km square using BNG northing and easting values.

## Installation

You can install the package from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rocb-ento/getHadUK")
```

## Usage

``` r
require(getHadUK)

getHadUK(
  username ="myCEDAusername", 
  password = "myCEDApassword", 
  version = "v1.3.0.ceda", 
  subversion= "v20240514",
  var = "rainfall",  
  spatial_resolution = "1km",
  temporal_resolution = "day",
  scratch = "temp",
  northing_col = "northing",
  easting_col = "easting",
  sample_id_col = "sample",
  date_col = "date",
  data = data.frame(northing = 572100, easting = 435900, sample = "X1", date = as.Date("2015-10-23"))
)

#    sample_id input_start_dates input_end_dates        file_dates    rainfall
#       <char>            <char>          <char>            <char>       <num>
# 1:        X1          20151001        20151031 20151001-20151031 1.08998e-07
```

The following variables are available:

```         
rainfall - daily    
tasmax - daily
tasmin - daily
groundfrost - mon, ann      
hurs - mon, ann     
psl - mon, ann      
pv - mon, ann       
sfcWind - mon, ann      
snowLying - mon, ann            
sun - mon, ann      
tas - mon, ann      
```

Please cite HadUK: Met Office; Hollis, D.; McCarthy, M.; Kendon, M.; Legg, T.; Simpson, I. (2018): HadUK-Grid gridded and regional average climate observations for the UK. Centre for Environmental Data Analysis, date of citation. http://catalogue.ceda.ac.uk/uuid/4dc8450d889a491ebb20e724debe2dfb

This code was written for O'Connell-Booth, R.; Hassall, C.; Kunin, William E. (2025) Effect of bulb type on moth trap catch and composition in UK Gardens. EcoEvoRxiv (pre-print). https://ecoevorxiv.org/repository/view/8079/