-- List unused indexes
SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name,
		
					p.rows
FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
		LEFT OUTER join sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id

WHERE   i.index_id NOT IN ( SELECT  ddius.index_id
                            FROM    sys.dm_db_index_usage_stats AS ddius
                            WHERE   ddius.[object_id] = i.[object_id]
                                    AND i.index_id = ddius.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
		--AND OBJECT_NAME(i.[object_id])  ='EventIdx_sv'
ORDER BY p.rows DESC ,OBJECT_NAME(i.[object_id]) ASC ;


--SELECT name AS "Name", 
--    is_auto_create_stats_on AS "Auto Create Stats",
--    is_auto_update_stats_on AS "Auto Update Stats",
--    is_auto_update_stats_async_on AS "Asynchronous Update" 
--FROM sys.databases
--GO