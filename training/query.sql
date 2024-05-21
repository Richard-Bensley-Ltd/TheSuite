select sum(a),b,c from test.slow_test
	where c like '%text%1%'
	group by c;

explain select sum(a),b,c from test.slow_test
	where c like '%text%1%'
	group by c;


ALTER TABLE test.slow_test
	ADD INDEX idx_c (c);
	
ALTER TABLE test.slow_test
	DROP INDEX idx_c;
