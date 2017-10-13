sp_lock 


SELECT resource_associated_entity_id,*
FROM sys.dm_tran_locks
WHERE resource_type = 'KEY'
ORDER BY request_mode



SELECT *
FROM sys.partitions
WHERE partition_id in (72057594359054336, 72057594359054336)




SELECT OBJECT_NAME(part.object_id),* FROM sys.partitions part 
	INNER JOIN sys.dm_tran_locks locks ON locks.resource_associated_entity_id =  part.partition_id









	 SELECT
	 d.name AS database_name,
        sess.session_id,
        sess.host_name,
        sess.login_time,
        sess.login_name,
        sess.reads,
        sess.writes
     , L.resource_type
     ,L.resource_description
     ,L.resource_associated_entity_id
     ,L.request_mode
     ,L.request_type
     ,L.request_status
     ,OBJECT_NAME(I.object_id) AS TableName
     ,I.object_id
     ,I.index_id
     ,I.name AS IndexName
     ,I.type_desc--,*
 FROM sys.dm_tran_locks L
 INNER JOIN sys.partitions P ON P.partition_id = L.resource_associated_entity_id
 INNER JOIN sys.indexes I ON I.object_id = P.object_id AND I.index_id = P.index_id
 LEFT OUTER JOIN sys.dm_exec_sessions sess ON sess.session_id = L.request_session_id
 INNER JOIN sys.databases d ON l.resource_database_id = d.database_id
 WHERE L.resource_type = 'KEY' AND OBJECT_NAME(I.object_id) IN ('DCOBJECT','FSM_STATE')
 ORDER BY L.request_mode



 SELECT
 sys.fn_PhysLocFormatter(OBJ.%%physloc%%) AS FilePageSlot, OBJ.%%lockres%% AS LockResource,*
FROM DCOBJECT AS OBJ
    INNER JOIN FSM_STATE OBJFSMST
        ON OBJFSMST.FSM_ST_ID = OBJ.OB_FSM_ST_ID
WHERE
(
    OBJ.OB_DELDATE IS NULL
    AND OBJ.OB_DELUSER IS NULL
    AND OBJ.OB_OT_CODE = 'DocumentTypeProperties'
)
ORDER BY OBJ.OB_ID ASC 

SELECT DB_ID('IrisNext')


DBCC TRACEON (3604);
DBCC PAGE (8, 1, 100149,0); -- DB_ID, FileId, PageId, Format


 SELECT sys.fn_PhysLocFormatter(%%physloc%%) AS FilePageSlot, %%lockres%% AS LockResource, *
FROM DCOBJECT
WHERE LastName BETWEEN 'Ware' AND 'Warthen'


SELECT OBJECT_NAME(123251594)


SELECT  %%LOCKRES%%,* 
FROM   NIMT.EventLabels
--ORDER BY %%LOCKRES%% 
WHERE   %%LOCKRES%%  = '(954817eee8c1)'                  
    
DBCC IND (IrisNext, 'NIMT.EventLabels', 4);
DBCC PAGE (AsfApp,1,22708,3)   WITH TABLERESULTS 



108	8	1623012863	10	KEY	(d2dcb093bc1d)                  	X	GRANT
108	8	123251594	5	KEY	(954817eee8c1)                  	X	GRANT
108	8	187251822	3	KEY	(f1d7a53a43d6)                  	X	GRANT
108	8	123251594	4	KEY	(94ed23cb3d84)                  	X	GRANT
108	8	1623012863	8	KEY	(7c938f91cff2)                  	X	GRANT
108	8	1623012863	5	PAG	1:36161102                      	IX	GRANT
108	8	1448444284	20	KEY	(ce020587f1f5)                  	X	GRANT
108	8	179531723	4	KEY	(764ac1df748d)                  	X	GRANT
108	8	2007014231	4	KEY	(274cb1a7791b)                  	X	GRANT
108	8	123251594	5	KEY	(8ab37aead3c4)                  	X	GRANT
108	8	1751013319	0	TAB	                                	IX	GRANT
108	8	1730209314	0	TAB	                                	IX	GRANT
108	8	1623012863	2	KEY	(ec237c6006f9)                  	X	GRANT