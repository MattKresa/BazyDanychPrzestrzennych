CREATE EXTENSION postgis;

CREATE TABLE buildings(
	id int PRIMARY KEY,
	geometry geometry,
	name varchar(40)
);

CREATE TABLE roads(
	id int PRIMARY KEY,
	geometry geometry,
	name varchar(40)
);

CREATE TABLE poi(
	id int PRIMARY KEY,
	geometry geometry,
	name varchar(40)
);

INSERT INTO buildings VALUES
(1, 'POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 'BuildingA'),
(2, 'POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))', 'BuildingB'),
(3, 'POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 'BuildingC');

INSERT INTO roads VALUES
(1, 'LINESTRING(0 4.5, 12 4.5)', 'RoadX'),
(2, 'LINESTRING(7.5 10.5, 7.5 0)', 'RoadY');

INSERT INTO poi VALUES
(1, 'POINT(1 3.5)', 'G'),
(2, 'POINT(5.5 1.5)', 'H'),
(3, 'POINT(9.5 6)', 'I'),
(4, 'POINT(6.5 6)', 'J'),
(5, 'POINT(6 9.5)', 'K');

INSERT INTO buildings VALUES
(4, 'POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))', 'BuildingD'),
(5, 'POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 'BuildingF');

--zad a
SELECT
	SUM(ST_Length(geometry)) AS total_roads_length
FROM roads;

--zad b
SELECT
	ST_AsText(geometry) AS geometry
	, ST_Area(geometry) AS area
	, ST_Perimeter(geometry) AS perimeter
FROM buildings
WHERE name='BuildingA';

--zad c
SELECT
	name
	, ST_Area(geometry) AS area
FROM buildings
ORDER BY name;

--zad d
SELECT
	name
	, ST_Perimeter(geometry) AS perimeter
FROM buildings
ORDER BY ST_Area(geometry) DESC LIMIT 2;

--zad e
SELECT 
	ST_Distance(b.geometry, p.geometry) AS min_distance
FROM buildings AS b
CROSS JOIN poi AS p
WHERE p.name='K' AND b.name='BuildingC';

--zad f
SELECT
	ST_Area(ST_Difference(buildingC.geometry, ST_Buffer(buildingB.geometry, 0.5))) AS C_part_area
FROM buildings AS buildingC
CROSS JOIN buildings AS buildingB
WHERE buildingC.name='BuildingC' AND buildingB.name='BuildingB';

--zad g
SELECT 
	b.name AS building_name
FROM buildings AS b
CROSS JOIN roads AS r
WHERE r.name='RoadX'
	AND ST_Y(ST_Centroid(b.geometry)) > ST_Y(ST_Centroid(r.geometry));
	
--zad h
SELECT
	ST_Area(ST_SymDifference(geometry, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')) AS symmetric_difference_area
FROM buildings
WHERE name='BuildingC';