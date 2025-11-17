
## function
GetHadUK <- function(
  
  username ="roconnellbooth", 
  password = "xx", 
  version = "v1.3.0.ceda", 
  edition= "v20240514",
  var = "rainfall",  # tasmax for max temp, tasmin for min temp
  spatial_resolution = "1km",
  temporal_resolution = "day",
  scratch = "temp",
  northing_col = "northing",
  easting_col = "easting",
  sample_id_col = "Sample",
  date_col = "Date",
  data = gms
)
  { 
  counter = 1
  ## 1. get a CEDA access token https://help.ceda.ac.uk/article/5100-archive-access-tokens
  ## change to allow an option to directly provide the token
  auth <- paste(username, password, sep = ":") |> charToRaw() |> base64enc::base64encode()
  req_AT <- request("https://services.ceda.ac.uk/api/token/create/") |>
    req_method("POST") |>
    req_headers(Authorization = paste("Basic", auth))
  resp_AT <- req_perform(req_AT)
  token <- resp_body_json(resp_AT)

  ## 2. identifty requisite files 
  input_dates = data[[date_col]]
  easting <- data[[easting_col]]
  northing <- data[[northing_col]]
  sample_id <- data[[sample_id_col]]
  
  base_dir <- print(paste0("https://dap.ceda.ac.uk/badc/ukmo-hadobs/data/insitu/MOHC/HadOBS/HadUK-Grid/", version, "/", spatial_resolution, "/", var, "/", temporal_resolution, "/", edition, "/", var, "_hadukgrid_uk_", spatial_resolution, "_", temporal_resolution, "_"))

  dates_data_frame <- data.frame(input_dates, easting, northing, sample_id) %>% # dataframe showing which file format dates have which dates that we want data for 
    unique() %>% 
    mutate(input_start_dates = gsub("-", "", format(as.Date(format(input_dates, "%Y-%m-01"))), fixed = TRUE)) %>% 
    mutate(input_end_dates = gsub("-", "", format(ceiling_date(input_dates, "month") - days(1)), fixed = TRUE)) %>%
    mutate(file_dates = paste0(input_start_dates, "-", input_end_dates))
  
  reslist = list()
  for(i in unique(dates_data_frame$file_dates)) { ## loop for individual nc files 
    
    
    #i = unique(dates_data_frame$file_dates)[1]
    
    date_range <- i
    suffix <- ".nc?download=1"
    url <- paste0(base_dir, date_range, suffix)
    print(date_range)
    print(url)
    ## 
    destfile <- paste0(base_dir, date_range, ".nc")
    # Create and perform the request
    resp <- request(url) |>
      req_headers(Authorization = paste("Bearer", token$access_token)) |>
      req_perform()

    if(scratch == "temp"){
      tmp_nc <- tempfile(fileext = ".nc")
      writeBin(resp_body_raw(resp), tmp_nc) 
    }
    else {
      tmp_nc <- file.path(scratch, paste0("rainfall_", date_range, ".nc"))
      writeBin(resp_body_raw(resp), tmp_nc)
    }

    nc <- nc_open(tmp_nc)

    # unique_dates_per_file <- dates_data_frame %>% filter(file_dates == date_range) %>% pull(input_dates) %>% unique()
    locs <- dates_data_frame %>% filter(file_dates == date_range)
      ## filter from dataframe of dates per file == date_range 

      # Date = as.Date(j)
      nc_x <- unlist(nc$dim$projection_x_coordinate$vals) ## raw x values from the nc in BNG 
      nc_y <- unlist(nc$dim$projection_y_coordinate$vals)
      nc_t <- as.Date(as.POSIXct(nc$dim$time$vals * 3600, origin = "1800-01-01 00:00:00", tz = "BST"))
      
      variable <- ncvar_get(nc, (var)) # 3d-matrix , x y and time. When we extract the coords are lost, must do it by index
      nc_close(nc)
      
      # e.g. rainfall[900, 902, 1] ## [x,y,time] / [easting, northing, time]

      x_index_map <- data.table(x_index = seq_along(nc_x), easting = nc_x)
      y_index_map <- data.table(y_index = seq_along(nc_y), northing = nc_y)
      time_index_map <- data.table(time_index = seq_along(nc_t), time = nc_t)

      # find the nearest nc file index for x and y
      locs <- time_index_map[locs, on = .(time = input_dates)] # we can just left join since the nearest value is always and exact match
      locs <- x_index_map[locs, on = "easting", roll = "nearest"]
      locs <- y_index_map[locs, on = "northing", roll = "nearest"]
      # extract the rainfall value
      locs[, (as.character(var)) := variable[cbind(x_index, y_index, time_index)]]
      reslist[[counter]] <- locs[, .SD, .SDcols = !c("y_index", "northing", "x_index", "easting", "time_index", "time")] # deselect the columns except for sample and the variable value
    counter = counter +1 
  }
  result <- bind_rows(reslist)
  return(result)
}

# input data example
# # A tibble: 10 × 4
#    northing easting Sample                     Date      
#       <dbl>   <dbl> <chr>                      <date>    
#  1   572100  435900 NE-85_NZ359721_2021-04-23  2021-04-23
#  2   209100  352700 CY-56_SO527091_2020-11-07  2020-11-07
#  3   472500  350200 NW-11_SD502725_2020-11-06  2020-11-06
#  4   473300  432300 YH-14_SE323733_2017-04-21  2017-04-21
#  5   212900  513200 EE-134_TL132129_2021-08-06 2021-08-06
#  6   228700  304700 CY-66_SO047287_2018-09-28  2018-09-28
#  7   347800  434700 EM-42_SK347478_2015-03-21  2015-03-21
#  8   185500  411500 SW-144_SU115855_2022-09-09 2022-09-09
#  9   375000  391800 NW-75_SJ918750_2019-07-22  2019-07-22
# 10   210700  347600 CY-23_SO476107_2015-10-23  2015-10-23
# >


