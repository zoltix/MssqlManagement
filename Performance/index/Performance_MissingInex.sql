

/* 
select 'drop index '+ name + ' on ' + OBJECT_NAME(OBJECT_ID),* from sys.indexes
WHERE name LIKE '%missing%'
*/


SELECT OBJECT_NAME  (117575457)
select * from sys.index_columns

SELECT 
     ind.name 
    ,ind.index_id 
    ,ic.index_column_id 
    ,col.name 
    ,ind.* 
    ,ic.* 
    ,col.* 
FROM sys.indexes ind 
INNER JOIN sys.index_columns ic 
    ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN sys.columns col 
    ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN sys.tables t 
    ON ind.object_id = t.object_id 
WHERE (1=1) 
    AND ind.is_primary_key = 0 
    AND ind.is_unique = 0 
    AND ind.is_unique_constraint = 0 
    AND t.is_ms_shipped = 0 
ORDER BY 
    t.name, ind.name, ind.index_id, ic.index_column_id 


SELECT * FROM sys.dm_db_index_usage_stats;
SELECT OBJECT_ID (266678431)
--
SELECT name
FROM sys.objects
WHERE type = 'U'
AND object_id NOT IN
(SELECT object_id FROM sys.indexes WHERE index_id = 1)


SELECT DISTINCT OBJECT_NAME(sis.OBJECT_ID) TableName, si.name AS IndexName, sc.Name AS ColumnName,
sic.Index_ID, sis.user_seeks, sis.user_scans, sis.user_lookups, sis.user_updates,*
FROM sys.dm_db_index_usage_stats sis
INNER JOIN sys.indexes si ON sis.OBJECT_ID = si.OBJECT_ID AND sis.Index_ID = si.Index_ID
INNER JOIN sys.index_columns sic ON sis.OBJECT_ID = sic.OBJECT_ID AND sic.Index_ID = si.Index_ID
INNER JOIN sys.columns sc ON sis.OBJECT_ID = sc.OBJECT_ID AND sic.Column_ID = sc.Column_ID

--WHERE   OBJECT_NAME(sis.OBJECT_ID)  LIKE '%eventidx_sv%'
ORDER BY sis.user_seeks desc

--WHERE sis.Database_ID = DB_ID('AdventureWorks') AND sis.OBJECT_ID = OBJECT_ID('HumanResources.Employee');


--
SELECT object_name(object_id) as objet, d.*, s.*
FROM sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
ON g.index_group_handle = s.group_handle
WHERE database_id = db_id()
ORDER BY  s.user_seeks DESC, object_id
-----

SELECT
cast( ('CREATE INDEX nix$' + lower(object_name(object_id)) + '$' 
+ REPLACE(REPLACE(REPLACE(COALESCE(equality_columns, inequality_columns), ']', ''), '[', ''), ', ', '_')
+ ' ON ' + statement + ' (' + COALESCE(equality_columns, inequality_columns) + ') INCLUDE (' + included_columns + ')')  as varchar(8000))
--,object_name(object_id) as objet
FROM sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
ON g.index_group_handle = s.group_handle
WHERE database_id = db_id()
ORDER BY  s.user_seeks DESC, object_id    
--Recommanded


SELECT migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS impact,
  mid.statement,migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
  'CREATE INDEX [lli_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle)
  + '_' + LEFT (PARSENAME(mid.statement, 1), 32) + ']'
  + ' ON ' + mid.statement
  + ' (' + ISNULL (mid.equality_columns,'')
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (mid.inequality_columns, '')
  + ')'
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
  migs.*, mid.database_id, mid.[object_id]
 
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10
	AND 	mid.statement LIKE '%crdcrm%'
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC


--Not Use index
/* 
http://weblogs.sqlteam.com/mladenp/archive/2009/04/08/SQL-Server---Find-missing-and-unused-indexes.aspx
*/
SELECT 
o.name
, indexname=i.name
, i.index_id   
, reads=user_seeks + user_scans + user_lookups   
, writes =  user_updates   
, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id)
, CASE
	WHEN s.user_updates < 1 THEN 100
	ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
  END AS reads_per_write
, 'DROP INDEX ' + QUOTENAME(i.name) 
+ ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) as 'drop statement',*
FROM sys.dm_db_index_usage_stats s  
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.object_id = i.object_id   
INNER JOIN sys.objects o on s.object_id = o.object_id
INNER JOIN sys.schemas c on o.schema_id = c.schema_id
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
AND s.database_id = DB_ID()   
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
AND user_seeks + user_scans + user_lookups = 0
--AND (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id) > 10000

ORDER BY writes DESC 







SELECT user_seeks,OBJECT_SCHEMA_NAME(IS.OBJECT_ID) AS SchemaName,
        OBJECT_NAME(IS.OBJECT_ID) AS ObjectName,*
		FROM sys.dm_db_index_usage_stats Is
			INNER JOIN sys.indexes i ON i.index_id = Is.index_id AND s.object_id = i.object_id   
WHERE OBJECT_NAME(I.OBJECT_ID) LIKE '%eventidx_sv%'
ORDER BY user_seeks DESC 



SELECT  OBJECT_SCHEMA_NAME(I.OBJECT_ID) AS SchemaName,
        OBJECT_NAME(I.OBJECT_ID) AS ObjectName,
        I.NAME AS IndexName        
FROM    sys.indexes I   
WHERE   -- only get indexes for user created tables
        OBJECTPROPERTY(I.OBJECT_ID, 'IsUserTable') = 1 
        -- find all indexes that exists but are NOT used
        AND NOT EXISTS ( 
                    SELECT  index_id 
                    FROM    sys.dm_db_index_usage_stats
                    WHERE   OBJECT_ID = I.OBJECT_ID 
                            AND I.index_id = index_id 
                            -- limit our query only for the current db
                           -- AND database_id = DB_ID()
          					   ) 
ORDER BY SchemaName, ObjectName, IndexName 




DBCC OPENTRAN




 




 CREATE INDEX [lli_index_1565_1564_HospitalisatieVordering] 
	ON [SsnFbz].[FBZ].[HospitalisatieVordering] ([FbzLid_id]) 
		INCLUDE ([id], [alumnus], [betalingsDatum], [bic], [burgerlijkeStaat], [busnummer], [creatieDatum], [familienaam], [gemeente], [gestructureerdeMededeling], [huisnummer], [iban], [insz], [land], [postcode], [sleutel], [code], [reden], [straat], [taal], [voornaam], [vrijeMededeling], [werkgeverKboNummer], [werkgeverNaam], [werkgeverRechtsvorm], [domicilieringsnummer], [eindDatum], [startDatum], [uitersteBetaaldatum], [inszVerzekerde], [bedrag_id], [mandaatDatum])