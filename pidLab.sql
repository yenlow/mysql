# Mirtazapine_glucose project
# Query patients with glucose labs in stride 5
# Output:   _mirtazapine_labComponents (lab components containing glucose)
#           _mirtazapine_labGlucose (lab results matching above lab components)
#           mirtazapine_labFreq (number of patients per lab)
# 12-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_inclregex='glucose.* |.*a1c.*';
#set @_exclboolean='gases csf fluid dipstick, "urinalysis, screen for culture"';
#set @minage=18;

#get components containing glucose or a1c
drop table if exists user_yenlow._labComponents;
create table user_yenlow._labComponents as
    SELECT * FROM stride5.component where common regexp @_inclregex order by base;
alter table user_yenlow._labComponents add primary key (component);

#exlusion criteria
delete from user_yenlow._labComponents 
    where match(name) against (@_exclboolean in boolean mode);
SELECT * FROM user_yenlow._labComponents;

#get lab records with lab components containing glucose
drop table if exists user_yenlow._lab;
create table user_yenlow._lab as
    select  a.pid, a.lid, a.timeoffset, a.component, a.description, 
            a.proc, a.proc_cat, a.ord, a.ord_num, a.result_flag,
            a.ref_low, a.ref_high, a.ref_unit, a.result_inrange, a.ref_norm
    from  user_yenlow._labComponents b, stride5.lab a
    where a.component=b.component;
alter table user_yenlow._lab add primary key (lid);
alter table user_yenlow._lab add index (component, age);
delete from user_yenlow._lab where age>=@minage;
select * from user_yenlow._lab;
select  pid, lid, timeoffset, component, description, 
        proc, proc_cat, ord, ord_num, result_flag,
        ref_low, ref_high, ref_unit, result_inrange, ref_norm
from stride5.lab;

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
