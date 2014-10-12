# Create rxnorm tables
# Yen Low 11-Dec-13

drop table if exists rxnorm.rxnorm_rxid;
create table rxnorm.rxnorm_rxid as
SELECT  b.code as ingredient,
        c.code as drug
FROM    terminology3.rxnorm_cui a, 
        umls2011ab.MRCONSO b, umls2011ab.MRCONSO c
where b.sab='RXNORM' and a.ingredient=b.cui
and c.sab='RXNORM' and a.drug=c.cui;
alter table rxnorm.rxnorm_rxid modify ingredient mediumint(8), modify drug  mediumint(8);
alter table rxnorm.rxnorm_rxid add index (ingredient), add index (drug);

#Create rxnorm.pin2in tables mapping precise ingredient to ingredient
create table rxnorm.pin2in_cui as
SELECT CUI1 as PIN, CUI2 as `IN`
FROM umls2011ab.MRREL 
where sab='RXNORM' and rela like 'has_form';

drop table if exists user_yenlow.tmp;
create table user_yenlow.tmp as
select cid, cui from terminology3.str2cid where grp=2;

drop table if exists rxnorm.pin2in;
create table rxnorm.pin2in as
SELECT b.cid as PIN, c.cid as `IN`
FROM rxnorm.pin2in_cui a, user_yenlow.tmp b,  user_yenlow.tmp c
where a.pin=b.cui and a.in=c.cui;

ALTER TABLE rxnorm.pin2in MODIFY pin int(8) NOT NULL;
ALTER TABLE rxnorm.pin2in MODIFY `in` int(8) NOT NULL;
ALTER TABLE rxnorm.pin2in ADD index(pin), ADD index(`in`);


drop table if exists user_yenlow.tmp2;
create table user_yenlow.tmp2
    select a.ingredient as rxcui, b.cui, b.str
    from    (select distinct ingredient from rxnorm.rxnorm_rxid) a
    left outer join umls2011ab.MRCONSO b       
    on a.ingredient=b.code
    where b.sab='rxnorm' and b.tty='in';
alter table  user_yenlow.tmp2 modify rxcui mediumint(8), modify cui char(8);
alter table  user_yenlow.tmp2 add index (cui);


drop table if exists rxnorm.cid2rxcui_ingredient;
create table rxnorm.cid2rxcui_ingredient
    select distinct a.*, c.cid
    from    user_yenlow.tmp2 a, 
            (select cui, cid from terminology3.str2cid where grp=2) c
    where a.cui=c.cui;
select * from rxnorm.cid2rxcui_ingredient limit 10;
alter table  rxnorm.cid2rxcui_ingredient drop str, drop cui;
alter table  rxnorm.cid2rxcui_ingredient add index (rxcui), add index (cid);


drop table user_yenlow.tmp;
drop table user_yenlow.tmp2;
