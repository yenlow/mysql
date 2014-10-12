# Get labs of selected patients
# Output:  	tmp3 (store in memory)
#			_labPid (labs selected patients) ->
# 16-Nov-13 Yen Low
#####################


#@_ is a fake handler. Use R to global replace.
#set @_pid=user_yenlow.mirtazapine_pidBeforeAfterMir;
#set @_cols=*;
#set @_labExtract=user_yenlow.mirtazapine_labPidSer;

#get distinct patients and then index for speed
drop table if exists user_yenlow.tmp3;
create table user_yenlow.tmp3 as
    select distinct @_cols
    from @_pid
    order by pid;
alter table user_yenlow.tmp3 add primary key (pid);
alter table user_yenlow.tmp3 engine=memory;

#get all labs of relevant patients
drop table if exists user_yenlow._labPid;
create table user_yenlow._labPid as
    select 	c.pid,c.timeoffset,c.lid,c.component,c.description,
    		c.proc,c.proc_cat,c.ord,c.ord_num,
    		c.result_flag,c.ref_low,c.ref_high,c.ref_unit
    from user_yenlow.tmp3 a, @_labExtract c
    where a.pid=c.pid
    order by pid, timeoffset, lid;
alter table user_yenlow._labPid add index (lid);
alter table user_yenlow._labPid add index (pid);
select * from user_yenlow._labPid limit 5;

