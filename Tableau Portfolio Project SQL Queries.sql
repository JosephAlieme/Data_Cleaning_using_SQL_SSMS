/*

Queries used for my Tableau Project

*/

USE PortfolioProject

-- 1. 

Select SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))*1.0/SUM(New_Cases)*100 as DeathPercentage
From Deaths
--Where location = 'Poland'
where continent is not null 
--Group By date
order by 1,2 



-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%pola%'
Where continent is null 
AND location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, 
MAX(total_cases) as HighestInfectionCount,  
Max((total_cases*1.0)/population)*100 as PercentPopulationInfected
From Deaths
--Where location = 'poland' and date < '2022-01-01'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.

Select Location, Population, date, 
MAX(total_cases) as HighestInfectionCount,  
Max(((total_cases*1.0)/population))*100 as PercentPopulationInfected
From Deaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc




-- 5.

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3




-- 6
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Deaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 7

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
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac
