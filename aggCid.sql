# Aggregate cids
# 1. Remove overly frequent cids by patient ic>3
# 2. Map cids to cids in selected ontologies (in cidrewriting)
# 3. Cids must also be the parent cidrewriting (form the uppermost level for aggregation)
# 4. Map cids to the uppermost level which is also present among cids (aggregation mapping key)
# Output:	_cidAgg (cid mapped to uppermost level also present among cids)
#			_cidAggKey (aggregation mapping key) ->
# 16-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @minPatientIc=3;
#set @_cid=user_yenlow._cidNid;

#get the unique cids (20727)
drop table if exists user_yenlow.tmp5;
create table user_yenlow.tmp5 (cid mediumint key) engine=memory;
    insert into user_yenlow.tmp5
    select distinct cid from @_cid 
    order by cid;
select count(distinct cid) from user_yenlow.tmp5;


#remove overly frequent/non-specific cids by ic filter (based on stride4)
#8801 cids left
drop table if exists user_yenlow.tmp6;
create table user_yenlow.tmp6
    select c.str,b.* from user_yenlow.tmp5 a, stride4.ic b, terminology3.str2cid c
    where a.cid=b.cid
    and a.cid=c.cid
    and patient>@minPatientIc
    order by patient;
select * from user_yenlow.tmp6 limit 3;

#load unique remaining cids into memory for speed
drop table if exists user_yenlow.tmp7;
create table user_yenlow.tmp7 (cid mediumint key) engine=memory;
    insert into user_yenlow.tmp7
    select distinct cid from user_yenlow.tmp6 order by cid;

#map the unique cids to cid in cidrewriting (selected ontologies)
#check that parents chosen are also among our unique cids (these parents form the upper bound)
#all 8801 cids are in cidrewriting
drop table if exists user_yenlow.tmp8;
create table user_yenlow.tmp8
    select a.* 
    from terminology3.cidrewriting a, user_yenlow.tmp7 b
    where b.cid=a.target
    order by source, target;
alter table user_yenlow.tmp8 add index (source);
alter table user_yenlow.tmp8 add index (target);
select * from user_yenlow.tmp8 limit 3;

#aggregate concepts
drop table if exists user_yenlow._cidAgg;
create table user_yenlow._cidAgg
    select  s.*,
            r1.*,max(r1.dist) as maxdist,
			c1.str as str,
            c2.str as parentstr
    from    user_yenlow.tmp7 as s,
            terminology3.str2cid as c1,
            terminology3.str2cid as c2,
            user_yenlow.tmp8 as r1
    where s.cid=c1.cid
    and s.cid=r1.source #map cid to children
    and r1.target=c2.cid #get their parents and their strings
#    and r1.grp<>2 #drug cidrewriting is inverse?
    group by cid
    order by cid, dist;
select * from user_yenlow._cidAgg where dist=maxdist and cid<>target limit 5;

#create aggregate mapping key
#1994 cids will be aggregated to higher level terms
drop table if exists user_yenlow._cidAggKey;
create table user_yenlow._cidAggKey
    select distinct cid, target 
    from user_yenlow._cidAgg 
    where dist=maxdist and cid<>target
    order by cid;
alter table user_yenlow._cidAggKey add primary key (cid);
alter table user_yenlow._cidAggKey add key (target);
alter table user_yenlow._cidAggKey engine=memory;
select count(distinct cid) from user_yenlow._cidAggKey;
