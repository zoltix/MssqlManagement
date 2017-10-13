--below code will help you in finding autogrowth events on your server instance.
IF OBJECT_ID('tempdb..#autogrowthTotal') IS NOT NULL
    DROP TABLE #autogrowthTotal;

IF OBJECT_ID('tempdb..#autogrowthTotal_Final') IS NOT NULL
    DROP TABLE #autogrowthTotal_Final;

DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);

-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1
    AND property = 2;

-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.', @filename);
SET @ec = CHARINDEX('_', @filename) + 1;
SET @efn = REVERSE(SUBSTRING(@filename, 1, @bc));
SET @bfn = REVERSE(SUBSTRING(@filename, @ec, LEN(@filename)));
-- set filename without rollover number
SET @filename = @bfn + @efn

-- process all trace files
SELECT ftg.StartTime
    ,te.NAME AS EventName
    ,DB_NAME(ftg.databaseid) AS DatabaseName
    ,ftg.[FileName] AS LogicalFileName
    ,(ftg.IntegerData * 8) / 1024.0 AS GrowthMB
    ,(ftg.duration / 1000) AS DurMS
    ,mf.physical_name AS PhysicalFileName
INTO #autogrowthTotal
FROM::fn_trace_gettable(@filename, DEFAULT) AS ftg
INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id
INNER JOIN sys.master_files mf ON (mf.database_id = ftg.databaseid)
    AND (mf.NAME = ftg.[FileName])
WHERE (
        ftg.EventClass = 92 -- Data File Auto-grow
        OR ftg.EventClass = 93
        ) -- Log File Auto-grow
ORDER BY ftg.StartTime

SELECT count(1) AS NoOfTimesEventFired
    ,CONVERT(VARCHAR(10), StartTime, 120) AS StartTime
    ,EventName
    ,DatabaseName
    ,[LogicalFileName]
    ,PhysicalFileName
    ,SUM(GrowthMB) AS TotalGrowthMB
    ,SUM(DurMS) AS TotalDurationMS
INTO #autogrowthTotal_Final
FROM #autogrowthTotal
GROUP BY CONVERT(VARCHAR(10), StartTime, 120)
    ,EventName
    ,DatabaseName
    ,[LogicalFileName]
    ,PhysicalFileName
--having count(1) > 5 or SUM(DurMS)/1000 > 60 -- change this for finetuning....
ORDER BY CONVERT(VARCHAR(10), StartTime, 120)

SELECT *
FROM #autogrowthTotal_Final