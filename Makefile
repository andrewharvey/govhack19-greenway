download:
	wget https://datasets.seed.nsw.gov.au/dataset/97815860-d840-4e67-8f73-1bfc665cb310/resource/6c10132f-8bcc-4b09-bf2a-34314cd6ca33/download/climateuhimmbsua2016.zip
	wget https://datasets.seed.nsw.gov.au/dataset/888e253e-3b4e-4564-93ba-02f00ad3f2c5/resource/420a894c-b387-4819-8220-eeb501459edf/download/climatevegcovermmbgsr2016.zip

unzip:
	mkdir -p data
	unzip -d data climateuhimmbsua2016.zip
	unzip -d data climatevegcovermmbgsr2016.zip

mbtiles:
	mkdir -p mbtiles
	ogr2ogr -f GeoJSON -t_srs 'EPSG:4326' -lco RFC7946=YES -select 'PerAnyVeg' -lco COORDINATE_PRECISION=5 /vsistdout data/Shapefile/VegCover_MMB_GSR_2016.shp | tippecanoe --force --output mbtiles/VegCover.mbtiles --name "VegCover" --attribution "© State Government of NSW and Department of Planning, Industry and Environment 2019" --maximum-zoom 14 --detect-shared-borders --coalesce-smallest-as-needed --no-tiny-polygon-reduction --buffer 2 --accumulate-attribute="PerAnyVeg:mean"
	ogr2ogr -f GeoJSON -t_srs 'EPSG:4326' -lco RFC7946=YES -select 'UHI_16_m' -lco COORDINATE_PRECISION=5 /vsistdout data/Shapefile_UHI/UHI_MMB_SUA_2016.shp | tippecanoe --force --output mbtiles/UHI.mbtiles --name "UHI" --attribution "© State Government of NSW and Department of Planning, Industry and Environment 2019" --maximum-zoom 14 --detect-shared-borders --coalesce-smallest-as-needed --no-tiny-polygon-reduction --buffer 2 --accumulate-attribute="UHI_16_m:mean"

raster:
	mkdir -p raster
	gdal_rasterize -of GTIFF -co COMPRESS=DEFLATE -tr 10 10 -a UHI_16_m data/Shapefile_UHI/UHI_MMB_SUA_2016.shp raster/UHI.geotiff
	gdal_rasterize -of GTIFF -co COMPRESS=DEFLATE -tr 10 10 -a PerAnyVeg data/Shapefile/VegCover_MMB_GSR_2016.shp raster/VegCover.geotiff
	gdal_translate -of AAIGrid raster/UHI.geotiff raster/UHI.asc
	gdal_translate -of AAIGrid raster/VegCover.geotiff raster/VegCover.asc

build_www:
	cd www && yarn run build
