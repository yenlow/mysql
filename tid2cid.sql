# Map tid to cid (patient features) from notes of relevant patients
# Output:   _cidNid (cid in notes of relevant patients) ->
#			_cidFeatures (cid features after removing overly freq cids) ->
# 16-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_tidNidBeforeAfter=user_yenlow.mirtazapine_tidFeaturesBeforeAfterSer;


alter table @_tidNidBeforeAfter add index (tid);
alter table @_tidNidBeforeAfter engine=memory;


#The following terms are dropped if: 
#	1. they are not in any of the 4 groups(disease, drug, device, proc)
#	2. are suppressed at term level (e.g. most freq words liks 'a')
#	3. are suppressed at certain cui levels (e.g. 'clip' is suppressed as a drug but the 2 device cuis are kept)
#We used the auto suppression rules in terminology3
drop table if exists user_yenlow._cidNid;
create table user_yenlow._cidNid as
	select a.*, b.cid
	from @_tidNidBeforeAfter a 
	left outer join terminology3.tid2cid b
	on a.tid=b.tid 
	where b.suppress!=1 and b.grp<=4;
alter table user_yenlow._cidNid order by pid, afterDrug, cid;
alter table user_yenlow._cidNid add index (pid);
alter table user_yenlow._cidNid add index (cid);
alter table user_yenlow._cidNid add index (tid);

#count original number of terms and terms mapped to cid
select count(distinct tid) from @_tidNidBeforeAfter;
select count(distinct tid) from user_yenlow._cidNid where cid is not null;
select count(distinct cid) from user_yenlow._cidNid;

#check that unmapped terms are dropped for the reasons above
drop table if exists user_yenlow.tmp1;
create table user_yenlow.tmp1  
	SELECT distinct tid FROM @_tidNidBeforeAfter a  
	where not exists   
		(SELECT distinct tid FROM user_yenlow._cidNid b  where a.tid=b.tid);
select distinct suppress, grp from user_yenlow.tmp1 a, terminology3.tid2cid b
where a.tid=b.tid order by suppress, grp;


