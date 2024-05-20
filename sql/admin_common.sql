-- User Tables and their ENIGNES
SELECT @@hostname, @@port, count(*) AS 'count', engine
FROM information_schema.tables
	WHERE table_schema NOT IN ('mysql', 'performance_schema', 'information_schema')
	AND table_type != 'view'
GROUP BY engine;

-- Non-InnoDB tables
SELECT @@hostname, @@port, TABLE_SCHEMA,TABLE_NAME, engine, SUM(DATA_LENGTH + INDEX_LENGTH) AS size, 'is_not_innodb'
FROM information_schema.tables
	WHERE table_schema NOT IN ('mysql', 'performance_schema', 'information_schema')
	AND table_type != 'view'
	AND engine !='InnoDB'
	GROUP BY table_name;


-- Tables without indexes
SELECT @@hostname, @@port, TABLE_SCHEMA,TABLE_NAME, ENGINE, SUM(DATA_LENGTH + INDEX_LENGTH) AS size, 'has_no_index'
FROM INFORMATION_SCHEMA.tables
	WHERE table_schema NOT IN ('mysql', 'performance_schema', 'information_schema')
	AND table_type != 'view'
	  AND TABLE_NAME NOT IN
		(SELECT TABLE_NAME
		 FROM
		   (SELECT TABLE_NAME,
				   index_name
			FROM information_schema.statistics
			WHERE table_schema NOT IN ('mysql', 'performance_schema', 'information_schema')
			GROUP BY TABLE_NAME,
					 index_name) tab_ind_cols
		 GROUP BY TABLE_NAME)
		GROUP BY table_schema, table_name;

-- Top 5 Fragmented Tables
SELECT * FROM
	(SELECT
		t.TABLE_SCHEMA,
		t.TABLE_NAME,
		ROUND(((t.DATA_LENGTH + t.INDEX_LENGTH)/1024/1024), 2) as TABLE_SIZE_MB,
		ROUND(t.DATA_FREE/1024/1024) as DATA_FREE_MB
FROM information_schema.tables t
JOIN (SELECT
		TABLE_SCHEMA,
		TABLE_NAME,
		DATA_FREE,
		(DATA_FREE/(DATA_LENGTH+INDEX_LENGTH)) AS FRAGMENTATION
		FROM information_schema.tables) f ON t.TABLE_SCHEMA = f.TABLE_SCHEMA and t.TABLE_NAME = f.TABLE_NAME
			WHERE t.DATA_FREE > 0
			AND f.DATA_FREE > 0) AS f
ORDER BY f.DATA_FREE_MB DESC
LIMIT 10;
