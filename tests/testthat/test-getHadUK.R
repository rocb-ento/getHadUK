test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})
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