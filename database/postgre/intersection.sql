
-- && is intersection
select string_to_array(lower(t.csv_col), ',') && string_to_array(:csvInput, ',' ) or
    string_to_array(lower(t.csv_col), ',') <@ string_to_array(:csvInput, ',' )
