SELECT  OBJECT_NAME(ddius.[object_id], ddius.database_id) AS [object_name] , i.name,p.rows,
        ddius.index_id ,
        ddius.user_seeks ,
        ddius.user_scans ,
        ddius.user_lookups ,
        ddius.user_seeks + ddius.user_scans + ddius.user_lookups     
                                                     AS user_reads ,
        ddius.user_updates AS user_writes ,
        ddius.last_user_scan ,
        ddius.last_user_update,*
FROM    sys.dm_db_index_usage_stats ddius
		INNER JOIN sys.tables t ON t.object_id = ddius.[object_id]
		INNER JOIN sys.indexes i ON i.object_id=t.object_id AND i.index_id = ddius.index_id
		LEFT OUTER join sys.partitions p ON t.object_id = p.OBJECT_ID AND i.index_id = p.index_id
WHERE   ddius.database_id > 4 -- filter out system tables
        AND OBJECTPROPERTY(ddius.OBJECT_ID, 'IsUserTable') = 1
        AND ddius.index_id > 0  -- filter out heaps 
		--AND  OBJECT_NAME(ddius.[object_id], ddius.database_id)  ='DCOBJECT_T_LINK'
		AND  i.name LIKE 'indexFilteredShelvedStatus%'
ORDER BY p.rows,ddius.user_scans DESC


