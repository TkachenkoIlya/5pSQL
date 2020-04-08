Declare @dShiftStart as date,
	@dShiftEnd as date

--SELECT * FROM [tmp].[EquipmentQuantity] 
--WHERE IDShift = 7
--	AND IDEquipmentType = 2;

--SELECT * FROM [dbo].[ЛистУправления_ОграниченияТехники]
--WHERE [Дата] = '20191124' AND [Смена] = 1 AND [ИДЗаписи] = 1744 AND [ИДТипаОборудования] = 2;

WITH preData as
(
	SELECT 
		[IDNode]
		,v.[ИДУчастка]
		, u.ИДШахты 
		,[IDPlanIndicator]
		,j.Название 
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
		LEFT JOIN ВидыРабот j on j.ИДВидаРабот = pd.[IDPlanIndicator] 
		INNER JOIN [dbo].[Выработки] v ON v.ИДВыработки = pd.IDNode AND '20191124' between v.[ДатаНачала] AND v.[ДатаОкончания]
		INNER JOIN dbo.Участки u on v.ИДУчастка = u.ИДУчастка 
	--WHERE 
	--	IDPlanIndicator = 31
	--	[IDNode] = 1612
		--AND 
--	ORDER BY [NumRank], [IDNode], [NumCycle],[NumPhase]
)
, SectorRange as
(
	SELECT 
		ИДУчастка 
		, Min(NumRank) SectorNumRank
		--, ROW_NUMBER() OVER (PARTITION BY ИДУчастка ORDER BY NumRank) AS rNum
	FROM 
	preData 
	GROUP BY ИДУчастка
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
		ROW_NUMBER() OVER (PARTITION BY p.ИДШахты ORDER BY sr.rNum,  p.[NumRank], p.[IDNode]) AS NN
		--, eq.Quantity 
		--, 1 as eqQuant
		, '2019-11-24 08:00:00' as dJobStart
		, DATEADD(mi,p.Duration,'20191124 08:00:00') as dJobEnd
		, '2019-11-24 20:00:00' as dShiftEnd
		, p.* 
		, sr.SectorNumRank 
	FROM preData p
		INNER JOIN SectorRangeEnd sr On sr.ИДУчастка = p.ИДУчастка 
		--INNER JOIN [tmp].[EquipmentQuantity]  eq on eq.ИДШахты = p.ИДШахты AND eq.IDShift = 7 AND eq.Quantity > 0 AND eq.IDEquipmentType = 2
	WHERE 
	p.rNum = 1
	AND p.IDPlanIndicator = 31
	AND p.ИДШахты = 2 
)
SELECT
	dr.NN
	, eq.Quantity 
	, CASE WHEN dr.NN <= eq.Quantity THEN 1 ELSE 0 END as 'AsignQuant'
	, dr.dJobStart , dr.dJobEnd , dr.IDNode, dr.ИДУчастка 
	, dr.Duration
	, dr.rNum 
	, dr.SectorNumRank 
FROM DataRanged dr
	INNER JOIN [tmp].[EquipmentQuantity]  eq on eq.ИДШахты = dr.ИДШахты AND eq.IDShift = 7 AND eq.Quantity > 0 AND eq.IDEquipmentType = 2
ORDER BY dr.SectorNumRank,  dr.[NumRank], dr.[IDNode]