#Going through the data to start. Nearly 15 years' worth of prices for the most commonly used types of fuel in Portugal.

	SELECT *
FROM diesel 
ORDER BY date
LIMIT 20;

	SELECT *
FROM gasoline 
ORDER BY date 
LIMIT 20;

#It seems there are two columns for both diesel and gasoline 95. One of them only goes until September 2021, but before than there is a period when both columns have different values, as they're taken from different gas stations. 
#Let's merge the columns and find the average price when both columns have different values.

ALTER TABLE diesel
ADD avg_diesel text;

UPDATE diesel
SET avg_diesel = CASE
    WHEN diesel_uptosep2021 != '' AND regular_diesel != '' THEN (diesel_uptosep2021 + regular_diesel) / 2
    WHEN diesel_uptosep2021 != '' THEN diesel_uptosep2021
    ELSE regular_diesel
    END;

ALTER TABLE gasoline
ADD avg_gasoline95 text;

UPDATE gasoline
SET avg_gasoline95 = CASE
    WHEN gasoline95_uptosep2021 != '' AND gasoline95 != '' THEN (gasoline95_uptosep2021 + gasoline95) / 2
    WHEN gasoline95_uptosep2021 != '' THEN gasoline95_uptosep2021
    ELSE gasoline95
    END;

#All done. Now it seems there are no prices for the interval between September 4th and 22nd, 2015, for some reason.
#Deleting those rows.

DELETE FROM diesel
WHERE date BETWEEN '2015-09-04' AND '2015-09-22';

#Let's have a look at some basic measures across the different kinds of fuel in the past ten years.
#Checking minimum, maximum and average prices.

	SELECT  
		ROUND(MIN(d.avg_diesel), 4) AS lowest_diesel_price,
		MAX(d.avg_diesel) AS highest_diesel_price,
        ROUND(AVG(d.avg_diesel), 4) AS average_diesel_price,
        MIN(g.avg_gasoline95) AS lowest_gasoline95_price,
		MAX(g.avg_gasoline95) AS highest_gasoline95_price,
        ROUND(AVG(g.avg_gasoline95), 4) AS average_gasoline95_price,
		MIN(g.gasoline98) AS lowest_gasoline98_price,
		MAX(g.gasoline98) AS highest_gasoline98_price,
        ROUND(AVG(g.gasoline98), 4) AS average_gasoline98_price
FROM diesel as d
JOIN gasoline as g
ON d.date = g.date
WHERE d.date BETWEEN '2013-08-22' AND '2023-08-22';

#I tend to fill up my tank weekly. Having a look at weekly rolling averages.

	SELECT  
		d.date,
		d.avg_diesel,
		ROUND(AVG(avg_diesel) OVER (
        ORDER BY date
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING), 4) AS diesel_moving_average_7_days,
        g.avg_gasoline95,
		ROUND(AVG(g.avg_gasoline95) OVER (
        ORDER BY date
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING), 4) AS gasoline95_moving_average_7_days,
        g.gasoline98,
        ROUND(AVG(g.gasoline98) OVER (
        ORDER BY date
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING), 4) AS gasoline98_moving_average_7_days
FROM diesel AS d
JOIN gasoline AS g
ON d.date = g.date 
ORDER BY 1;

#Unsurprisingly, diesel has had the lowest average price overall. 
#I've been driving a diesel car in the past ten years, so let's focus on that type of fuel now. Again, here's the average.

	SELECT 
		ROUND(AVG(avg_diesel), 4) AS diesel_avg_10years
FROM diesel
WHERE date BETWEEN '2013-08-22' AND '2023-08-22';

#And now the highest price.

	SELECT
		date,
		avg_diesel AS max_avg_diesel
FROM diesel
WHERE  avg_diesel = (SELECT MAX(avg_diesel) FROM diesel) AND date BETWEEN '2013-08-22' AND '2023-08-22';

#I hope I didn't fill up my tank on the 23rd of June last year. Not a good day.
#I wonder if June 2022 was the most expensive month for diesel since 2013?

	SELECT	
		MONTHNAME(date) AS month, 
		YEAR(date) AS year, 
		ROUND(AVG(avg_diesel), 4) AS average_diesel_price
FROM diesel
WHERE date BETWEEN '2013-01-01' AND '2023-08-22'
GROUP BY 2, 1
ORDER BY 3 DESC
LIMIT 20;

#It was indeed. 2022 was probably the most expensive year as well. Let's rank the decade.

	SELECT  
		RANK() OVER (ORDER BY AVG(avg_diesel) DESC) AS ranking,
		YEAR(date) AS year, 
		ROUND(AVG(avg_diesel), 4) AS average_diesel_price
FROM diesel
WHERE date BETWEEN '2013-01-01' AND '2023-08-22'
GROUP BY 2
ORDER BY 3 DESC;

#2022 was bad, and 2023 is slowly closing in. 
#Let's label prices as "high" and "low" and then counting number of days in 2023 when diesel has been cheaper than 1.5€:

WITH Categories AS (
    SELECT
		date,
        avg_diesel,
        CASE WHEN avg_diesel < 1.50 THEN 'Low' ELSE 'High' END AS price_category
    FROM diesel
)
	SELECT 
		COUNT(*)
FROM Categories
WHERE price_category = "Low" AND date BETWEEN '2023-01-01' AND '2023-08-22';

#Only 90 days. Three out of eight months so far.
#To finish on a positive not, let's consider my vacation.
#I went on a driving vacation from July 28th to August 3rd this year, driving around 2000km in a week. My car does 100km with around 5l of diesel, so that week took around 100l.
#If I'd done it ten years ago, how much money would I have saved?

WITH ThisYear AS (
    SELECT
        ROUND((AVG(avg_diesel) * 100), 2) AS this_year_average
    FROM diesel
    WHERE date >= '2023-07-28' AND date <= '2023-08-03'
),
TenYearsAgo AS (
   SELECT
        ROUND((AVG(avg_diesel) * 100), 2) AS ten_years_ago_average
    FROM diesel
    WHERE date >= '2013-07-28' AND date <= '2013-08-03'
)
	SELECT
		ThisYear.this_year_average AS this_year_average,
		TenYearsAgo.ten_years_ago_average AS ten_years_ago_average,
		ROUND((ThisYear.this_year_average - TenYearsAgo.ten_years_ago_average), 2) AS difference
FROM ThisYear
JOIN TenYearsAgo ON 1=1;

#More than 20€. I'd better start cycling.