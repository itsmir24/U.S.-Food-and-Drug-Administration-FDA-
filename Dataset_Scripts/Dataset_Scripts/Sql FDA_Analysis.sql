use FDA;
select * from appdoc;
select * from appdoctype_lookup;
select * from application;
select * from chemtypelookup;
select * from doctype_lookup;
select * from product;
select * from Product_tecode;
select * from regactiondate;
select * from reviewclass_lookup;

-- Task 1: Identifying Approval Trends
-- 1. Determine the number of drugs approved each year and provide insights into the yearly trends.
SELECT 
    YEAR(ActionDate) AS ApprovalYear, 
    COUNT(*) AS DrugsApproved
FROM 
    RegActionDate
WHERE 
    ActionType = 'AP'  -- assuming 'approved' is the value used for approvals
GROUP BY 
    ApprovalYear
ORDER BY 
    ApprovalYear DESC;
 

-- 2. Identify the top three years that got the highest and lowest approvals, in descending and ascending order, respectively.
   ( SELECT 
        YEAR(ActionDate) AS ApprovalYear, 
        COUNT(*) AS DrugsApproved
    FROM 
        RegActionDate
    WHERE 
        ActionType = 'AP'  -- 'AP' represents approvals
        AND YEAR(ActionDate) IS NOT NULL  -- Exclude NULL years
    GROUP BY 
        ApprovalYear
    ORDER BY 
       DrugsApproved DESC
    LIMIT 3)
UNION 
    (SELECT 
        YEAR(ActionDate) AS ApprovalYear, 
        COUNT(*) AS DrugsApproved
    FROM 
        RegActionDate
    WHERE 
        ActionType = 'AP'
        AND YEAR(ActionDate) IS NOT NULL  -- Exclude NULL years
    GROUP BY 
        ApprovalYear
    ORDER BY 
       DrugsApproved ASC
    LIMIT 3);

-- 3. Explore approval trends over the years based on sponsors.
SELECT YEAR(r.ActionDate) AS approval_year, a.SponsorApplicant, COUNT(*) AS total_approvals
FROM Application a
JOIN RegActionDate r ON a.ApplNo = r.ApplNo
WHERE r.ActionType = 'AP'  -- Assuming "AP" stands for approval
GROUP BY approval_year, SponsorApplicant
ORDER BY approval_year, total_approvals DESC;

-- 4. Rank sponsors based on the total number of approvals they received each year between 1939 and 1960.
SELECT 
	YEAR(r.ActionDate) AS ActionYear, 
    a.SponsorApplicant, 
    COUNT(a.ActionType) AS TotalApprovals, 
    RANK() OVER (PARTITION BY YEAR(r.ActionDate) ORDER BY COUNT(a.ActionType) DESC) AS SponsorRank 
FROM  Application a
INNER JOIN regactiondate r
ON a.ApplNo=r.ApplNo
WHERE a.ActionType="AP" AND r.ActionDate AND YEAR(r.ActionDate) BETWEEN 1939 AND 1960
GROUP BY 
    ActionYear, 
    a.SponsorApplicant
ORDER BY 
    ActionYear, 
    SponsorRank;
-- Task 2: Segmentation Analysis Based on Drug MarketingStatus
-- 1. Group products based on MarketingStatus. Provide meaningful insights into the segmentation patterns.
SELECT 
    CASE ProductMktStatus
        WHEN 1 THEN 'Marketed'
        WHEN 2 THEN 'Withdrawn'
        WHEN 3 THEN 'Pending'
        WHEN 4 THEN 'Pre-Market'
        ELSE 'Unknown'
    END AS Status,
    COUNT(*) AS total_products
FROM Product
GROUP BY ProductMktStatus
ORDER BY total_products DESC;

-- 2. Calculate the total number of applications for each MarketingStatus year-wise after the year 2010. 
SELECT YEAR(r.ActionDate) AS approval_year, p.ProductMktStatus, COUNT(DISTINCT p.ApplNo) AS total_applications
FROM Product p
JOIN RegActionDate r ON p.ApplNo = r.ApplNo
WHERE YEAR(r.ActionDate) > 2010
GROUP BY approval_year, p.ProductMktStatus
ORDER BY approval_year, p.ProductMktStatus ;

-- 3. Identify the top MarketingStatus with the maximum number of applications and analyze its trend over time. 

WITH TopProductMktStatus AS
 ( 	SELECT p.ProductMktStatus, COUNT(DISTINCT p.ApplNo) AS total_applications
	FROM Product p
	JOIN RegActionDate r ON p.ApplNo = r.ApplNo
	WHERE YEAR(r.ActionDate) > 2010
	GROUP BY p.ProductMktStatus
	ORDER BY total_applications DESC
	LIMIT 1)
-- Analyze the trend over time for the top ProductMktStatus
SELECT YEAR(r.ActionDate) AS approval_year, COUNT(DISTINCT p.ApplNo) AS total_applications
FROM Product p
JOIN RegActionDate r ON p.ApplNo = r.ApplNo
WHERE YEAR(r.ActionDate) > 2010
AND p.ProductMktStatus = (SELECT ProductMktStatus FROM TopProductMktStatus) -- Replace with actual top ProductMktStatus
GROUP BY YEAR(r.ActionDate)
ORDER BY approval_year ASC;
-- Task 3: Analyzing Products
-- 1. Categorize Products by dosage form and analyze their distribution.
select * from product;
SELECT Form AS dosage_form, COUNT(*) AS total_products
FROM Product
GROUP BY Form
ORDER BY total_products DESC;

-- 2. Calculate the total number of approvals for each dosage form and identify the most successful forms.
SELECT p.Form AS dosage_form, COUNT(*) AS total_approvals
FROM Product p
JOIN RegActionDate r ON p.ApplNo = r.ApplNo
WHERE r.ActionType = 'AP'  -- Assuming "AP" indicates approval
GROUP BY p.Form
ORDER BY total_approvals DESC;

-- 3. Investigate yearly trends related to successful forms. 
SELECT YEAR(r.ActionDate) AS approval_year, p.Form AS dosage_form, COUNT(*) AS total_approvals
FROM Product p
JOIN RegActionDate r ON p.ApplNo = r.ApplNo
WHERE r.ActionType = 'AP'
GROUP BY approval_year, p.Form
ORDER BY approval_year, total_approvals DESC;

-- Task 4: Exploring Therapeutic Classes and Approval Trends
-- 1. Analyze drug approvals based on the therapeutic evaluation code (TE_Code).
SELECT TECode, COUNT(*) AS total_approvals
FROM Product
JOIN RegActionDate r ON Product.ApplNo = r.ApplNo
WHERE r.ActionType = 'AP'
GROUP BY TECode
ORDER BY total_approvals DESC;

-- 2. Determine the therapeutic evaluation code (TE_Code) with the highest number of Approvals in each year.
WITH ApprovalsByYearAndTECode AS (
    -- CTE 1: total approvals for each year and TECode
    SELECT YEAR(r.ActionDate) AS approval_year, p.TECode, COUNT(*) AS total_approvals
    FROM Product p
    JOIN RegActionDate r ON p.ApplNo = r.ApplNo
    WHERE r.ActionType = 'AP' 
      AND p.TECode IS NOT NULL  -- Filter out NULL TECode values
    GROUP BY YEAR(r.ActionDate), p.TECode
),
MaxApprovalsByYear AS (
    -- CTE 2: maximum number of approvals for each year
    SELECT approval_year, MAX(total_approvals) AS max_approvals
    FROM ApprovalsByYearAndTECode
    GROUP BY approval_year
)

-- Join the CTEs to get the TECode with the maximum approvals for each year
SELECT a.approval_year, a.TECode, a.total_approvals AS max_approvals
FROM ApprovalsByYearAndTECode a
JOIN MaxApprovalsByYear m
ON a.approval_year = m.approval_year
AND a.total_approvals = m.max_approvals
ORDER BY max_approvals desc;

-- End of Analysis 
