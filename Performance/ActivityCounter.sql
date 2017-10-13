











SELECT d,SUM(N) 
FROM 

(
SELECT CAST ( [RequestReceivedDate] AS DATE) AS d,COUNT(*) N FROM [CRS].[Demand]
GROUP BY CAST ( [RequestReceivedDate] AS DATE)
--ORDER BY d desc

UNION ALL 

SELECT CAST ( [RequestReceivedDate] AS DATE) AS d ,COUNT(*) N FROM [CRS].[SearchRequest]
GROUP BY CAST ( [RequestReceivedDate] AS DATE) 
--ORDER BY d desc
)   AS A
GROUP BY d
ORDER BY d desc
