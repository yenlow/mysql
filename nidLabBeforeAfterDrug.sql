# Get note ID of patients with labs before AND after indexTime (start of drug)
# Output:  	tmp3 (unique pid with labs b4 and after indexTime; paired by component)
#			_nidBeforeAfter (note id of patients with labs before and after indexTime) ->
# 10-Nov-13 Yen Low
#####################


#@_ is a fake handler. Use R to global replace.
#set @_pidBeforeAfterDrug=user_yenlow.mirtazapine_pidBeforeAfterMir;
#set @_someComponentCriteria=like '%';

#get distinct patients and then index for speed
#decide if AnyLabBeforeAndAfter=1
#or PairedLabBeforeAndAfter=1 (which components)
drop table if exists user_yenlow.tmp3;
create table user_yenlow.tmp3 (pid mediumint) engine=memory;
    insert into user_yenlow.tmp3 select distinct pid 
    from @_pidBeforeAfterDrug
    where AnyLabBeforeAndAfter=1
    and component @_someComponentCriteria;
alter table user_yenlow.tmp3 add primary key (pid);

#get all nid of relevant patients
drop table if exists user_yenlow._nidBeforeAfterDrug;
create table user_yenlow._nidBeforeAfterDrug as
    select c.pid, c.nid, c.timeoffset, c.src_type, c.year, c.icd9
    from user_yenlow.tmp3 a, stride5.note c
    where a.pid=c.pid;
alter table user_yenlow._nidBeforeAfterDrug add primary key (nid);
select * from user_yenlow._nidBeforeAfterDrug limit 5;
#export _nidBeforeAfterDrug -> mirtazapine_nidBeforeAfterMir

