# Filter overly frequent cids by patient information content
# Output:   _cidFeatures (cid features after removing overly freq cids) ->
#
# 16-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_cid=user_yenlow._cidNid;


#load the unique cids into memory for speed;
drop table if exists user_yenlow.tmp5;
create table user_yenlow.tmp5 (cid mediumint key) engine=memory;
    insert into user_yenlow.tmp5
    select distinct cid from @_cid 
    order by cid;
select count(distinct cid) from user_yenlow.tmp5;


#identify cids to keep
#NOT overly frequent cid by low patient Ic in stride4 
#(dif criteria for dif groups)
drop table if exists user_yenlow.tmp6;
create table user_yenlow.tmp6
    select distinct c.str,b.*,d.grp 
    from 	user_yenlow.tmp5 a, stride4.ic b, 
    		terminology3.str2cid c, terminology3.tid2cid d
    where a.cid=b.cid
    and a.cid=c.cid
    and a.cid=d.cid
    order by patient;
alter table user_yenlow.tmp6 add index (cid);
alter table user_yenlow.tmp6 add index (grp);
delete from user_yenlow.tmp6 where patient<3 and grp in (1,4); #diseases and proc
delete from user_yenlow.tmp6 where patient is null and grp=3; #devices
#do not filter drug cid by patientIc (grp=2)
select * from user_yenlow.tmp6 order by patient limit 3;

#select only cids that are not overly freq
drop table if exists user_yenlow._cidFeatures;
create table user_yenlow._cidFeatures
	select b.pid,b.cid,b.afterDrug 
	from user_yenlow.tmp6 a, user_yenlow._cidNid b
	where a.cid=b.cid;
alter table user_yenlow._cidFeatures add index (cid);
alter table user_yenlow._cidFeatures add index (pid);
select count(distinct cid) from user_yenlow._cidFeatures;
