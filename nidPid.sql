# Get note ID of selected patients
# Output:  	tmp3 (unique pid)
#			_nidPid (note id of selected patients) ->
# 16-Sep-14 removed icd column from stride5.note
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
drop table if exists user_yenlow._nidPid;
create table user_yenlow._nidPid as
    select c.pid, c.nid, c.timeoffset, c.src_type, c.year
    from stride5.note c, user_yenlow.tmp3 a
    where a.pid=c.pid;
alter table user_yenlow._nidPid order by pid, timeoffset,nid;
alter table user_yenlow._nidPid add index (nid);
alter table user_yenlow._nidPid add index (pid);
select * from user_yenlow._nidPid limit 5;

