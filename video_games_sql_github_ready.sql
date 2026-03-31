/*
===============================================================================
Project: Video Games Sales Analysis
Author : Natan Mamedov
Tools  : SQL Server / T-SQL
Table  : dbo.video_games
Database: Video_Games
===============================================================================

PROJECT OVERVIEW
This project analyzes a video games dataset in order to answer business-style
questions about platform distribution, genre peak performance, critic scores,
data scaffolding, and year-over-year sales growth.

SKILLS DEMONSTRATED
- Data cleaning and validation
- Common Table Expressions (CTEs)
- Window functions
- Aggregations and statistical measures
- Data scaffolding for missing combinations
- Year-over-year growth analysis

ASSUMPTIONS
- A unique game is defined as: Name + Year_of_Release
- Blank strings are treated as missing values
- Ties are preserved where relevant
- Year 2020 is excluded from EX_5 according to assignment requirements

NOTES
- This script is organized for readability and GitHub presentation.
- Each section includes a short business objective and query logic.
===============================================================================
*/

USE Video_Games;
GO

/*
===============================================================================
EX_2A
Business question:
How many games were released on 3 or more distinct platforms?

Business value:
This helps identify titles with broad platform reach, which may indicate higher
commercial potential or publisher investment.
===============================================================================
*/
;WITH CleanGames AS
(
    SELECT
        LTRIM(RTRIM(vg.[Name])) AS [Name],
        vg.[Year_of_Release],
        LTRIM(RTRIM(vg.[Platform])) AS [Platform]
    FROM dbo.video_games AS vg
    WHERE vg.[Name] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Name])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
      AND vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
),
GamePlatforms AS
(
    SELECT
        cg.[Name],
        cg.[Year_of_Release],
        COUNT(DISTINCT cg.[Platform]) AS PlatformCount
    FROM CleanGames AS cg
    GROUP BY
        cg.[Name],
        cg.[Year_of_Release]
)
SELECT
    gp.[Name],
    gp.[Year_of_Release],
    gp.PlatformCount
FROM GamePlatforms AS gp
WHERE gp.PlatformCount >= 3
ORDER BY
    gp.PlatformCount DESC,
    gp.[Year_of_Release],
    gp.[Name];
GO

;WITH CleanGames AS
(
    SELECT
        LTRIM(RTRIM(vg.[Name])) AS [Name],
        vg.[Year_of_Release],
        LTRIM(RTRIM(vg.[Platform])) AS [Platform]
    FROM dbo.video_games AS vg
    WHERE vg.[Name] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Name])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
      AND vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
),
GamePlatforms AS
(
    SELECT
        cg.[Name],
        cg.[Year_of_Release],
        COUNT(DISTINCT cg.[Platform]) AS PlatformCount
    FROM CleanGames AS cg
    GROUP BY
        cg.[Name],
        cg.[Year_of_Release]
)
SELECT
    COUNT(*) AS Games_With_3_Or_More_Platforms
FROM GamePlatforms
WHERE PlatformCount >= 3;
GO

/*
===============================================================================
EX_2B
Business question:
In which year did the highest number of genres reach their sales peak?

Business value:
This shows whether there was a particularly strong year for the gaming market
across multiple categories at once.

Definition:
For each genre, the peak year is the year with the highest total Global_Sales.
Ties are kept.
===============================================================================
*/
;WITH GenreYearSales AS
(
    SELECT
        LTRIM(RTRIM(vg.[Genre])) AS [Genre],
        vg.[Year_of_Release],
        SUM(vg.[Global_Sales]) AS Total_Global_Sales
    FROM dbo.video_games AS vg
    WHERE vg.[Genre] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Genre])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
    GROUP BY
        LTRIM(RTRIM(vg.[Genre])),
        vg.[Year_of_Release]
),
GenrePeak AS
(
    SELECT
        gys.[Genre],
        gys.[Year_of_Release],
        gys.Total_Global_Sales,
        MAX(gys.Total_Global_Sales) OVER (PARTITION BY gys.[Genre]) AS Max_Genre_Sales
    FROM GenreYearSales AS gys
),
PeakYears AS
(
    SELECT
        gp.[Genre],
        gp.[Year_of_Release]
    FROM GenrePeak AS gp
    WHERE gp.Total_Global_Sales = gp.Max_Genre_Sales
),
YearPeakCount AS
(
    SELECT
        py.[Year_of_Release],
        COUNT(DISTINCT py.[Genre]) AS Genres_At_Peak
    FROM PeakYears AS py
    GROUP BY py.[Year_of_Release]
),
BestYear AS
(
    SELECT TOP (1) WITH TIES
        ypc.[Year_of_Release],
        ypc.Genres_At_Peak
    FROM YearPeakCount AS ypc
    ORDER BY ypc.Genres_At_Peak DESC
)
SELECT
    byear.[Year_of_Release],
    byear.Genres_At_Peak,
    py.[Genre]
FROM BestYear AS byear
JOIN PeakYears AS py
    ON py.[Year_of_Release] = byear.[Year_of_Release]
ORDER BY
    byear.[Year_of_Release],
    py.[Genre];
GO

/*
===============================================================================
EX_3
Business question:
What are the weighted average, simple average, and mode of Critic_Score by Rating?

Business value:
This compares critic evaluation patterns across content ratings and demonstrates
how weighting by critic count can change the interpretation.

Technical note:
The weighted average is based on Critic_Count.
This version calculates averages and mode in separate steps to avoid duplicate
rows affecting the result.
===============================================================================
*/
;WITH Cleaned AS
(
    SELECT
        NULLIF(LTRIM(RTRIM(vg.[Rating])), '') AS Rating,
        TRY_CONVERT(DECIMAL(10,2), vg.[Critic_Score]) AS Critic_Score,
        TRY_CONVERT(DECIMAL(10,2), vg.[Critic_Count]) AS Critic_Count
    FROM dbo.video_games AS vg
),
Base AS
(
    SELECT
        c.[Rating],
        c.Critic_Score,
        c.Critic_Count
    FROM Cleaned AS c
    WHERE c.[Rating] IS NOT NULL
      AND c.Critic_Score IS NOT NULL
),
Aggregates AS
(
    SELECT
        b.[Rating],
        ROUND(AVG(b.Critic_Score), 1) AS Normal_Average,
        ROUND(
            SUM(b.Critic_Score * CASE WHEN b.Critic_Count > 0 THEN b.Critic_Count ELSE 0 END)
            / NULLIF(SUM(CASE WHEN b.Critic_Count > 0 THEN b.Critic_Count ELSE 0 END), 0),
            1
        ) AS Weighted_Average
    FROM Base AS b
    GROUP BY b.[Rating]
),
ModeFrequency AS
(
    SELECT
        b.[Rating],
        b.Critic_Score,
        COUNT(*) AS Score_Frequency
    FROM Base AS b
    GROUP BY
        b.[Rating],
        b.Critic_Score
),
ModeRank AS
(
    SELECT
        mf.[Rating],
        mf.Critic_Score,
        mf.Score_Frequency,
        ROW_NUMBER() OVER
        (
            PARTITION BY mf.[Rating]
            ORDER BY mf.Score_Frequency DESC, mf.Critic_Score ASC
        ) AS rn
    FROM ModeFrequency AS mf
)
SELECT
    a.[Rating],
    a.Weighted_Average,
    a.Normal_Average,
    ROUND(mr.Critic_Score, 1) AS Mode_Critic_Score
FROM Aggregates AS a
LEFT JOIN ModeRank AS mr
    ON mr.[Rating] = a.[Rating]
   AND mr.rn = 1
ORDER BY
    a.[Rating];
GO

/*
Optional helper for EX_3:
Find rating groups that ended with exactly the same weighted average,
simple average, and mode.
*/
;WITH Cleaned AS
(
    SELECT
        NULLIF(LTRIM(RTRIM(vg.[Rating])), '') AS Rating,
        TRY_CONVERT(DECIMAL(10,2), vg.[Critic_Score]) AS Critic_Score,
        TRY_CONVERT(DECIMAL(10,2), vg.[Critic_Count]) AS Critic_Count
    FROM dbo.video_games AS vg
),
Base AS
(
    SELECT
        c.[Rating],
        c.Critic_Score,
        c.Critic_Count
    FROM Cleaned AS c
    WHERE c.[Rating] IS NOT NULL
      AND c.Critic_Score IS NOT NULL
),
Aggregates AS
(
    SELECT
        b.[Rating],
        ROUND(AVG(b.Critic_Score), 1) AS Normal_Average,
        ROUND(
            SUM(b.Critic_Score * CASE WHEN b.Critic_Count > 0 THEN b.Critic_Count ELSE 0 END)
            / NULLIF(SUM(CASE WHEN b.Critic_Count > 0 THEN b.Critic_Count ELSE 0 END), 0),
            1
        ) AS Weighted_Average
    FROM Base AS b
    GROUP BY b.[Rating]
),
ModeFrequency AS
(
    SELECT
        b.[Rating],
        b.Critic_Score,
        COUNT(*) AS Score_Frequency
    FROM Base AS b
    GROUP BY
        b.[Rating],
        b.Critic_Score
),
ModeRank AS
(
    SELECT
        mf.[Rating],
        mf.Critic_Score,
        mf.Score_Frequency,
        ROW_NUMBER() OVER
        (
            PARTITION BY mf.[Rating]
            ORDER BY mf.Score_Frequency DESC, mf.Critic_Score ASC
        ) AS rn
    FROM ModeFrequency AS mf
),
Measures AS
(
    SELECT
        a.[Rating],
        a.Weighted_Average,
        a.Normal_Average,
        ROUND(mr.Critic_Score, 1) AS Mode_Critic_Score
    FROM Aggregates AS a
    LEFT JOIN ModeRank AS mr
        ON mr.[Rating] = a.[Rating]
       AND mr.rn = 1
)
SELECT
    m1.[Rating] AS Rating_1,
    m2.[Rating] AS Rating_2,
    m1.Weighted_Average,
    m1.Normal_Average,
    m1.Mode_Critic_Score
FROM Measures AS m1
JOIN Measures AS m2
    ON m1.[Rating] < m2.[Rating]
   AND m1.Weighted_Average = m2.Weighted_Average
   AND m1.Normal_Average = m2.Normal_Average
   AND m1.Mode_Critic_Score = m2.Mode_Critic_Score
ORDER BY
    Rating_1,
    Rating_2;
GO

/*
===============================================================================
EX_4
Business question:
Return Global_Sales by Genre, Platform, and Year_of_Release for every possible
combination, including combinations that do not exist in the original data.
Missing values should appear as 0.

Business value:
This scaffolding technique is useful for complete reporting, trend analysis,
and visualization tools that need continuous dimensions.
===============================================================================
*/
;WITH YearBounds AS
(
    SELECT
        MIN(vg.[Year_of_Release]) AS MinYear,
        MAX(vg.[Year_of_Release]) AS MaxYear
    FROM dbo.video_games AS vg
    WHERE vg.[Year_of_Release] IS NOT NULL
),
Years AS
(
    SELECT yb.MinYear AS Year_of_Release
    FROM YearBounds AS yb

    UNION ALL

    SELECT y.[Year_of_Release] + 1
    FROM Years AS y
    CROSS JOIN YearBounds AS yb
    WHERE y.[Year_of_Release] < yb.MaxYear
),
Genres AS
(
    SELECT DISTINCT
        LTRIM(RTRIM(vg.[Genre])) AS [Genre]
    FROM dbo.video_games AS vg
    WHERE vg.[Genre] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Genre])) <> ''
),
Platforms AS
(
    SELECT DISTINCT
        LTRIM(RTRIM(vg.[Platform])) AS [Platform]
    FROM dbo.video_games AS vg
    WHERE vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
),
Scaffold AS
(
    SELECT
        g.[Genre],
        p.[Platform],
        y.[Year_of_Release]
    FROM Genres AS g
    CROSS JOIN Platforms AS p
    CROSS JOIN Years AS y
),
Sales AS
(
    SELECT
        LTRIM(RTRIM(vg.[Genre])) AS [Genre],
        LTRIM(RTRIM(vg.[Platform])) AS [Platform],
        vg.[Year_of_Release],
        SUM(vg.[Global_Sales]) AS Total_Global_Sales
    FROM dbo.video_games AS vg
    WHERE vg.[Genre] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Genre])) <> ''
      AND vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
    GROUP BY
        LTRIM(RTRIM(vg.[Genre])),
        LTRIM(RTRIM(vg.[Platform])),
        vg.[Year_of_Release]
)
SELECT
    s.[Genre],
    s.[Platform],
    s.[Year_of_Release],
    ISNULL(sa.Total_Global_Sales, 0) AS Global_Sales
FROM Scaffold AS s
LEFT JOIN Sales AS sa
    ON sa.[Genre] = s.[Genre]
   AND sa.[Platform] = s.[Platform]
   AND sa.[Year_of_Release] = s.[Year_of_Release]
ORDER BY
    s.[Genre],
    s.[Platform],
    s.[Year_of_Release]
OPTION (MAXRECURSION 0);
GO

/*
===============================================================================
EX_5
Business question:
Which platform and year had the highest year-over-year growth in Global_Sales?

Requirements:
- Exclude 2020
- Create a full year range per platform
- Start calculations from the second year only

Business value:
This identifies the strongest expansion point for each platform lifecycle and
shows how to handle missing years before calculating growth.
===============================================================================
*/
;WITH PlatformBounds AS
(
    SELECT
        LTRIM(RTRIM(vg.[Platform])) AS [Platform],
        MIN(vg.[Year_of_Release]) AS MinYear,
        MAX(vg.[Year_of_Release]) AS MaxYear
    FROM dbo.video_games AS vg
    WHERE vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
      AND vg.[Year_of_Release] <> 2020
    GROUP BY
        LTRIM(RTRIM(vg.[Platform]))
),
PlatformYears AS
(
    SELECT
        pb.[Platform],
        pb.MinYear AS Year_of_Release,
        pb.MaxYear
    FROM PlatformBounds AS pb

    UNION ALL

    SELECT
        py.[Platform],
        py.[Year_of_Release] + 1,
        py.MaxYear
    FROM PlatformYears AS py
    WHERE py.[Year_of_Release] < py.MaxYear
),
Sales AS
(
    SELECT
        LTRIM(RTRIM(vg.[Platform])) AS [Platform],
        vg.[Year_of_Release],
        SUM(vg.[Global_Sales]) AS Total_Global_Sales
    FROM dbo.video_games AS vg
    WHERE vg.[Platform] IS NOT NULL
      AND LTRIM(RTRIM(vg.[Platform])) <> ''
      AND vg.[Year_of_Release] IS NOT NULL
      AND vg.[Year_of_Release] <> 2020
    GROUP BY
        LTRIM(RTRIM(vg.[Platform])),
        vg.[Year_of_Release]
),
ScaffoldSales AS
(
    SELECT
        py.[Platform],
        py.[Year_of_Release],
        ISNULL(s.Total_Global_Sales, 0) AS Global_Sales
    FROM PlatformYears AS py
    LEFT JOIN Sales AS s
        ON s.[Platform] = py.[Platform]
       AND s.[Year_of_Release] = py.[Year_of_Release]
),
YoYCalc AS
(
    SELECT
        ss.[Platform],
        ss.[Year_of_Release],
        ss.Global_Sales,
        LAG(ss.Global_Sales) OVER
        (
            PARTITION BY ss.[Platform]
            ORDER BY ss.[Year_of_Release]
        ) AS Prev_Year_Sales
    FROM ScaffoldSales AS ss
),
YoY AS
(
    SELECT
        yc.[Platform],
        yc.[Year_of_Release],
        yc.Global_Sales,
        yc.Prev_Year_Sales,
        CAST(
            (yc.Global_Sales - yc.Prev_Year_Sales) * 1.0
            / NULLIF(yc.Prev_Year_Sales, 0)
            AS DECIMAL(18,4)
        ) AS YoY_Growth
    FROM YoYCalc AS yc
    WHERE yc.Prev_Year_Sales IS NOT NULL
)
SELECT TOP (1) WITH TIES
    y.[Platform],
    y.[Year_of_Release],
    y.Prev_Year_Sales,
    y.Global_Sales,
    y.YoY_Growth
FROM YoY AS y
WHERE y.YoY_Growth IS NOT NULL
ORDER BY
    y.YoY_Growth DESC
OPTION (MAXRECURSION 0);
GO
