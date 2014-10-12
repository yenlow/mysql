# Stacks rx, visits, labs of selected patients (ideally, should have identical pid)
# Output:  	_unionFeatures ->
# 16-Nov-13 Yen Low
#####################

#@_ is a fake handler. Use R to global replace.
#set @_rx=user_yenlow.mirtazapine_rxPidSer;
#set @_visit=user_yenlow.mirtazapine_visitPidSer;
#set @_lab=user_yenlow.mirtazapine_labPidSer;

#get distinct patients and then index for speed
alter table @_rx order by pid, timeoffset;
alter table @_visit order by pid, timeoffset;
alter table @_lab order by pid, timeoffset;
alter table @_lab add index (pid);
    
drop table if exists user_yenlow._unionFeatures;
create table user_yenlow._unionFeatures as
    (select pid,timeoffset,rxid,drug_description,route,order_status,ingr_set_id,
    null as year,null as visit,null as src_type,null as cpt,null as icd9,null as src,
    null as lid,null as component,null as description,null as proc,null as proc_cat,
    null as ord,null as ord_num,null as result_flag,null as ref_low,null as ref_high,null as ref_unit
    from @_rx)
    
    union all		
    
    (select pid,timeoffset,
    null as rxid,null as drug_description,null as route,
    null as order_status,null as ingr_set_id,
    year,visit,src_type,cpt,icd9,src,
    null as lid,null as component,null as description,null as proc,null as proc_cat,
    null as ord,null as ord_num,null as result_flag,null as ref_low,null as ref_high,null as ref_unit
    from @_visit)
    
    union all		
    
    (select pid,timeoffset,
    null as rxid,null as drug_description,null as route,
    null as order_status,null as ingr_set_id,
    null as year,null as visit,null as src_type,null as cpt,null as icd9,null as src,
    lid,component,description,proc,proc_cat,ord,ord_num,result_flag,ref_low,ref_high,ref_unit
    from @_lab)
    
    order by pid, timeoffset;

alter table user_yenlow._unionFeatures add index (pid);

select * from user_yenlow._unionFeatures limit 30;
