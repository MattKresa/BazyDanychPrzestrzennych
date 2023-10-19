CREATE EXTENSION postgis;

--zad 1
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_BUILDINGS.shp" buildings_2019 | psql -p 5432 -h localhost -U postgres -d cw3
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2018_KAR_GERMANY\T2018_KAR_BUILDINGS.shp" buildings_2018 | psql -p 5432 -h localhost -U postgres -d cw3

SELECT
	b19.name AS b19_name
	, ST_AsText(b19.geom) AS b19_geom
	, b18.name AS b18_name
	, ST_AsText(b18.geom) AS b18_geom
FROM buildings_2019 AS b19
LEFT JOIN buildings_2018 b18
	ON b19.polygon_id = b18.polygon_id
WHERE b18.polygon_id IS NULL 
	OR ST_AsText(b18.geom) != ST_AsText(b19.geom);
	
	
--zad 2
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_POI_TABLE.shp" poi_2019 | psql -p 5432 -h localhost -U postgres -d cw3
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2018_KAR_GERMANY\T2018_KAR_POI_TABLE.shp" poi_2018 | psql -p 5432 -h localhost -U postgres -d cw3

CREATE VIEW changed_new_buildings AS
	SELECT
		b19.*
	FROM buildings_2019 AS b19
	LEFT JOIN buildings_2018 b18
		ON b19.polygon_id = b18.polygon_id
	WHERE b18.polygon_id IS NULL 
		OR ST_AsText(b18.geom) != ST_AsText(b19.geom);
		
CREATE VIEW new_poi AS
	SELECT
		p19.*
	FROM poi_2019 AS p19
	LEFT JOIN poi_2018 AS p18
		ON p19.poi_id = p18.poi_id
	WHERE p18.poi_id IS NULL;
	
SELECT
	np.type
	, count(np.gid) AS count
FROM new_poi AS np
JOIN changed_new_buildings AS cnb
	ON ST_Intersects(ST_Buffer(cnb.geom, 0.005), np.geom)
GROUP BY np.type;


--zad 3
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_STREETS.shp" streets_2019 | psql -p 5432 -h localhost -U postgres -d cw3
	
CREATE TABLE streets_reprojected AS
	SELECT
		gid
		, link_id
		, st_name
		, ref_in_id
		, nref_in_id
		, func_class
		, speed_cat
		, fr_speed_l
		, to_speed_l
		, dir_travel
		, ST_SetSRID(geom, 3068) AS geom
	FROM streets_2019;


--zad 4
CREATE TABLE input_points(
	gid int PRIMARY KEY,
	geom geometry
);

INSERT INTO input_points VALUES
(1, 'POINT(8.36093 49.03174)'),
(2, 'POINT(8.39876 49.00644)');


--zad 5
UPDATE input_points
SET geom = ST_SetSRID(ST_AsText(geom), 3068)


--zad 6
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_STREET_NODE.shp" street_node_2019 | psql -p 5432 -h localhost -U postgres -d cw3

UPDATE street_node_2019
SET geom = ST_SetSRID(geom, 3068);
	
CREATE VIEW line_from_points AS
	SELECT
		ST_Makeline(geom) AS geom
	FROM input_points

SELECT 
	sn19.node_id
FROM street_node_2019 AS sn19
JOIN line_from_points AS lfp
	ON ST_Contains(ST_Buffer(lfp.geom, 0.002), sn19.geom)
	
	
--zad 7
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_LAND_USE_A.shp" land_use_2019 | psql -p 5432 -h localhost -U postgres -d cw3

SELECT
	COUNT(*)
FROM poi_2019 AS p
JOIN land_use_2019 AS lu
	ON ST_Intersects(ST_Buffer(lu.geom, 0.003), p.geom)
WHERE p.type = 'Sporting Goods Store';


--zad 8
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_RAILWAYS.shp" railways_2019 | psql -p 5432 -h localhost -U postgres -d cw3
--shp2pgsql.exe "C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab3\T2019_KAR_GERMANY\T2019_KAR_WATER_LINES.shp" water_lines_2019 | psql -p 5432 -h localhost -U postgres -d cw3

CREATE TABLE T2019_KAR_BRIDGES AS
	SELECT
		ST_Intersection(r.geom, wl.geom) AS geom
	FROM railways_2019 AS r
	JOIN water_lines_2019 AS wl
		ON ST_Intersects(r.geom, wl.geom);