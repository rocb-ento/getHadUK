#' Get HadUK weather data
#' @param username CEDA username, make an account https://archive.ceda.ac.uk/
#' @param password CEDA password
#' @param version dataset version
#' @param subversion dataset subversion
#' @param var desired weather variable. "rainfall" for rainfall volumn, "tasmax" for max temp, "tasmin" for min temp
#' @param spatial_resolution desired spatial_resolution
#' @param temporal_resolution desired temporal_resolution
#' @param scratch scratch directory to store intermediate .nc files; use "temp" to set to temporary direcory (recommended)
#' @param northing_col column containing British National Grid northing (EPSG:27700) 
#' @param easting_col column containing British National Grid easting (EPSG:27700)
#' @param sample_id_col unique identifier for each sample (location, time) for which weather data is required
#' @param date_col date column in as.Date() format
#' @param data input data
#' 
#' @importFrom httr2 request req_method req_headers req_perform resp_body_json resp_body_raw
#' @importFrom base64enc base64encode
#' @importFrom ncdf4 nc_open ncvar_get nc_close
#' @importFrom dplyr bind_rows filter mutate
#' @importFrom lubridate ceiling_date days
#' @import data.table
#' @return weather data for specified dates and locations
#' @export
#'
#' @examples
#' getHadUK(
#'  username ="myCEDAusername", 
#'  password = "myCEDApassword", 
#'  version = "v1.3.0.ceda", 
#'  subversion= "v20240514",
#'  var = "rainfall",  
#'  spatial_resolution = "1km",
#'  temporal_resolution = "day",
#'  scratch = "temp",
#'  northing_col = "northing",
#'  easting_col = "easting",
#'  sample_id_col = "sample",
#'  date_col = "date",
#'  data = data.frame(northing = 572100, easting = 435900, sample = "X1", date = as.Date("2015-10-23"))
#')

getHadUK <- function(
  username = "myCEDAusername",
  password = "myCEDApassword",
  version = "v1.3.0.ceda",
  subversion = "v20240514",
  var = "rainfall",
  spatial_resolution = "1km",
  temporal_resolution = "day",
  scratch = "temp",
  northing_col = "northing",
  easting_col = "easting",
  sample_id_col = "sample",
  date_col = "date",
  data = data.frame(northing = 572100, easting = 435900, sample = "X1", date = as.Date("2015-10-23"))
) {
  counter <- 1

  # 1. get a CEDA access token
  auth <- paste(username, password, sep = ":") |> charToRaw() |> base64enc::base64encode()
  req_AT <- httr2::request("https://services.ceda.ac.uk/api/token/create/") |>
    httr2::req_method("POST") |>
    httr2::req_headers(Authorization = paste("Basic", auth))
  resp_AT <- httr2::req_perform(req_AT)
  token <- httr2::resp_body_json(resp_AT)

  # 2. identify requisite files
  input_dates <- data[[date_col]]
  easting <- data[[easting_col]]
  northing <- data[[northing_col]]
  sample_id <- data[[sample_id_col]]

  base_dir <- print(paste0(
    "https://dap.ceda.ac.uk/badc/ukmo-hadobs/data/insitu/MOHC/HadOBS/HadUK-Grid/",
    version, "/", spatial_resolution, "/", var, "/", temporal_resolution, "/", subversion, "/", var,
    "_hadukgrid_uk_", spatial_resolution, "_", temporal_resolution, "_"
  ))

  dates_data_frame <- data.frame(input_dates, easting, northing, sample_id) |> # showing which file format dates map to
    unique() |>
    dplyr::mutate(input_start_dates = gsub("-", "", format(as.Date(format(input_dates, "%Y-%m-01"))), fixed = TRUE)) |>
    dplyr::mutate(input_end_dates = gsub("-", "", format(lubridate::ceiling_date(input_dates, "month") - lubridate::days(1)), fixed = TRUE)) |>
    dplyr::mutate(file_dates = paste0(input_start_dates, "-", input_end_dates))

  reslist <- list()
  for (i in unique(dates_data_frame$file_dates)) {
    date_range <- i
    suffix <- ".nc?download=1"
    url <- paste0(base_dir, date_range, suffix)
    print(date_range)
    print(url)

    destfile <- paste0(base_dir, date_range, ".nc")
    resp <- httr2::request(url) |>
      httr2::req_headers(Authorization = paste("Bearer", token$access_token)) |>
      httr2::req_perform()

    if (scratch == "temp") {
      tmp_nc <- tempfile(fileext = ".nc")
      writeBin(httr2::resp_body_raw(resp), tmp_nc)
    } else {
      tmp_nc <- file.path(scratch, paste0("rainfall_", date_range, ".nc"))
      writeBin(httr2::resp_body_raw(resp), tmp_nc)
    }

    nc <- ncdf4::nc_open(tmp_nc)

    locs <- dates_data_frame |> dplyr::filter(file_dates == date_range)

    nc_x <- unlist(nc$dim$projection_x_coordinate$vals)
    nc_y <- unlist(nc$dim$projection_y_coordinate$vals)
    nc_t <- as.Date(as.POSIXct(nc$dim$time$vals * 3600, origin = "1800-01-01 00:00:00", tz = "BST"))

    variable <- ncdf4::ncvar_get(nc, var)
    ncdf4::nc_close(nc)

    x_index_map <- data.table::data.table(x_index = seq_along(nc_x), easting = nc_x)
    y_index_map <- data.table::data.table(y_index = seq_along(nc_y), northing = nc_y)
    time_index_map <- data.table::data.table(time_index = seq_along(nc_t), time = nc_t)

    locs <- time_index_map[locs, on = .(time = input_dates)]
    locs <- x_index_map[locs, on = "easting", roll = "nearest"]
    locs <- y_index_map[locs, on = "northing", roll = "nearest"]

    locs[, (as.character(var)) := variable[cbind(x_index, y_index, time_index)]]
    reslist[[counter]] <- locs[, .SD, .SDcols = !c("y_index", "northing", "x_index", "easting", "time_index", "time")]
    counter <- counter + 1
  }

  result <- dplyr::bind_rows(reslist)
  return(result)
}