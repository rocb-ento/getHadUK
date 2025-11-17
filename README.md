Met Office HadUK weather data is freely available for academic use via the CEDA archive https://catalogue.ceda.ac.uk/uuid/4dc8450d889a491ebb20e724debe2dfb/

These data are organised by month and variable. E.g. rainfall/day/v20240514/rainfall_hadukgrid_uk_1km_day_20151001-20151031.nc and are stored in NetCDF files. This can make accessing the data finicky in R. 

This function provides an easy way to get 1km / daily resolution weather data (rainfall, max temp, min temp) from the CEDA archive via http. The function takes your CEDA username and password and requests an access token from CEDA. It then finds the correct NetCDF file, downloads it to a temporary directory using http and extracts the requested variable value at the nearest 1km square. 