# Query patients on drug of interest  in stride 5 (can enter multiple drug ingredients)
# Took 2min for 6000 pid on mirtazapine; 30min for 21000 pid on sertraline
#
# Output:   _rxMirtazapinebyIngSet (rx orders with mirtazapine as ingredient)
#           _mirtazapine_cui (drug cuis in RxNorm ingredient cui="mirtazapine")
#           _mirtazapine_tid (tids related to above drug CUIS -> numPidPerMirtazapineTid.xls)
#           _mirtazapine_nidWithMirtazapine (nid containing above tid matching mirtazapine)
#           _mirtazapine_noteWithMirtazapine (notes containing above tid matching mirtazapine)
#           mirtazapine_pidFreq_mirtazapine_tid (-> numPidPerMirtazapineTid.xls)
#           mirtazapine_pidOnMirtazapine (unique patients on Mirtazapine from Rx orders and notes)
# 17-Sep-14 commented out pain cocktail line, use UMLS2014aa instead of UMLS2011ab
# 16-Nov-13 Yen Low
#####################3

#use gsub in R to replace the global variables instead
#set @drugIng='%mirtazapine%';
#set @minage=18;
# _variables are NOT global variables in mysql but for handling in R by gsub
#set _tblTidDrug             =user_yenlow.mirtazapine_tidSertraline;
#set _tblPidFreqPerTidDrug   =user_yenlow.mirtazapine_pidFreq_tidSertraline;
#set _tblPidDrug             =user_yenlow.mirtazapine_pidSertraline;


### 1. BY RX ORDERS
#get rx records with mirtazapine in drug ingredient set
#load ingr_set_id into memory for speed;
drop table if exists user_yenlow._ingr;
create table user_yenlow._ingr as
    SELECT ingr_set_id FROM stride5.ingredient 
    where ingredient like @drugIng
    order by ingr_set_id;
alter table user_yenlow._ingr add index (ingr_set_id);
alter table user_yenlow._ingr engine=memory;


drop table if exists user_yenlow._rxDrug;
create table user_yenlow._rxDrug as
    SELECT a.* 
    FROM user_yenlow._ingr b, stride5.prescription a
    where a.ingr_set_id= b.ingr_set_id
    and age>=@minage;
#SELECT * FROM user_yenlow._rxDrug;
alter table user_yenlow._rxDrug add index (ingr_set_id);


#Exclude known cocktails (e.g. with trazodone)
#delete from user_yenlow._rxDrug where drug_description='pain cocktail';

#save table
drop table if exists user_yenlow._pidFreq_rxDrug;
create table user_yenlow._pidFreq_rxDrug
    SELECT count(distinct pid) as numPid,  ingr_set_id, drug_description, route
    FROM user_yenlow._rxDrug
    group by drug_description
    order by numPid desc;
select * from user_yenlow._pidFreq_rxDrug;


### 2. BY NOTES ###
#select drug cuis in RxNORM containing ingredient cui=drugIng
drop table if exists user_yenlow._cuiDrug;
create table user_yenlow._cuiDrug as
select rxnorm.drug
    from terminology3.rxnorm_cui rxnorm, 
        (select cui from umls2014aa.MRCONSO
        where SAB like 'RXNORM%' and tty like 'in' and STR like @drugIng) ing
    where rxnorm.ingredient=ing.cui;
alter table user_yenlow._cuiDrug add index (drug);

#get tids related to above drug CUIS
drop table if exists user_yenlow._tidDrug;
create table user_yenlow._tidDrug as
    select distinct a.*, c.str as tid_str, d.str as cid_str
    from terminology3.tid2cid a,
        (SELECT terms.tid
        FROM user_yenlow._cuiDrug cui, terminology3.terms terms
        where terms.ontology like '%rxnorm%'
        and cui.drug = terms.cui) b,
#map tid to str
        terminology3.str2tid c,
#map cid to str
        terminology3.str2cid d
    where a.suppress=0 and a.grp=2
    and a.tid=b.tid
    and c.tid=b.tid
    and d.cid=a.cid
    order by cid_str, tid_str;
alter table user_yenlow._tidDrug add index (tid);
#export to suppress_mirtazapineTid.xls
#!!check if certain Tids need to be manually suppressed by tid!!#

#get notes with above tids corresponding to drugIng
drop table if exists user_yenlow._nidDrug;
create table user_yenlow._nidDrug as
    SELECT distinct tid.tid_str, mgrep.*
    FROM user_yenlow._tidDrug tid, stride5.mgrep mgrep
    where mgrep.negated=0 and mgrep.familyHistory=0
    and mgrep.tid=tid.tid;
alter table user_yenlow._nidDrug add index (nid);
alter table user_yenlow._nidDrug add index (tid);

#select patients with notes mentioning the above tids corr to drugIng
drop table if exists user_yenlow._noteDrug;
create table user_yenlow._noteDrug as
    select note.*, nid.tid, nid.tid_str
    from user_yenlow._nidDrug nid, stride5.note note
    where nid.nid=note.nid
    and age>=@minage;
alter table user_yenlow._noteDrug add index (nid);
alter table user_yenlow._noteDrug add index (tid);

#count number of unique patients with notes mentioning the above tids corr to drugIng
drop table if exists user_yenlow._pidFreq_tidDrug;
create table user_yenlow._pidFreq_tidDrug as
    select tid, tid_str, count(distinct pid) as numPid
    from user_yenlow._noteDrug
    group by tid
    order by numPid desc;
#select * from user_yenlow._pidFreq_tidDrug;
#!!check if certain Tids need to be manually suppressed by pidFreq!!#


### 3. UNION PATIENTS ON drugIng IN RX ORDERS AND IN NOTES ###
#get unique pid on drugIng from rx orders and notes
#2424 in rx + 19106 in notes -> 21491 total
drop table if exists user_yenlow._pidDrug;
create table user_yenlow._pidDrug as
    select a.pid, min(a.timeoffset) as indexTime, max(a.timeoffset) as lastExposureTime, min(age) as ageIndexTime
    from    (select pid, timeoffset, age from user_yenlow._rxDrug
            union
            select pid, timeoffset, age from user_yenlow._noteDrug) a
    group by pid;
alter table user_yenlow._pidDrug add primary key (pid);
alter table user_yenlow._pidDrug add index (ageIndexTime, indexTime);
delete from user_yenlow._pidDrug where ageIndexTime<@minage;
#select * from user_yenlow._pidDrug;

select count(distinct pid) from user_yenlow._pidDrug;

