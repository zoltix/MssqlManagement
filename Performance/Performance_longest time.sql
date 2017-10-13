--SELECT SUM(Size*Free)/1024 AS [Total avail mem, KB]  
--FROM VASummary  
--WHERE Free <> 0 


 SELECT TOP 100  COALESCE(DB_NAME(st.dbid),
                DB_NAME(CAST(pa.value as int))+'*',
                'Resource') AS DBNAME, 
       SUBSTRING(text,
        -- starting value for substring 
        CASE WHEN statement_start_offset = 0 
             OR statement_start_offset IS NULL 
               THEN 1 
               ELSE statement_start_offset/2 + 1 END,
        -- ending value for substring
        CASE WHEN statement_end_offset = 0 
          OR statement_end_offset = -1 
          OR statement_end_offset IS NULL 
               THEN LEN(text) 
               ELSE statement_end_offset/2 END - 
                   CASE WHEN statement_start_offset = 0 
                          OR statement_start_offset IS NULL 
                               THEN 1 
                               ELSE statement_start_offset/2  END + 1
        )  AS TSQL, 
               SUBSTRING(CONVERT(CHAR(23),
                  DATEADD(ms,(total_elapsed_time/execution_count)/1000,0),
                          121),
                  12,23) AS AVG_ELAPSED_TIME,execution_count,total_worker_time,total_physical_reads,total_logical_writes,total_logical_reads
FROM sys.dm_exec_query_stats  
   CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
   OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) pa
    WHERE attribute = 'dbid' --AND  DB_NAME(CAST(pa.value as int)) = 'IrisNextV2'  
  
      
   ORDER BY total_logical_writes DESC ;







 SELECT TOP 100  COALESCE(DB_NAME(st.dbid),
                DB_NAME(CAST(pa.value as int))+'*',
                'Resource') AS DBNAME, 
       SUBSTRING(text,
        -- starting value for substring 
        CASE WHEN statement_start_offset = 0 
             OR statement_start_offset IS NULL 
               THEN 1 
               ELSE statement_start_offset/2 + 1 END,
        -- ending value for substring
        CASE WHEN statement_end_offset = 0 
          OR statement_end_offset = -1 
          OR statement_end_offset IS NULL 
               THEN LEN(text) 
               ELSE statement_end_offset/2 END - 
                   CASE WHEN statement_start_offset = 0 
                          OR statement_start_offset IS NULL 
                               THEN 1 
                               ELSE statement_start_offset/2  END + 1
        )  AS TSQL, 
               SUBSTRING(CONVERT(CHAR(23),
                  DATEADD(ms,(total_elapsed_time/execution_count)/1000,0),
                          121),
                  12,23) AS AVG_ELAPSED_TIME,execution_count,total_worker_time,total_physical_reads,total_logical_writes,total_logical_reads
FROM sys.dm_exec_query_stats  
   CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
   OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) pa
    WHERE attribute = 'dbid' --AND  DB_NAME(CAST(pa.value as int)) = 'IrisNextV2'  
  
      
   ORDER BY AVG_ELAPSED_TIME DESC ;



   SET STATISTICS TIME ON;
GO

SELECT TOP 10 DB_NAME(q.dbid) AS DATABASE_CONTEXT, text AS SQL_QUERY, query_plan AS EXECUTION_PLAN
FROM   sys.dm_exec_query_stats AS s WITH(NOLOCK)
       CROSS APPLY sys.dm_exec_query_plan(s.plan_handle) p
       CROSS APPLY sys.dm_exec_sql_text(s.plan_handle) AS q
WHERE  p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
                           max(//p:RelOp/@Parallel)', 'float') > 0
ORDER  BY total_worker_time/execution_count DESC
OPTION (MAXDOP 1);