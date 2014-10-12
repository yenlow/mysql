# Get visits of selected patients
# Output:  	tmp3 (store in memory)
#			_visitPid (demographics info of selected patients) ->
# 15-Nov-13 Yen Low
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

#get all visits of relevant patients
drop table if exists user_yenlow._visitPid;
create table user_yenlow._visitPid as
    select c.pid,c.visit,c.timeoffset,c.year,c.src_type,c.cpt,c.icd9,c.src
    from user_yenlow.tmp3 a, stride5.visit c
    where a.pid=c.pid
    order by pid;
alter ignore table user_yenlow._visitPid add unique (pid,visit);
alter table user_yenlow._visitPid add index (visit);
alter table user_yenlow._visitPid add index (pid);
select * from user_yenlow._visitPid limit 5;

