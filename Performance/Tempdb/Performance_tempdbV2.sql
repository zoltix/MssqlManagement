




---Identify which type of tempdb objects are consuming  space
SELECT
SUM (user_object_reserved_page_count)*8 as user_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage


--Query that identifies the currently active T-SQL query, it’s text and the Application that is consuming a lot of tempdb space
SELECT es.host_name , es.login_name , es.program_name,
st.dbid as QueryExecContextDBID, DB_NAME(st.dbid) as QueryExecContextDBNAME, st.objectid as ModuleObjectId,
SUBSTRING(st.text, er.statement_start_offset/2 + 1,(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query_Text,
tsu.session_id ,tsu.request_id, tsu.exec_context_id, 
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) as OutStanding_user_objects_page_counts,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) as OutStanding_internal_objects_page_counts,
er.start_time, er.command, er.open_transaction_count, er.percent_complete, er.estimated_completion_time, er.cpu_time, er.total_elapsed_time, er.reads,er.writes, 
er.logical_reads, er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu inner join sys.dm_exec_requests er 
 ON ( tsu.session_id = er.session_id and tsu.request_id = er.request_id) 
inner join sys.dm_exec_sessions es ON ( tsu.session_id = es.session_id ) 
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count+tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)+(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) 
DESC


--Tempdb and the Version Store
SELECT top 5 a.session_id, a.transaction_id, a.transaction_sequence_num, a.elapsed_time_seconds,
b.program_name, b.open_tran, b.status
FROM sys.dm_tran_active_snapshot_database_transactions a
join sys.sysprocesses b
on a.session_id = b.spid
ORDER BY elapsed_time_seconds DESC



--Session In use tempdb
SELECT
  sys.dm_exec_sessions.session_id AS [SESSION ID]
  ,DB_NAME(database_id) AS [DATABASE Name]
  ,HOST_NAME AS [System Name]
  ,program_name AS [Program Name]
  ,login_name AS [USER Name]
  ,status
  ,cpu_time AS [CPU TIME (in milisec)]
  ,total_scheduled_time AS [Total Scheduled TIME (in milisec)]
  ,total_elapsed_time AS    [Elapsed TIME (in milisec)]
  ,(memory_usage * 8)      AS [Memory USAGE (in KB)]
  ,(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)]
  ,(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)]
  ,(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)]
  ,(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)]
  ,CASE is_user_process
             WHEN 1      THEN 'user session'
             WHEN 0      THEN 'system session'
  END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM 
  sys.dm_db_session_space_usage
INNER join
  sys.dm_exec_sessions
ON  sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
WHERE is_user_process = 1
ORDER BY internal_objects_alloc_page_count



--TempDB Space Usage
SELECT
 SPID = s.session_id,
 s.[host_name],
 s.[program_name],
 s.status,
 s.memory_usage,
 granted_memory = CONVERT(INT, r.granted_query_memory*8.00),
 t.text, 
 sourcedb = DB_NAME(r.database_id),
 workdb = DB_NAME(dt.database_id), 
 mg.*,
 su.*
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_db_session_space_usage su
   ON s.session_id = su.session_id
   AND su.database_id = DB_ID('tempdb')
INNER JOIN sys.dm_exec_connections c
   ON s.session_id = c.most_recent_session_id
LEFT OUTER JOIN sys.dm_exec_requests r
   ON r.session_id = s.session_id
LEFT OUTER JOIN (
   SELECT
    session_id,
    database_id
   FROM sys.dm_tran_session_transactions t
   INNER JOIN sys.dm_tran_database_transactions dt
      ON t.transaction_id = dt.transaction_id 
   WHERE dt.database_id = DB_ID('tempdb')
   GROUP BY  session_id,  database_id
   ) dt
   ON s.session_id = dt.session_id
 CROSS APPLY sys.dm_exec_sql_text(COALESCE(r.sql_handle,
 c.most_recent_sql_handle)) t
 LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg
   ON s.session_id = mg.session_id
 WHERE (r.database_id = DB_ID('tempdb')
   OR dt.database_id = DB_ID('tempdb'))
  AND s.status = 'running'
 ORDER BY SPID;






SELECT
                    sys.dm_exec_sessions.session_id AS [SESSION ID],
                    DB_NAME(database_id) AS [DATABASE Name],
                    HOST_NAME AS [System Name],
                    program_name AS [Program Name],
                    login_name AS [USER Name],
                    status,
                    cpu_time AS [CPU TIME (in milisec)],
                    total_scheduled_time AS [Total Scheduled TIME (in milisec)],
                    total_elapsed_time AS    [Elapsed TIME (in milisec)],
                    (memory_usage * 8)      AS [Memory USAGE (in KB)],
                    (user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
                    (user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
                    (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
                    (internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
                    CASE is_user_process
                                         WHEN 1      THEN 'user session'
                                         WHEN 0      THEN 'system session'
                    END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM sys.dm_db_session_space_usage
                                         INNER join
                    sys.dm_exec_sessions
                                         ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id 



--A long running transaction may prevent cleanup of transaction log thus eating up all log space available resulting space crisis for all other applications.
SELECT
                    transaction_id AS [Transacton ID],
                    [name]      AS [TRANSACTION Name],
                    transaction_begin_time AS [TRANSACTION BEGIN TIME],
                    DATEDIFF(mi, transaction_begin_time, GETDATE()) AS [Elapsed TIME (in MIN)],
                    CASE transaction_type
                                         WHEN 1 THEN 'Read/write'
                    WHEN 2 THEN 'Read-only'
                    WHEN 3 THEN 'System'
                    WHEN 4 THEN 'Distributed'
                    END AS [TRANSACTION Type],
                    CASE transaction_state
                                         WHEN 0 THEN 'The transaction has not been completely initialized yet.'
                                         WHEN 1 THEN 'The transaction has been initialized but has not started.'
                                         WHEN 2 THEN 'The transaction is active.'
                                         WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
                                         WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
                                         WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
                                         WHEN 6 THEN 'The transaction has been committed.'
                                         WHEN 7 THEN 'The transaction is being rolled back.'
                                         WHEN 8 THEN 'The transaction has been rolled back.'
                    END AS [TRANSACTION Description]
FROM sys.dm_tran_active_transactions       



--Long running Queries
 
-- sys.dm_exec_requests : Returns information regarding the requests made to the database server.
SELECT
                    HOST_NAME                                                          AS [System Name],
                    program_name                                                      AS [Application Name],
                    DB_NAME(database_id)                  AS [DATABASE Name],
                    USER_NAME(USER_ID)                     AS [USER Name],
                    connection_id                                                       AS [CONNECTION ID],
                    sys.dm_exec_requests.session_id AS [CURRENT SESSION ID],
                    blocking_session_id                         AS [Blocking SESSION ID],
                    start_time                                           AS [Request START TIME],
                    sys.dm_exec_requests.status         AS [Status],
                    command                         AS [Command Type],
                    (SELECT TEXT FROM sys.dm_exec_sql_text(sql_handle)) AS [Query TEXT],
                    wait_type                                           AS [Waiting Type],
                    wait_time                                           AS [Waiting Duration],
                    wait_resource                                                       AS [Waiting FOR Resource],
                    sys.dm_exec_requests.transaction_id AS [TRANSACTION ID],
                    percent_complete                           AS [PERCENT Completed],
                    estimated_completion_time          AS [Estimated COMPLETION TIME (in mili sec)],
                    sys.dm_exec_requests.cpu_time AS [CPU TIME used (in mili sec)],
                    (memory_usage * 8)                        AS [Memory USAGE (in KB)],
                    sys.dm_exec_requests.total_elapsed_time AS [Elapsed TIME (in mili sec)]
FROM sys.dm_exec_requests
                                         INNER join
                    sys.dm_exec_sessions
                                         ON sys.dm_exec_requests.session_id = sys.dm_exec_sessions.session_id
WHERE DB_NAME(database_id) = 'tempdb'                                  



sp_helptext N'spWebCSVouchers99New'

sp_helptext N'[dbo].[AanmakenAangifteRSZ01]'