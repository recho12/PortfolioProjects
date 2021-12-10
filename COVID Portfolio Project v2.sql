--=============================================================--
/*
SELECT
	cd.continent,
	SUM(cd.total_cases) AS Total_cases,
	SUM(CAST(cd.total_deaths AS float)) AS Total_deaths,
	cv.date
FROM PortfolioProject..CovidDeaths AS cd
INNER JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.iso_code = cv.iso_code
WHERE total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
GROUP BY cd.continent, cv.date
ORDER BY total_deaths DESC
;
*/
--=================================================================--
/*
SELECT 
	iso_code,
	CASE 
		WHEN [date] BETWEEN '2021-12-01 00:00:00.000' AND '2021-12-08 00:00:00.000'
		THEN 'December'
		WHEN [date] BETWEEN '2021-11-01 00:00:00.000' AND '2021-11-30 00:00:00.000'
		THEN 'November'
		WHEN [date] BETWEEN '2021-10-01 00:00:00.000' AND '2021-10-31 00:00:00.000'
		THEN 'October'
		WHEN [date] BETWEEN '2021-09-01 00:00:00.000' AND '2021-09-30 00:00:00.000'
		THEN 'September'
	ELSE 'Invalid'
END AS Months
INTO Monthly
FROM PortfolioProject..CovidVaccinations
;
*/
--===================================================================--
/*
SELECT
	iso_code,
	Months
FROM Monthly
WHERE Months IN('December','November','October','September')
GROUP BY Months, iso_code
;
*/
--==========================================================================---
/*WITH AggregatedTable AS (
	SELECT
		CASE 
		WHEN cv.[date] BETWEEN '2021-12-01 00:00:00.000' AND '2021-12-08 00:00:00.000'
		THEN 'December'
		WHEN cv.[date] BETWEEN '2021-11-01 00:00:00.000' AND '2021-11-30 00:00:00.000'
		THEN 'November'
		WHEN cv.[date] BETWEEN '2021-10-01 00:00:00.000' AND '2021-10-31 00:00:00.000'
		THEN 'October'
		WHEN cv.[date] BETWEEN '2021-09-01 00:00:00.000' AND '2021-09-30 00:00:00.000'
		THEN 'September'
	ELSE 'Invalid'
END AS Months,
	cd.continent AS Continent,
	SUM(CAST(cd.new_cases AS bigint)) AS New_cases,
	SUM(CAST(cd.new_deaths AS bigint)) AS New_deaths
FROM PortfolioProject..CovidDeaths AS cd
INNER JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.iso_code = cv.iso_code
)
SELECT
	Months,
	Continent,
	New_cases,
	New_deaths
FROM AggregatedTable
GROUP BY cd.continent, Months
ORDER BY Months ASC, New_cases DESC, New_deaths DESC
;*/

--====================================================================--
/*The below query works */
/*
SELECT 
continent, 
sum([new_cases]) AS Newcases, 
sum(cast([new_deaths] as float)) AS NewDeaths
FROM PortfolioProject..CovidDeaths
WHERE date BETWEEN '2021-12-01 00:00:00.000' AND '2021-12-30 00:00:00.000'
GROUP BY continent
;
*/
--===================================================================--
--===DEATHPERCENTAGE==--
-- Looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country

SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	total_deaths/total_cases * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%United Kingdom%'
ORDER BY location, date
;

--====================================================================--
-- Looking at Total Cases vs Population --
-- this will show us what population of the country has gotten covid--

SELECT 
	location,
	CAST(date AS date) AS Date,
	population,
	total_cases,
	(total_cases/population) * 100 AS PopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location IN('United States','United Kingdom') AND Date = '2021-12-08'
ORDER BY location, Date
;
--====================================================================--
-- Looking at countries with Highest Infection Rate compared to Population

SELECT 
	location,
	population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population)) * 100 AS HighestInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%United Kingdom%'
GROUP BY location, population
ORDER BY HighestInfectionRate DESC
;

--====================================================================--
/* THE BELOW SHOWS WHERE CONTINENT IS NOT NULL */
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4
--==================================================================--
/* Showing countries with Highest Death Count Population */
SELECT 
	location,
	MAX(CAST(total_deaths AS Int)) AS Total_deathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_deathsCount DESC
;
--==============================================================--
-- let's break things down by continent
-- Continents with highest death counta --
SELECT 
	location,
	MAX(CAST(total_deaths AS Int)) AS Total_deathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_deathsCount DESC
;
----------------------------------------------------------------------
-- Showing the continents with highest death count 
SELECT 
	continent,
	MAX(CAST(total_deaths AS Int)) AS Total_deathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_deathsCount DESC
;
--==================================================================--
-- breaking of global numbers
SELECT 
	--date,
	SUM(new_cases) AS new_cases,
	SUM(CAST(new_deaths AS int)) AS new_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%United Kingdom%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2
;
--=================================================================--
-- Looking at total population vs vaccinations
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Vaccinated_Num,
	--MAX(Rolling_Vaccinated_Num/d.population) * 100 -- cannot use an alias table to query with - therefore will need cte/temp table
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.date = v.date
	AND d.location = d.location
WHERE d.continent IS NOT NULL
ORDER BY 1,2,3
;
--===================================================================--
/* CREATING CTE*/
WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Vaccinated_Num) AS (
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Vaccinated_Num
	--MAX(Rolling_Vaccinated_Num/d.population) * 100 -- cannot use an alias table to query with - therefore will need cte/temp table
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.date = v.date
	AND d.location = d.location
WHERE d.continent IS NOT NULL
--ORDER BY 2,3 --Cant have an order by becuse have already ordered in the OVER Window function--
)
SELECT *,
	(Rolling_Vaccinated_Num/population)*100 AS VaccinatedPopulation
FROM PopvsVac
;
--=====================================================================--
/* CREATING TEMP TABLE*/
DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
	continent NVARCHAR (255),
	location NVARCHAR (255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	Rolling_Vaccinated_Num numeric
)
INSERT INTO #PercentPopVaccinated
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Vaccinated_Num
	--MAX(Rolling_Vaccinated_Num/d.population) * 100 -- cannot use an alias table to query with - therefore will need cte/temp table
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.date = v.date
	AND d.location = d.location
WHERE d.continent IS NOT NULL
--ORDER BY 2,3 --Cant have an order by becuse have already ordered in the OVER Window function--

SELECT *,
	(Rolling_Vaccinated_Num/population)*100 AS VaccinatedPopulation
FROM #PercentPopVaccinated
;
--==================================================================--
/* CREATING A VIEW TO STORE DATA FOR LATER VISUALISATIONS */
CREATE VIEW PercentPopVaccinated AS
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Vaccinated_Num
	--MAX(Rolling_Vaccinated_Num/d.population) * 100 -- cannot use an alias table to query with - therefore will need cte/temp table
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.date = v.date
	AND d.location = d.location
WHERE d.continent IS NOT NULL
--ORDER BY 2,3 
--===============================================================--
/* Selecting all from view which can be used later */
SELECT *
FROM PortfolioProject.dbo.PercentPopVaccinated
