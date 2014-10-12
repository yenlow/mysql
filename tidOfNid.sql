# Get tid from notes of patients of interest
# Output:  _tidNid (tid features in notes of relevant patients) ->
# 16-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_nid=user_yenlow.mirtazapine_nidBeforeAfterMir;
#set @_minDaysAfterIndexTime=1;
#set @_pid=user_yenlow.mirtazapine_pidBeforeAfterSer;

#load unique pid into memory for speed
drop table if exists user_yenlow.tmp4;
create table user_yenlow.tmp4 (pid mediumint, nid int, timeoffset float) engine=memory;
    insert into user_yenlow.tmp4
    select distinct pid, nid, timeoffset from @_nid;
alter table user_yenlow.tmp4 add primary key (nid);

#take only 1 mention of tid per nid per pid (for space and modeling purpose)
#remove negated terms
drop table if exists user_yenlow._tidNid;
create table user_yenlow._tidNid as
	select distinct a.pid, a.timeoffset, b.nid, b.tid, sum(b.negated) as sumNegated
	from user_yenlow.tmp4 a, stride5.mgrep b
	where a.nid=b.nid and b.familyHistory<>1
	group by b.nid
	having sumNegated=0;
alter table user_yenlow._tidNid add index (pid);
alter table user_yenlow._tidNid add index (nid);
alter table user_yenlow._tidNid add index (tid);

#flatten tid per timeoffset to before or after indexTime
drop table if exists user_yenlow._tidNidBeforeAfter;
create table user_yenlow._tidNidBeforeAfter as
	select distinct a.pid, b.tid, 
			if(b.timeoffset>(a.indexTime+@_minDaysAfterIndexTime),1,0) as afterDrug 
	from @_pid a, user_yenlow._tidNid b
	where a.pid=b.pid
	order by pid, tid;
alter table user_yenlow._tidNidBeforeAfter MODIFY afterDrug tinyint;
alter table user_yenlow._tidNidBeforeAfter add index (pid);
alter table user_yenlow._tidNidBeforeAfter add index (tid);
alter table user_yenlow._tidNidBeforeAfter add index (afterDrug);
