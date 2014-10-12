# Mirtazapine_glucose project
# Get patients with glucose labs and on mirtazapine
# Output:   _lidDrug (lab ID of interest of patients on drug)
#           _labDrug (labs of interest of patients on drug; indep of beforeAndAfter) 
#           _pidBeforeAfter (pid and flags for labs before and after indexTime) -> mirtazapine_pidBeforeAfterMir
#           _labBeforeAfterDrug (lab results of relevant patients; at least ANY 1 lab must occur b4 and after indexTime) ->
#           _pidFreq_labComponentBeforeAfterDrug (number of patients with labs b4 and after indexTime; paired by component)->
# 10-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_pidIndexTimeDrug=user_yenlow.mirtazapine_pidMirtazapine;
#set @_lidDrugSelection=user_yenlow.mirtazapine_labGlucose_ed;
#set @_minDaysAfterIndexTime=3;

#####1. get intersection of pid with glucose labs and on drug
#get their lab ids
drop table if exists user_yenlow._lidDrug;
create table user_yenlow._lidDrug
    SELECT distinct b.* 
    FROM @_pidIndexTimeDrug a, @_lidDrugSelection b
    where a.pid=b.pid;
alter table user_yenlow._lidDrug add index (lid);
alter table user_yenlow._lidDrug add index (component);
alter table user_yenlow._lidDrug add index (pid);
#select * from user_yenlow._lidDrug;

#create flag for at least @_minDaysAfterIndexTime afterDrug
#get their lab results
drop table if exists user_yenlow._labDrug;
create table user_yenlow._labDrug as
    select *, if(timeoffset>indexTime+@_minDaysAfterIndexTime,1,0) as afterDrug
    from user_yenlow._lidDrug;
alter table user_yenlow._labDrug add index (lid);
alter table user_yenlow._labDrug add index (component);
alter table user_yenlow._labDrug add index (pid);
select * from user_yenlow._labDrug limit 5; 


######2a. Check if there are labs before and after IndexTime
#create column to flag ANY lab before and after (group by pid)
drop table if exists user_yenlow.tmp2;
create table user_yenlow.tmp2 as
    select *, if(min(afterDrug)=0 and max(afterDrug)=1,1,0) as AnyLabBeforeAndAfter
    from user_yenlow._labDrug
    group by pid;
select count(distinct pid) from user_yenlow.tmp2 where AnyLabBeforeAndAfter=1;


######2b. Check if there are labs before and after WITHIN the same lab component
#create flag for labs of the same component before and after (group by pid, component)
drop table if exists user_yenlow.tmp1;
create table user_yenlow.tmp1 as
    select *, if(min(afterDrug)=0 and max(afterDrug)=1,1,0) as PairedLabBeforeAndAfter
    from user_yenlow._labDrug
    group by pid, component;
select count(distinct pid) from user_yenlow.tmp1 where PairedLabBeforeAndAfter=1;


#create table of pid with indexDate and flags for pairedLab and ANY lab before and after
drop table if exists user_yenlow._pidBeforeAfterDrug;
create table user_yenlow._pidBeforeAfterDrug as
    select distinct b.*,a.component,a.PairedLabBeforeAndAfter
    from    (select distinct pid, component, PairedLabBeforeAndAfter 
            from user_yenlow.tmp1) a,
            (select distinct pid, indexTime, lastExposureTime, AnyLabBeforeAndAfter 
            from user_yenlow.tmp2) b
    where a.pid=b.pid;
alter table user_yenlow._pidBeforeAfterDrug add index (pid);
alter table user_yenlow._pidBeforeAfterDrug add index (component);
#select * from user_yenlow._pidBeforeAfterDrug;
#->export _pidBeforeAfterDrug (pid, indexTime, BeforeAfter flags, component)


######3. Subset lab results (must be beforeAfter indexTime) of relevant patients
drop table if exists user_yenlow._labBeforeAfterDrug;
create table user_yenlow._labBeforeAfterDrug as
    select distinct a.*, b.AnyLabBeforeAndAfter, b.PairedLabBeforeAndAfter
    from user_yenlow._labDrug a, user_yenlow._pidBeforeAfterDrug b
    where b.AnyLabBeforeAndAfter=1
    and a.pid=b.pid
    and a.component=b.component
    order by pid, timeoffset;
alter table user_yenlow._labBeforeAfterDrug add index (pid, component);
select * from user_yenlow._labBeforeAfterDrug limit 5;
#export _labBeforeAfterDrug ->

#count number of unique patients per component type with before and after
drop table if exists user_yenlow._pidFreq_labComponentBeforeAfterDrug;
create table user_yenlow._pidFreq_labComponentBeforeAfterDrug as 
    select component, description, proc, proc_cat, count(distinct pid) as numPid
    from user_yenlow._labBeforeAfterDrug
    group by component 
    order by numPid desc;
select * from user_yenlow._pidFreq_labComponentBeforeAfterDrug;
#export _pidFreq_labComponentBeforeAfterDrug -> mirtazapine_numPid_labBeforeAfterMir


select count(*) from user_yenlow._pidFreqLab;
