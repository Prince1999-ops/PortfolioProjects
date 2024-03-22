SELECT *
FROM [PORTFOLIO PROJECT]..Coviddeaths
where continent is not null


SELECT Location,date,total_cases,new_cases,total_deaths,population
FROM [PORTFOLIO PROJECT].. coviddeaths
order by 1,2

-- Now looking at total cases vs Total Deaths
SELECT Location, date, total_cases, new_cases, total_deaths, 
       (CAST(total_deaths AS float) / total_cases) * 100 AS Deathpercentage
FROM [PORTFOLIO PROJECT]..CovidDeaths
where location like '%tanzania'
ORDER BY 1, 2;

-- looking at the total cases vs populations

SELECT Location, date, population, total_cases, new_cases, total_deaths, 
       (CAST(total_deaths AS float) / population) * 100 AS populationpercentage
FROM [PORTFOLIO PROJECT]..CovidDeaths
where location like '%tanzania'
ORDER BY 1, 2;


-- looking at countries with highest infection rate compared to poipulation

SELECT Location,population, MAX(total_cases) as HighestInfectionCount,
       (CAST(MAX(total_cases) AS float) / population) * 100 AS Infectionpercent
FROM [PORTFOLIO PROJECT]..CovidDeaths
group by Location, population 
order by Infectionpercent DESC


-- looking at countries with highest death count per population
SELECT Location,population,MAX(cast(total_deaths as int)) as HighestDearthnCount,
       (CAST(MAX(total_deaths) AS float) / population) * 100 AS Deathpercent
FROM [PORTFOLIO PROJECT]..CovidDeaths
where continent is not null
group by Location, population
order by Deathpercent DESC

-- lets break this down by continent
SELECT continent,MAX(cast(total_deaths as int)) as HighestDeathnCount
FROM [PORTFOLIO PROJECT]..CovidDeaths
where continent is not null
group by continent
order by HighestDeathnCount DESC

-- further breakdown with better and accurate data ( continent with the highest death count per population)
SELECT location,MAX(cast(total_deaths as int)) as HighestDeathnCount
FROM [PORTFOLIO PROJECT]..CovidDeaths
where continent is null
group by location
order by HighestDeathnCount DESC

-- global numbers
SELECT Location, date, total_cases, new_cases, total_deaths, 
       (CAST(total_deaths AS float) / total_cases) * 100 AS Deathpercentage
FROM [PORTFOLIO PROJECT]..CovidDeaths
where continent is not null
ORDER BY 1, 2

--- globally numbers number 2
Select date, SUM(new_cases) as total_cases, SUM(cast (new_deaths as int)) as total_deaths, SUM(cast(new_deaths as float))/SUM(New_Cases)*100 as DeathPercentage
From [PORTFOLIO PROJECT]..CovidDeaths
where continent is not null
Group By date 
order by 1,2

-- another one for the golbal cases per day
SELECT date, 
       SUM(new_cases) as total_cases, 
       SUM(cast(new_deaths as int)) as total_deaths, 
       CASE 
           WHEN SUM(new_cases) = 0 THEN 0
           ELSE SUM(cast(new_deaths as float))/SUM(new_cases)*100
       END as DeathPercentage
FROM [PORTFOLIO PROJECT]..CovidDeaths
GROUP BY date 
ORDER BY 1,2

-- joining the two previous codes to show one table 
SELECT t1.date, t1.total_cases, t1.total_deaths, t1.DeathPercentage, t2.global_total_cases
FROM (
    SELECT date, 
           SUM(new_cases) as total_cases, 
           SUM(cast(new_deaths as int)) as total_deaths, 
           SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
    FROM [PORTFOLIO PROJECT]..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY date 
) t1
JOIN (
    SELECT date, SUM(new_cases) as global_total_cases
    FROM [PORTFOLIO PROJECT]..CovidDeaths
    GROUP BY date
) t2 ON t1.date = t2.date
ORDER BY t1.date, t1.total_cases;

--Total population vs vaccination table

select a.continent, a.location, a.date,b.new_vaccinations
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
group by a.continent, a.location,a.date, b.new_vaccinations
order by a.location, a.date

-- another total population vs vaccination table ( FROM ALEX)
select a.continent, a.location, a.date,a.population,b.new_vaccinations,SUM(cast(b.new_vaccinations as int)) OVER (Partition by a.location)
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
WHERE a.continent is not null
order by 1,2,3

-- another one but by using convert instead of cast
select a.continent, a.location, a.date,a.population,b.new_vaccinations,
   SUM(convert(int,b.new_vaccinations)) OVER (Partition by a.location order by a.date) as RollingPeopleVaccinated
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
WHERE a.continent is not null
order by 2,3

-- another with running total ( same as the previous just a few modifications and better understanding { where running total is the aggregated sum of the new_vaccinations similar to an incrment})

SELECT a.continent, a.location, a.date, a.population, b.new_vaccinations,
       SUM(CONVERT(int, b.new_vaccinations)) OVER (PARTITION BY a.location ORDER BY a.date) AS running_total
FROM [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b ON a.location = b.location AND a.date = b.date
WHERE a.continent IS NOT NULL
ORDER BY a.continent, a.location, a.date;

-- with using CTE
with PopvsVac ( continent, location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
select a.continent, a.location, a.date,a.population,b.new_vaccinations,
   SUM(convert(int,b.new_vaccinations)) OVER (Partition by a.location order by a.date) as RollingPeopleVaccinated
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
WHERE a.continent is not null
--order by 2,3
)
SELECT *,(cast(RollingPeopleVaccinated as float)/population)*100 as rollunderpop
FROM PopvsVac

--TEMP TABLE

drop table if exists #PercentPopulationVaccinated
CREATE table #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    LOCATION NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated FLOAT
)

INSERT INTO #PercentPopulationVaccinated
select a.continent, a.location, a.date,a.population,b.new_vaccinations,
   SUM(convert(int,b.new_vaccinations)) OVER (Partition by a.location order by a.date) as RollingPeopleVaccinated
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
WHERE a.continent is not null

SELECT *,(cast(RollingPeopleVaccinated as float)/population )*100 as rollunderpop
FROM #PercentPopulationVaccinated

-- CREATING VIEW FOR LATER VISUALIZATIONS

Create view PercentpopulationVaccinated as
select a.continent, a.location, a.date,a.population,b.new_vaccinations,
   SUM(convert(int,b.new_vaccinations)) OVER (Partition by a.location order by a.date) as RollingPeopleVaccinated
from [PORTFOLIO PROJECT]..CovidDeaths a
JOIN [PORTFOLIO PROJECT]..CovidVaccinations b
 ON a.location = b.location
 and a.date = b.date
WHERE a.continent is not null
