# Get demographics of selected patients
# Output:  	tmp3 (store in memory)
#			_demPid (demographics info of selected patients) ->
# 10-Nov-13 Yen Low
#####################


#@_ is a fake handler. Use R to global replace.
#set @_pid=user_yenlow.mirtazapine_pidBeforeAfterMir;
#set @_cols=*;

#get distinct patients and then index for speed
drop table if exists user_yenlow.tmp3;
create table user_yenlow.tmp3 as
    select distinct @_cols
    from @_pid
    order by pid;
alter table user_yenlow.tmp3 add primary key (pid);
alter table user_yenlow.tmp3 engine=memory;

#get all nid of relevant patients
drop table if exists user_yenlow._demPid;
create table user_yenlow._demPid as
    select c.pid,c.gender,c.race,c.ethnicity,c.death
    from user_yenlow.tmp3 a, stride5.demographics c
    where a.pid=c.pid
    order by pid;
alter table user_yenlow._demPid add primary key (pid);
select * from user_yenlow._demPid limit 5;

