download_osm:
	wget http://download.openstreetmap.fr/extracts/oceania/australia/new_south_wales.osm.pbf
	ln -s -T new_south_wales.osm.pbf new_south_wales-car.osm.pbf
	ln -s -T new_south_wales.osm.pbf new_south_wales-bicycle.osm.pbf
	ln -s -T new_south_wales.osm.pbf new_south_wales-foot.osm.pbf
	ln -s -T new_south_wales.osm.pbf new_south_wales-footcool.osm.pbf

osrm_process_car:
	osrm-extract -p profiles/car.lua new_south_wales-car.osm.pbf
	osrm-partition new_south_wales-car.osrm
	osrm-customize new_south_wales-car.osrm

osrm_process_bicycle:
	osrm-extract -p profiles/bicycle.lua new_south_wales-bicycle.osm.pbf
	osrm-partition new_south_wales-bicycle.osrm
	osrm-customize new_south_wales-bicycle.osrm

osrm_process_foot:
	osrm-extract -p profiles/foot.lua new_south_wales-foot.osm.pbf
	osrm-partition new_south_wales-foot.osrm
	osrm-customize new_south_wales-foot.osrm

osrm_process_footcool:
	osrm-extract -p profiles/footcool.lua new_south_wales-footcool.osm.pbf
	osrm-partition new_south_wales-footcool.osrm
	osrm-customize new_south_wales-footcool.osrm

start_osrm:
	osrm-routed --port 5000 --algorithm mld new_south_wales-car.osrm
	osrm-routed --port 5001 --algorithm mld new_south_wales-foot.osrm
	osrm-routed --port 5002 --algorithm mld new_south_wales-bicycle.osrm

download:
	wget https://datasets.seed.nsw.gov.au/dataset/97815860-d840-4e67-8f73-1bfc665cb310/resource/6c10132f-8bcc-4b09-bf2a-34314cd6ca33/download/climateuhimmbsua2016.zip
	wget https://datasets.seed.nsw.gov.au/dataset/888e253e-3b4e-4564-93ba-02f00ad3f2c5/resource/420a894c-b387-4819-8220-eeb501459edf/download/climatevegcovermmbgsr2016.zip

unzip:
	mkdir -p data
	unzip -d data climateuhimmbsua2016.zip
	unzip -d data climatevegcovermmbgsr2016.zip

mbtiles:
	mkdir -p mbtiles
	ogr2ogr -f GeoJSON -t_srs 'EPSG:4326' -lco RFC7946=YES -select 'PerAnyVeg' -lco COORDINATE_PRECISION=5 /vsistdout data/Shapefile/VegCover_MMB_GSR_2016.shp | tippecanoe --force --output mbtiles/VegCover.mbtiles --name "VegCover" --attribution "© State Government of NSW and Department of Planning, Industry and Environment 2019" --maximum-zoom 14 --detect-shared-borders --buffer 2
	ogr2ogr -f GeoJSON -t_srs 'EPSG:4326' -lco RFC7946=YES -select 'UHI_16_m' -lco COORDINATE_PRECISION=5 /vsistdout data/Shapefile_UHI/UHI_MMB_SUA_2016.shp | tippecanoe --force --output mbtiles/UHI.mbtiles --name "UHI" --attribution "© State Government of NSW and Department of Planning, Industry and Environment 2019" --maximum-zoom 14 --detect-shared-borders --buffer 2

raster:
	mkdir -p raster
	ogr2ogr -t_srs 'EPSG:4326' -sql 'SELECT CAST((((UHI_16_m + 10) / 25) * 255) AS INT) AS v, geometry FROM UHI_MMB_SUA_2016' -dialect 'SQLITE' raster/UHI.shp data/Shapefile_UHI/UHI_MMB_SUA_2016.shp
	ogr2ogr -t_srs 'EPSG:4326' -sql 'SELECT PerAnyVeg AS v FROM VegCover_MMB_GSR_2016' raster/VegCover.shp data/Shapefile/VegCover_MMB_GSR_2016.shp
	gdal_rasterize -of GTIFF -co COMPRESS=DEFLATE -tr 0.0001 0.0001 -a v -ot Byte raster/UHI.shp raster/UHI.geotiff
	gdal_rasterize -of GTIFF -co COMPRESS=DEFLATE -tr 0.00005 0.00005 -a v -ot Byte raster/VegCover.shp raster/VegCover.geotiff
	gdal_translate -of AAIGrid raster/UHI.geotiff raster/UHI.asc
	gdal_translate -of AAIGrid raster/VegCover.geotiff raster/VegCover.asc
	head -n 5 < raster/UHI.asc > raster/UHI.head.asc
	tail -n +6 < raster/UHI.asc > raster/UHI.tail.asc
	rm -f raster/UHI.asc
	head -n 5 < raster/VegCover.asc > raster/VegCover.head.asc
	tail -n +6 < raster/VegCover.asc > raster/VegCover.tail.asc
	rm -f raster/VegCover.asc

build_www:
	cd www && yarn run build
