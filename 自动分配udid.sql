--limitnum  限制一个udid分配机器的数量
--maxcount  最大更新记录条数
CREATE OR REPLACE FUNCTION fn_auto_allot_udid(limitnum integer,maxcount integer) RETURNS boolean
AS $$
DECLARE 
	tableexist integer;
	canuseudid varchar;
	accountrecord RECORD;
	tempcount integer;
BEGIN
	--检查账号表是否存在，检查udid数据记录是否存在
	select count(*) into tableexist from pg_class where relname = 't_account';
	IF tableexist=0 THEN
		RETURN FALSE;
	END  IF;
	select count(*) into tableexist from pg_class where relname = 't_equipment_temp';
	IF tableexist=0 THEN
		RETURN FALSE;
	END  IF;

	--挑一个没有udid的账号记录更新掉
	tempcount:=0;
	FOR accountrecord IN select * from t_account where state=true and udid='' order by id asc LOOP
		--随机查询一个可用udid
		select udid into canuseudid from t_equipment_temp where udid not in(
			select udid from t_account where state=true group by udid having count(1)>limitnum) 
		limit 1;
		--更新记录
		--raise notice '%', canuseudid;
		update t_account set udid=canuseudid where id=accountrecord.id;
		tempcount:=tempcount+1;
		IF tempcount>maxcount THEN
			RETURN TRUE;
		END IF;
	END LOOP;
	RETURN TRUE;
END
$$ LANGUAGE plpgsql;