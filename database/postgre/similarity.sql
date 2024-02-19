CREATE EXTENSION IF NOT EXISTS pg_trgm
	SCHEMA public;



select similarity(col_text, :input) > 0.1
