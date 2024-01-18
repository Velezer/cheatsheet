-- multi column ilike index
CREATE EXTENSION pg_trgm
	SCHEMA "schema";

CREATE EXTENSION pg_trgm
	SCHEMA public;


create index idx on
schema.table
	using gin (
		(
			coalesce(col_a,'') || ' ' ||
			coalesce(col_b,'') 
		) gin_trgm_ops
);
