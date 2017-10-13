SELECT
CAST(
        serverproperty(N'Servername')
       AS sysname) AS [Server_Name],
'Server[@Name=' + quotename(CAST(
        serverproperty(N'Servername')
       AS sysname),'''') + ']' + '/ResourceGovernor' AS [Urn],
	   c.classifier_function_id,
	   QUOTENAME(OBJECT_SCHEMA_NAME(c.classifier_function_id, 1)) AS OBJECT_SCHEMA_NAME,	 
       OBJECT_NAME(1307867726) AS test,                                                        
	   QUOTENAME(OBJECT_SCHEMA_NAME(c.classifier_function_id, 1)) + N'.' + OBJECT_NAME(c.classifier_function_id, 1),  
      CASE WHEN OBJECT_NAME(c.classifier_function_id) IS NULL THEN OBJECT_NAME(c.classifier_function_id)  
      	  ELSE QUOTENAME(OBJECT_SCHEMA_NAME(c.classifier_function_id, 1)) + N'.' + QUOTENAME(OBJECT_NAME(c.classifier_function_id, 1))  END
     AS [ClassifierFunction],
CAST(c.is_enabled AS bit) AS [Enabled],
CAST((SELECT is_reconfiguration_pending FROM sys.dm_resource_governor_configuration) AS bit) AS [ReconfigurePending]
FROM
sys.resource_governor_configuration AS c

1307867726

SELECT * FROM master.sys.databases
SELECT * FROM master.sys.objects WHERE object_id = 1307867726
SELECT OBJECT_SCHEMA_NAME(1307867726, 1)
SELECT OBJECT_NAME(1307867726, 1)
SELECT OBJECT_NAME(1307867726,1) 


SELECT
            rpool.name as PoolName,
            COALESCE(SUM(rgroup.total_request_count), 0) as TotalRequest,
            COALESCE(SUM(rgroup.total_cpu_usage_ms), 0) as TotalCPUinMS,
            CASE 
                  WHEN SUM(rgroup.total_request_count) > 0 THEN
                        SUM(rgroup.total_cpu_usage_ms) / SUM(rgroup.total_request_count)
                        ELSE
                        0 
                  END as AvgCPUinMS
      FROM
      sys.dm_resource_governor_resource_pools AS rpool
      LEFT OUTER JOIN
      sys.dm_resource_governor_workload_groups  AS rgroup
      ON 
          rpool.pool_id = rgroup.pool_id
      GROUP BY
          rpool.name;


		  SELECT 
   name,
   [start] = statistics_start_time,
   cpu = total_cpu_usage_ms,
   memgrant_timeouts = total_memgrant_timeout_count,
   out_of_mem = out_of_memory_count,     mem_waiters = memgrant_waiter_count
FROM 
   sys.dm_resource_governor_resource_pools
WHERE
   pool_id > 1;
   
SELECT 
   name,
   [start] = statistics_start_time,
   waiters = queued_request_count, -- or total_queued_request_count
   [cpu_violations] = total_cpu_limit_violation_count,
   subopt_plans = total_suboptimal_plan_generation_count,
   reduced_mem = total_reduced_memgrant_count
FROM
   sys.dm_resource_governor_workload_groups
WHERE
   group_id > 1;



   SELECT *
FROM sys.dm_os_performance_counters
WHERE object_name IN
('SQLServer:Workload Group Stats','SQLServer:Resource Pool Stats')
AND instance_name = 'default'


SELECT * FROM sys.resource_governor_workload_groups
SELECT * FROM sys.resource_governor_resource_pools
SELECT * FROM sys.resource_governor_configuration
