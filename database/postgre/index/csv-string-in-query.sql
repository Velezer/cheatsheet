select string_to_array('a,b,c', ',') @> string_to_array('c,a', ','); -- true