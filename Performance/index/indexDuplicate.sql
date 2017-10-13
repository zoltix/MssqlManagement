-- exact duplicates
WITH    indexcols
          AS ( SELECT   object_id AS id ,
                        index_id AS indid ,
                        name ,
                        ( SELECT    CASE keyno
                                      WHEN 0 THEN NULL
                                      ELSE colid
                                    END AS [data()]
                          FROM      sys.sysindexkeys AS k
                          WHERE     k.id = i.object_id
                                    AND k.indid = i.index_id
                          ORDER BY  keyno ,
                                    colid
                        FOR
                          XML PATH('')
                        ) AS cols ,
                        ( SELECT    CASE keyno
                                      WHEN 0 THEN colid
                                      ELSE NULL
                                    END AS [data()]
                          FROM      sys.sysindexkeys AS k
                          WHERE     k.id = i.object_id
                                    AND k.indid = i.index_id
                          ORDER BY  colid
                        FOR
                          XML PATH('')
                        ) AS inc
               FROM     sys.indexes AS i
						 ), details AS (SELECT  ddius.[object_id] AS [object_id],OBJECT_NAME(ddius.[object_id], ddius.database_id) AS [object_name] , i.name,p.rows,
					ddius.index_id ,
					ddius.user_seeks ,
					ddius.user_scans ,
					ddius.user_lookups ,
					ddius.user_seeks + ddius.user_scans + ddius.user_lookups 
																 AS user_reads ,
					ddius.user_updates AS user_writes ,
					ddius.last_user_scan ,
					ddius.last_user_update
			FROM    sys.dm_db_index_usage_stats ddius
					INNER JOIN sys.tables t ON t.object_id = ddius.[object_id]
					INNER JOIN sys.indexes i ON i.object_id=t.object_id AND i.index_id = ddius.index_id
					LEFT OUTER join sys.partitions p ON t.object_id = p.OBJECT_ID AND i.index_id = p.index_id
			WHERE   ddius.database_id > 4 -- filter out system tables
					AND OBJECTPROPERTY(ddius.OBJECT_ID, 'IsUserTable') = 1
					AND ddius.index_id > 0  -- filter out heaps 
					--AND  OBJECT_NAME(ddius.[object_id], ddius.database_id)  ='DCOBJECT_T_LINK'			 
			 )

	

    SELECT  OBJECT_SCHEMA_NAME(c1.id) + '.' + OBJECT_NAME(c1.id) AS 'table' ,
            c1.name AS 'index' ,
            c2.name AS 'exactduplicate',
			p.rows,  
			d.user_seeks,
		  d.user_scans ,
        d.user_lookups ,
        d.user_seeks + d.user_scans + d.user_lookups     AS user_reads ,
        d.user_writes AS user_writes ,
        d.last_user_scan ,
        d.last_user_update

	    FROM    indexcols AS c1
            JOIN indexcols AS c2 ON c1.id = c2.id
                                    AND c1.indid < c2.indid
                                    AND c1.cols = c2.cols
                                    AND c1.inc = c2.inc
		   inner JOIN sys.tables t ON t.object_id = C1.id
		   INNER JOIN sys.partitions p ON c1.id = p.OBJECT_ID AND c1.indid = p.index_id
		   INNER JOIN details d  ON d.index_id = c1.indid AND d.[object_id]= c1.id
ORDER BY user_writes DESC 


