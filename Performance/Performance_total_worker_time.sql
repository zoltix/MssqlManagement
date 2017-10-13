SELECT  COALESCE(DB_NAME(st.dbid),
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
                  DATEADD(ms,(total_worker_time/execution_count)/1000,0),
                          121),
                  12,23)  AVG_CPU_MS,execution_count executionCount,execution_count,CAST ( max_elapsed_time  as NUMERIC(17,2))/1000000 AS MaxTimeSeconde,
			CAST( total_elapsed_time/execution_count AS NUMERIC(17,4))/1000000  AS AverageTimeSeconde              
      ,*

FROM sys.dm_exec_query_stats  
   CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
   OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) pa
    WHERE attribute = 'dbid'  
		--AND DB_NAME(CAST(pa.value as int))   LIKE  'Invoicing%' 				
		AND 
		(				
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
        ) 
         NOT LIKE '%SCHEMA_NAME%'  )
        
  and        
	execution_count > 10
   ORDER BY sys.dm_exec_query_stats.execution_count DESC 


   21 025 801
--SELECT * FROM sys.dm_exec_query_stats   

2 084 607

SELECT @ret= commStateId 
	FROM dbo.Communicationstate
	WHERE communicationState = @sCommunicationStateName

	
	