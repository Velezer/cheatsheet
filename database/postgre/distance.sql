

CREATE TABLE IF NOT EXISTS research (
    id varchar(36),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);

DO $$
DECLARE
    random_lat DECIMAL;
    random_lon DECIMAL;
    i INT := 1;
BEGIN
    WHILE i <= 10000 LOOP
        -- Generate random latitude (-90 to 90 degrees)
        random_lat := -90.0 + (RANDOM() * 180.0);
        
        -- Generate random longitude (-180 to 180 degrees)
        random_lon := -180.0 + (RANDOM() * 360.0);
        
        -- Insert into the research table
        INSERT INTO research (id, latitude, longitude)
        VALUES (gen_random_uuid(), random_lat, random_lon);
        
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;



-- apt-get install postgis;

--drop extension postgis;
CREATE EXTENSION postgis;

-- Assuming the user provides the latitude and longitude values
-- Replace 'user_latitude' and 'user_longitude' with actual user-provided values



--drop INDEX idx_research_distance;
CREATE INDEX idx_research_distance ON research USING GIST (
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);

-- estimated 100m
select ST_Distance(
           ST_SetSRID(ST_MakePoint(106.83796433623549, -6.2117437046348085), 4326),
           ST_SetSRID(ST_MakePoint(106.838038, -6.212679), 4326),
           true
       );


--EXPLAIN (ANALYZE, FORMAT JSON)
explain analyze
WITH distances AS (
    SELECT id, latitude, longitude, ST_Distance(
               ST_SetSRID(ST_MakePoint(106.8376889, -6.213018), 4326),
               ST_SetSRID(ST_MakePoint(longitude, latitude), 4326),
               false
           ) as distance_in_meter
    FROM research
    where ST_DWithin(
               ST_SetSRID(ST_MakePoint(106.8376889, -6.213018), 4326),
               ST_SetSRID(ST_MakePoint(longitude, latitude), 4326),
               2 -- 100km
           ) = true -- is in distance
--    limit 1000
)
SELECT id, latitude, longitude, FLOOR(distance_in_meter * 100) / 100, 
(SQRT(POW(69.1 * (latitude::float -  -6.213018::float), 2) + POW(69.1 * (106.8376889::float - longitude::float) * COS(latitude::float / 57.3), 2)) * 1609.344
) distance_in_meter_math
FROM distances
WHERE true 
ORDER BY distance_in_meter asc
;

-- alternative without postgis
-- using bounding box approach

-- use these two indexes
CREATE INDEX idx_latitude ON research (latitude);
CREATE INDEX idx_longitude ON research (longitude);

-- or just use this
CREATE INDEX research_latitude_idx ON public.research (latitude,longitude);

explain analyze
SELECT id, latitude, longitude, 
    (SQRT(POW(69.1 * (latitude::float - -6.213018), 2) + POW(69.1 * (106.8376889 - longitude::float) * COS(latitude::float / 57.3), 2)) * 1609.344) AS distance_in_meter
FROM research
WHERE latitude BETWEEN -6.213018 - 1 AND -6.213018 + 1
  AND longitude BETWEEN 106.8376889 - 1 AND 106.8376889 + 1
  AND (SQRT(POW(69.1  * (latitude::float - -6.213018), 2) + POW(69.1 * (106.8376889 - longitude::float) * COS(latitude::float / 57.3), 2)) * 1609.344) < 100000
ORDER BY distance_in_meter;

