-- create table
CREATE TABLE IF NOT EXISTS research (
    id varchar(36),
    random_string text
);


-- generate data
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

        INSERT INTO research (id, random_string) VALUES (gen_random_uuid(), '{"search": "' || random_str || '"}');
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


create EXTENSION pg_trgm
	SCHEMA public;


-- create gin index on key
-- coalesce is for indexing nullable column
create index idx_r_search_gin on
rnd_schema.research
	using gin (
		(
			coalesce(random_string::json->>'search', '')
		) gin_trgm_ops
);

-- create btree index on key
CREATE INDEX idx_r_search_btree ON rnd_schema.research USING btree (coalesce(random_string::json->>'search', ''));

-- check if indexing gin applied
explain analyze
SELECT 
*
FROM rnd_schema.research r
WHERE coalesce(r.random_string::json->>'search', '') ilike :input


-- check if indexing btree applied
explain analyze
select 
*
from rnd_schema.research r 
where coalesce(random_string::json->>'search', '') = :input


-- upsert key
UPDATE rnd_schema.research
SET random_string = random_string::jsonb 
|| '{"search": "KFRWAYMSMKRSOWHWENFP"}' 
where id = :id

-- delete key
UPDATE rnd_schema.research
SET random_string = random_string::jsonb - 'searcha'
where id = :id



