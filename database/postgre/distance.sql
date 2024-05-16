

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
    WHILE i <= 1000000 LOOP
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
               1 -- 100km
           ) = true -- is in distance
)
SELECT id, latitude, longitude, FLOOR(distance_in_meter * 100) / 100
FROM distances
WHERE true 
ORDER BY distance_in_meter desc
;
