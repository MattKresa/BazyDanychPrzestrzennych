create extension postgis;

SELECT
	ST_Union(geom)
INTO FinalGeomJoined
FROM "Exports";

select * from FinalGeomJoined
