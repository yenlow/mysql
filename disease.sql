# Find top-level CUIs for Alzheimers disease
# string search: contains 'diabet*'
#                exclude terms '+diabet* -"type i" -"type 1" -"type ia" -"type ib" -mastopathy 
#                            -gestational -neonatal -child* -pregnan* -maternal* -puerperium -young -youth -foetopathy 
#                            -"drug induced" -"drug-induced" -"chemical induced" -"chemical-induced" -"steroid-induced" -"steroid induced"
#                            -insipidus -ketoacido* -"structurally abnormal insulin" -diet 
#                            -posttransplant -"cystic fibrosis" -diabeticorum -secondary'
# exclude ICDs: V (screening/fam hist), 648 (neonatal), 775 (pregnancy-induced), 250.1 (ketoacidosis), 253, 588 (insipidus)
# almost similar to algorithm used by pheKB (has criteria for glucose labs, rx, only ICD 250.x0, 250.x2)
# http://www.phekb.org/phenotype/type-2-diabetes-mellitus
# Yen Low 11-Feb-14

# make a slice by selecting:
#       strings containing 'diabetes'
#       exclude terms "type i", neonatal(ICD9: 648), gestational, pregnancy (ICD9:775), screening, fam history (ICD: Vxx)
drop table if exists user_yenlow._diabetes;
create table user_yenlow._diabetes as
    select distinct str, cui, sab, code
    from umls2011ab.MRCONSO
    where SAB in ('ICD9CM')
    and match(str) against('+diabet* -"type i" -"type 1" -"type ia" -"type ib" -mastopathy 
                            -gestational -neonatal -child* -pregnan* -maternal* -puerperium -young -youth -foetopathy 
                            -"drug induced" -"drug-induced" -"chemical induced" -"chemical-induced" -"steroid-induced" -"steroid induced"
                            -insipidus -ketoacido* -"structurally abnormal insulin" -diet 
                            -posttransplant -"cystic fibrosis" -diabeticorum -secondary'  in boolean mode)
    and code not like '250.1%'
    and code not like '253%'
    and code not like '588%'
    and code not like '648%'
    and code not like '775%'
    and code not like 'V%'
    order by cui, sab, str;
alter table user_yenlow._diabetes add index (cui);
select * from user_yenlow._diabetes;
#40 cuis from ICD9 alone

#2 hop expansion across ontologies
#use isaclosure; cidrewriting only maps between 3 ontologies for diseases (DO, NDRFT, MDR)
#1. map cui to cid and then to parent (c1.cid=r1.cid2, includes 1 hop)
#2. map children to other parent (r1.cid1=r2.cid2; use another copy of isaclosure)
#3. get children of other parent, map to str (r2.cid1=c2.cid)
drop table if exists user_yenlow._2hopDiabetes;
create table user_yenlow._2hopDiabetes
    select  distinct s.*,
            c1.cid, 
            r1.cid1 as cid_child1hop, r2.cid1 as cid_child2hop,
            r1.ontology as ontology1, r2.ontology as ontology2
    from    (select distinct cui from user_yenlow._diabetes) as s,
            terminology3.str2cid as c1,
            terminology3.isaclosure as r1,
            terminology3.isaclosure as r2
    where s.cui=c1.cui
    and c1.cid=r1.cid2 #map cui to all parents (includes 1st hop)
    and r1.cid1=r2.cid2 #get children of parents, map children to other parents (2nd hop)
    order by cid;
select count(*) from user_yenlow._2hopDiabetes;
#16178 hops

#get unique cids from 2 hop expansion
drop table if exists user_yenlow._cidDiabetes;
create table user_yenlow._cidDiabetes
    select c.*, s.str 
    from    terminology3.str2cid s,
            (select distinct cid from user_yenlow._2hopDiabetes
            union
            select distinct cid_child1hop from user_yenlow._2hopDiabetes
            union
            select distinct cid_child2hop from user_yenlow._2hopDiabetes) c
    where c.cid=s.cid;
select count(*) from user_yenlow._cidDiabetes;
#874 cids after 2hop expansion

#remove cids based on exclusion terms
drop table if exists user_yenlow.cidDiabetes;
create table user_yenlow.cidDiabetes
    select * from user_yenlow._cidDiabetes
    where match(str) against('diabet* -"type i" -"type 1" -"type ia" -"type ib" -mastopathy 
                            -gestational -neonatal -child* -pregnan* -maternal* -puerperium -young -youth -foetopathy 
                            -"drug induced" -"drug-induced" -"chemical induced" -"chemical-induced" -"steroid-induced" -"steroid induced"
                            -insipidus -ketoacido* -"structurally abnormal insulin" -diet 
                            -posttransplant -"cystic fibrosis" -diabeticorum -secondary' in boolean mode)
#exclude type 1 or (insulin dependent diabetes)
    and str not regexp ' insulin.dependent'
    and str not regexp '^insulin.dependent';
select * from user_yenlow.cidDiabetes limit 10;
#396 cids after exclusion

#get all term strings, slice strings, mapped to cui strings
#prepare to manually suppress
drop table if exists user_yenlow.diabetes_freq;
create table user_yenlow.diabetes_freq
    select distinct x.*
    from (
        select  g.cid, g.str as cid_str, t.str as term_str,
                t.tid, 
                tc.suppress as tc_suppress, t.suppress as t_suppress, 
                tc.suppress + t.suppress as manual_suppress, tc.source as suppress_reason,
                tc.grp as tc_grp,
                f.patient as pfreq
        from    user_yenlow.cidDiabetes as g, 
                terminology3.tid2cid as tc,
                terminology3.str2tid as t,
                stride4.freqtid as f
        where   g.cid = tc.cid
                and tc.tid = t.tid
                and t.tid = f.tid
        )   as x
    order by pfreq desc;
alter table user_yenlow.diabetes_freq add index (cid, tid);

#alter table (add primary keys, set field types)
alter table user_yenlow.diabetes_freq add primary key(id, cid, cui, tid);
alter table user_yenlow.diabetes_freq CHANGE `manual_suppress` `manual_suppress` INT(4)  NULL  DEFAULT NULL;
select * from user_yenlow.diabetes_freq
group by cid
order by pfreq desc;
#164 tid in 72 cid
#166 rows in 72 cid

#get patient freq by tid
drop table if exists user_yenlow.diabetes_pfreqbytid;
create table user_yenlow.diabetes_pfreqbytid
    select b.cui, a.*
    from user_yenlow.diabetes_freq a
    left join terminology3.str2cid b
    on a.cid=b.cid
    group by tid
    order by pfreq desc;
alter table user_yenlow.diabetes_pfreqbytid add primary key (tid);
select * from user_yenlow.diabetes_pfreqbytid;
#164 unique terms
#export to numPid_tidDiabetes.xls

#check auto-suppression rules
#change mody to niddm mapping
select * from terminology3.tid2cid where tid=32492;
select * from terminology3.str2cid where cid=5902;
#update terminology3.tid2cid    set suppress=1, source='YL wrong mapping'     where tid=32492 and cid=5902;

###########manual suppression############
#unsuppress certain terms (update does not work in mysql workbench)
update user_yenlow.diabetes_pfreqbytid set manual_suppress=0 
        where term_str in ( 'diabetes mellitus type 2 in obese',
                            'diabetic vitreous hemorrhage',
                            'diabetes mellitus type ii',
                            'diabetes mellitus with neuropathy',
                            'autonomic neuropathy due to diabetes',
                            'diabetes mellitus without complication',
                            'diabetic cheirarthropathy',
                            'diabetic mononeuritis multiplex',
                            'diabetes mellitus with polyneuropathy');

#suppress certain terms (mody is ok because of similar mechanism)
update user_yenlow.diabetes_pfreqbytid set manual_suppress=1 
        where term_str in ('irma');
select * from user_yenlow.diabetes_pfreqbytid order by manual_suppress desc;

select count(*) from stride5.note;

#get notes of relevant patients with tid
drop table if exists user_yenlow.diabetes_pidnidtid;
create table user_yenlow.diabetes_pidnidtid as
select distinct a.tid, b.nid, c.*
    from user_yenlow.diabetes_pfreqbytid a, stride5.mgrep b, user_yenlow.nidBeforeAfterMirtazapine c
    where a.manual_suppress is null or a.manual_suppress=0
    and a.tid=b.tid
    and b.nid=c.nid;
select * from user_yenlow.diabetes_pidnidtid;
