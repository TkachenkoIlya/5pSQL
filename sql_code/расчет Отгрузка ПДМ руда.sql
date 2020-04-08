Declare @dShiftStart as date,
	@dShiftEnd as date

--SELECT * FROM [tmp].[EquipmentQuantity] 
--WHERE IDShift = 7
--	AND IDEquipmentType = 2;

--SELECT * FROM [dbo].[��������������_������������������]
--WHERE [����] = '20191124' AND [�����] = 1 AND [��������] = 1744 AND [������������������] = 2;

WITH preData as
(
	SELECT 
		[IDNode]
		,v.[���������]
		, u.������� 
		,[IDPlanIndicator]
		,j.�������� 
		,[NumRank]
		,[IDEquipment]
		,[IDEquipmentType]
		,[DateStart]
		,[DateEnd]
		,[Duration]
		,[WorkloadValue]
		,[NumShift]
		,[IDShift]
		,[NumCycle]
		,[NumPhase]
		, ROW_NUMBER() OVER (PARTITION BY [IDNode] ORDER BY [NumCycle],[NumPhase]) AS rNum
		
	FROM [tmp].[PrePlanData] pd
		LEFT JOIN ��������� j on j.����������� = pd.[IDPlanIndicator] 
		INNER JOIN [dbo].[���������] v ON v.����������� = pd.IDNode AND '20191124' between v.[����������] AND v.[�������������]
		INNER JOIN dbo.������� u on v.��������� = u.��������� 
	--WHERE 
	--	IDPlanIndicator = 31
	--	[IDNode] = 1612
		--AND 
--	ORDER BY [NumRank], [IDNode], [NumCycle],[NumPhase]
)
, SectorRange as
(
	SELECT 
		��������� 
		, Min(NumRank) SectorNumRank
		--, ROW_NUMBER() OVER (PARTITION BY ��������� ORDER BY NumRank) AS rNum
	FROM 
	preData 
	GROUP BY ���������
)
, SectorRangeEnd as
(
	SELECT 
	* 
	, ROW_NUMBER() OVER (ORDER BY SectorNumRank) AS rNum
	FROM SectorRange
)
, DataRanged as 
(
	SELECT
		ROW_NUMBER() OVER (PARTITION BY p.������� ORDER BY sr.rNum,  p.[NumRank], p.[IDNode]) AS NN
		--, eq.Quantity 
		--, 1 as eqQuant
		, '2019-11-24 08:00:00' as dJobStart
		, DATEADD(mi,p.Duration,'20191124 08:00:00') as dJobEnd
		, '2019-11-24 20:00:00' as dShiftEnd
		, p.* 
		, sr.SectorNumRank 
	FROM preData p
		INNER JOIN SectorRangeEnd sr On sr.��������� = p.��������� 
		--INNER JOIN [tmp].[EquipmentQuantity]  eq on eq.������� = p.������� AND eq.IDShift = 7 AND eq.Quantity > 0 AND eq.IDEquipmentType = 2
	WHERE 
	p.rNum = 1
	AND p.IDPlanIndicator = 31
	AND p.������� = 2 
)
SELECT
	dr.NN
	, eq.Quantity 
	, CASE WHEN dr.NN <= eq.Quantity THEN 1 ELSE 0 END as 'AsignQuant'
	, dr.dJobStart , dr.dJobEnd , dr.IDNode, dr.��������� 
	, dr.Duration
	, dr.rNum 
	, dr.SectorNumRank 
FROM DataRanged dr
	INNER JOIN [tmp].[EquipmentQuantity]  eq on eq.������� = dr.������� AND eq.IDShift = 7 AND eq.Quantity > 0 AND eq.IDEquipmentType = 2
ORDER BY dr.SectorNumRank,  dr.[NumRank], dr.[IDNode]