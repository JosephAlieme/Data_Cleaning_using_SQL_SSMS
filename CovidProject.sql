/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- After executing below USE statement, any subsequent queries in this query window will be executed in the CovidProject database.

USE PortfolioProject

--1
Select *
From Deaths
Where continent is not null 
--in dataset, some continents are wrongly included in location column and this makes the continent column to have some null values
order by 3,4


--2
-- Selecting Data below that we will begin with:

Select Location, date, total_cases, new_cases, total_deaths, population
From Deaths
Where continent is not null 
order by 1,2


--3
-- Total Cases vs Total Deaths
-- This basically shows the likelihood of dying if you contract covid for people living in Poland (Highest % on 17th May, 2020)

Select Location, date, total_cases,total_deaths, (total_deaths*1.0/total_cases)*100 as DeathPercentage
From PortfolioProject..Deaths
Where location like '%Pola%' 
AND total_cases is not null 
AND total_deaths is not null
AND continent is not null 
order by 5 DESC

--4
-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases, (total_cases*1.0/population)*100 as PercentPopulationInfected
From Deaths
Where location = 'poland'
AND (total_cases*1.0/population)*100 IS NOT NULL
order by 1,2


--5
-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  
(Max(total_cases*1.0)/population)*100 as PercentPopulationInfected
From Deaths
--Where location = 'poland'
Group by Location, Population
order by PercentPopulationInfected desc



--6
-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From Deaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc



--7
-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From Deaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc



--8
-- GLOBAL NUMBERS BY DATE

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))*1.0/SUM(New_Cases)*100 as DeathPercentage
--we CAST new_deaths to convert it from nvarchar(255) to integer,  i.e MAX(cast(new_deaths as int))
From Deaths
where continent is not null 
Group By date
Having SUM(cast(new_deaths as int))/SUM(New_Cases)*100 is not null
order by 1,2

--9
-- To view the Death percentage of the world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))*1.0/SUM(New_Cases)*100 as DeathPercentage
From Deaths
where continent is not null 



--10
-- Total Population vs Vaccinations
-- This shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


--11
-- Total Population vs RollingPeopleVaccinated in Poland
--This shows that First set of vaccinations in poland was taken 2020-12-29 
-- At 2024-01-21, Vaccinations had totalled 41,549,442 in Poland

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
where dea.location = 'Poland' 
AND dea.continent is not null 
--AND vac.new_vaccinations is not null 


--12
-- Total Population vs RollingCountPeopleVaccinated in Poland 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, COUNT(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingCountPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
where dea.location = 'Poland' 
AND dea.continent is not null 

--13
-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated*1.0/Population)*100 as PercentagePeopleVaccinated
From PopvsVac



--14
--Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



--15
-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
