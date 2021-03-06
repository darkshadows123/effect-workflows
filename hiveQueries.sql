# Create table CDR
CREATE TABLE CDR(`_id` STRING, timestamp INT, raw_content STRING, content_type STRING, url STRING, version STRING, team STRING, source_name STRING)
COMMENT 'Used to store all CDR data'
PARTITIONED BY (year INT, month INT)
CLUSTERED BY(source_name) INTO 256 BUCKETS
STORED AS ORC;

#TBLPROPERTIES('transactional'='true');

#location 's3n://effect-hive-data/cdr';




# Create table for hackmagadden
CREATE TABLE hackmageddon (raw_content STRING)
STORED AS TEXTFILE

# Load data into hackmagadden
LOAD DATA INPATH '/user/effect/hackmageddon-cleaned.jl' INTO TABLE hackmageddon


# Load data into CDR from hackmagadden
FROM hackmageddon h
INSERT INTO TABLE cdr PARTITION(year='2016', month='10')
SELECT concat('hackmageddon/', hex(hash(h.raw_content))), unix_timestamp(), h.raw_content, 'application/json', concat('http://effect.isi.edu/input/hackmageddon/',hex(hash(h.raw_content))), "2.0", "hackmageddon", "hackmageddon"


# Load the HyperionGray CVE Data
#1. Download data from API
#2. Convert JSON to Json Lines - jq -c .[] cve.json > cve.jl
#3. Upload data to hdfs
#4. Load into a hg_cve table
CREATE TABLE hg_cve (raw_content STRING)
STORED AS TEXTFILE

LOAD DATA INPATH '/user/effect/hg_cve.jl' INTO TABLE hg_cve;

#5. Insert data into CDR from hg_cve
FROM hg_cve h
INSERT INTO TABLE cdr PARTITION(year='2016', month='10')
SELECT concat('hg-cve/', hex(hash(h.raw_content))), unix_timestamp(),h.raw_content, 'application/json', concat('http://effect.isi.edu/input/hg/cve/',hex(hash(h.raw_content))),  "2.0", "hyperiongray", "hg-cve"


CREATE TABLE hg_zdi (raw_content STRING)
STORED AS TEXTFILE

LOAD DATA INPATH '/user/effect/hg_zdi.jl' INTO TABLE hg_zdi


FROM hg_zdi h
INSERT INTO TABLE cdr PARTITION(year='2016', month='10')
SELECT concat('hg-zdi/', hex(hash(h.raw_content))), unix_timestamp(),h.raw_content, 'application/json', concat('http://effect.isi.edu/input/hg/zdi/',hex(hash(h.raw_content))),  "2.0", "hyperiongray", "hg-zdi"

#---------------------------------------------------------------------------------------

# Adding data into CDR table from a temprary table It created the partitions
#dynamically from the timestamp

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE CDR PARTITION(year, month, day) SELECT `_id`, timestamp, raw_content, content_type, url, version, team, source_name, year(from_unixtime(timestamp)), month(from_unixtime(timestamp)), day(from_unixtime(timestamp)) FROM cdr_temp;

#---------------------------------------------------------------
#Reloading ASU data in CDR

drop table cdr_temp;
create table cdr_temp as select * from cdr where source_name='hackmageddon' or source_name like 'hg-%';
drop table cdr;
CREATE TABLE CDR(`_id` STRING, timestamp INT, raw_content STRING, content_type STRING, url STRING, version STRING, team STRING, source_name STRING)
COMMENT 'Used to store all CDR data'
PARTITIONED BY (year INT, month INT)
CLUSTERED BY(source_name) INTO 256 BUCKETS
STORED AS ORC;
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE CDR PARTITION(year, month) SELECT `_id`, timestamp, raw_content, content_type, url, version, team, source_name, year(from_unixtime(timestamp)), month(from_unixtime(timestamp)) FROM cdr_temp;


#---------------------------------------------------------------
#Reloading ASU and HG data in CDR

drop table cdr_temp;
create table cdr_temp as select * from cdr where source_name='hackmageddon';
drop table cdr;
CREATE TABLE CDR(`_id` STRING, timestamp INT, raw_content STRING, content_type STRING, url STRING, version STRING, team STRING, source_name STRING)
COMMENT 'Used to store all CDR data'
PARTITIONED BY (year INT, month INT)
CLUSTERED BY(source_name) INTO 256 BUCKETS
STORED AS ORC;
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE CDR PARTITION(year, month) SELECT `_id`, timestamp, raw_content, content_type, url, version, team, source_name, year(from_unixtime(timestamp)), month(from_unixtime(timestamp)) FROM cdr_temp;



