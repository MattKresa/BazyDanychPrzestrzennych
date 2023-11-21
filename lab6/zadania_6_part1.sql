CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

--załadowanie kopii bazy danych
--pg_restore.exe -h localhost -p 5432 -U postgres -d cw6 "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab6\postgis_raster.backup"

ALTER SCHEMA schema_name RENAME TO Kresa;

--załadowanie rastrów do bazy:
--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab6\srtm_1arc_v3.tif" rasters.dem | psql -d cw6 -h localhost -U postgres -p 5432
--raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab6\Landsat8_L1TP_RGBN.TIF" rasters.landsat8 | psql -d cw6 -h localhost -U postgres -p 5432

SELECT * FROM public.raster_columns

-----------------Tworzenie rastrów z istniejących rastrów i interakcja z wektorami------------------

--Przykład 1
--ST_Intersects: Przecięcie rastra z wektorem
CREATE TABLE kresa.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table kresa.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON kresa.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name , dodanie raster constraints
SELECT AddRasterConstraints('kresa'::name,
'intersects'::name,'rast'::name);


--Przykład 2
--ST_Clip: Obcinanie rastra na podstawie wektora
CREATE TABLE kresa.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


--Przykład 3
--ST_Union: Połączenie wielu kafelków w jeden raster
CREATE TABLE kresa.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-----------------Tworzenie rastrów z wektorów (rastrowanie)------------------

--Przykład 1
--ST_AsRaster: Przykład pokazuje użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej samej
--charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE kresa.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 2
--- ST_Union: Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy raster
DROP TABLE kresa.porto_parishes; --> drop table porto_parishes first
CREATE TABLE kresa.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 3
--ST_Tile: Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile
DROP TABLE kresa.porto_parishes; --> drop table porto_parishes first
CREATE TABLE kresa.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-----------------Konwertowanie rastrów na wektory (wektoryzowanie)------------------

--Przykład 1
--ST_Intersection: jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca
--zestaw par wartości geometria-piksel
create table kresa.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 2
--ST_DumpAsPolygons: konwertuje rastry w wektory (poligony), też zwraca zestaw wartości geomval
CREATE TABLE kresa.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


-----------------Analiza rastrów------------------

--Przykład 1
--ST_Band: Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE kresa.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;


--Przykład 2
--ST_Clip: może być użyty do wycięcia rastra z innego rastra. Poniższy przykład wycina jedną parafię z
--tabeli vectors.porto_parishes. Wynik będzie potrzebny do wykonania kolejnych przykładów.
CREATE TABLE kresa.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 3
--ST_Slope: Poniższy przykład użycia funkcji ST_Slope wygeneruje nachylenie przy użyciu poprzednio
--wygenerowanej tabeli (wzniesienie).
CREATE TABLE kresa.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM kresa.paranhos_dem AS a;


--Przykład 4
--ST_Reclass: Aby zreklasyfikować raster należy użyć funkcji ST_Reclass
CREATE TABLE kresa.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM kresa.paranhos_slope AS a;


--Przykład 5
--ST_SummaryStats: Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats. Poniższy przykład wygeneruje
--statystyki dla kafelka.
SELECT st_summarystats(a.rast) AS stats
FROM kresa.paranhos_dem AS a;


--Przykład 6
--ST_SummaryStats oraz Union: Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM kresa.paranhos_dem AS a;


--Przykład 7
--ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM kresa.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;


--Przykład 8
--ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


--Przykład 9
--ST_Value: pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów.
--Ponieważ geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometrii
--jednopunktowej, należy przekonwertować geometrię wielopunktową na geometrię jednopunktową
--za pomocą funkcji (ST_Dump(b.geom)).geom.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-----------------Topographic Position Index (TPI)------------------

--Przykład 10
--- ST_TPI: Obecna wersja PostGIS może obliczyć TPI jednego piksela za pomocą sąsiedztwa wokół tylko jednej komórki
create table kresa.tpi30 as		--58 secs 585 msecs
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

create table kresa.tpi30_porto as		--3 secs 226 msecs
select ST_TPI(a.rast,1) as rast
from rasters.dem a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_rast_gist ON kresa.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kresa'::name,		--dodanie constraintów
'tpi30'::name,'rast'::name);