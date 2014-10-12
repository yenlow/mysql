# Get prescriptions of selected patients
# Output:  	tmp3 (store in memory)
#			_rxPid (prescriptions info of selected patients) ->
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

#get all prescriptions of relevant patients
drop table if exists user_yenlow._rxPid;
create table user_yenlow._rxPid as
    select c.pid,c.rxid,c.timeoffset,c.drug_description,c.route,c.order_status,c.ingr_set_id
    from user_yenlow.tmp3 a, stride5.prescription c
    where a.pid=c.pid
    order by pid,timeoffset,rxid;
alter table user_yenlow._rxPid add primary key (rxid);
alter table user_yenlow._rxPid add index (pid);
select * from user_yenlow._rxPid limit 5;

