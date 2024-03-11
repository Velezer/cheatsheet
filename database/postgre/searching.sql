CREATE TABLE IF NOT EXISTS research (
    id varchar(36),
    random_string VARCHAR(255)
);


DO $$
DECLARE
    random_str VARCHAR(255);
    i INT := 1;
BEGIN
    WHILE i <= 1_000_000 LOOP
        random_str := '';
        FOR j IN 1..20 LOOP
            random_str := random_str || CHR(65 + FLOOR(RANDOM() * 26)::INT);
        END LOOP;

        INSERT INTO research (id, random_string) VALUES (gen_random_uuid(), random_str);
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


create EXTENSION pg_trgm
	SCHEMA public;


create index idx_r_search_gin on
rnd_schema.research
	using gin (
		(
			coalesce(random_string,'')
		) gin_trgm_ops
);

create index idx_r_search_gist on
rnd_schema.research
	using gist (
		(
			coalesce(random_string,'')
		) gist_trgm_ops
);


explain analyze
SELECT 
* 
FROM rnd_schema.research r
WHERE coalesce(r.random_string, '') ilike :input


select show_limit();
select set_limit(0.0625);
SET pg_trgm.similarity_threshold = 0.0625;

explain analyze
SELECT 
*
FROM rnd_schema.research r
WHERE coalesce(r.random_string, '') %> :input
ORDER BY coalesce(r.random_string, '') <->> :input ASC;


SELECT oprname, oprcode FROM pg_operator where oprcode::text ilike '%similarity%'