# Mirtazapine_glucose project
# Query patients with glucose labs in stride 5
# Output:   _mirtazapine_labComponents (lab components containing glucose)
#           _mirtazapine_labGlucose (lab results matching above lab components)
#           mirtazapine_labFreq (number of patients per lab)
# 12-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_inclregex='glucose.* |.*a1c.*';
#set @_exclboolean='gases "glucose, csf" fluid dipstick "urinalysis, screen for culture"';
#set @minage=18;
#set @_pid=mirtazapine_pidMirtazapine;

#get components containing glucose or a1c
drop table if exists user_yenlow._labComponents;
create table user_yenlow._labComponents as
    SELECT * FROM stride5.component where common regexp @_inclregex order by base;
alter table user_yenlow._labComponents add primary key (component);

#exlusion criteria
delete from user_yenlow._labComponents 
    where match(name) against (@_exclboolean in boolean mode);
SELECT * FROM user_yenlow._labComponents;

#get lab records matching pid of interest
drop table if exists user_yenlow.tmp;
create table user_yenlow.tmp (pid mediumint(8) unsigned, indexTime float, lastExposureTime float, index using hash (pid)) 
			engine=memory;
	insert into user_yenlow.tmp 
	select  distinct pid, indexTime, lastExposureTime
	from  @_pid;
alter table user_yenlow.tmp add primary key (pid);

#get lab records matching pid of interest
drop table if exists user_yenlow._labPid;
create table user_yenlow._labPid as
    select  b.*, a.lid, a.timeoffset, a.component, a.description, 
            a.proc, a.proc_cat, a.ord, a.ord_num, a.result_flag,
            a.ref_low, a.ref_high, a.ref_unit, a.result_inrange, a.ref_norm
    from  user_yenlow.tmp b, stride5.lab a
    where a.pid=b.pid;
alter table user_yenlow._labPid add index (lid);
alter table user_yenlow._labPid add index (component);
alter table user_yenlow._labPid add index (pid);


drop table if exists user_yenlow._lab;
create table user_yenlow._lab as
    select  a.*
    from user_yenlow._labComponents b, user_yenlow._labPid a
    where a.component=b.component;
alter table user_yenlow._lab add index (lid);
alter table user_yenlow._lab add index (component);
alter table user_yenlow._lab add index (pid);


#count number of patients per glucose lab
drop table if exists user_yenlow._pidFreqLab;
create table user_yenlow._pidFreqLab as
    select count(distinct pid) as numPid, count(*) as numLab, component, description
    from user_yenlow._lab 
    group by component
    order by numPid desc;
select * from user_yenlow._pidFreqLab;

#drop lab records of irrelevant glucose tests (numPid>=10, exclusion criteria)
drop table if exists user_yenlow._lab_ed;
create table user_yenlow._lab_ed  as
    select a.*, b.numPid 
    from user_yenlow._lab a, user_yenlow._pidFreqLab b
    where b.numPid>=10
    and a.component=b.component;
alter table user_yenlow._lab_ed add index (lid);
select count(distinct pid) from user_yenlow._lab_ed;

delete from user_yenlow._lab_ed 
    where match(description) against (@_exclboolean in boolean mode);
select count(distinct pid) from user_yenlow._lab_ed;

select distinct description from user_yenlow._lab_ed;
