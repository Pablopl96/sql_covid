-- En este proyecto nos vamos a plantear preguntas y vamos a buscar la respuesta en los datos:
-- Vamos a seleccionar la data que usaremos:
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, date;

-- ¿Cuál es el % de muerte por casos?
SELECT 
	location, date, total_cases, total_deaths, 
    (total_deaths/total_cases) * 100 AS porcentaje_de_muerte
FROM 
	coviddeaths
ORDER BY 
	location, date;
    
--  ¿% de muerte por casos agrupado por país?
SELECT
    location,
    SUM(total_cases) AS total_cases_country,
    SUM(total_deaths) AS total_deaths_country,
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS porcentaje_de_muerte_total
FROM
    coviddeaths
GROUP BY
    location
ORDER BY
    location;
    
-- ¿% de casos por total de población en España? 
SELECT 
	location, date, total_cases, population, 
    (total_cases/population) * 100 AS porcentaje_de_casos
FROM 
	coviddeaths
WHERE 
	location LIKE "Spain"
ORDER BY 
	location;
    
-- % de casos agrupado por mes y ordenador por mayor a menor % en España
WITH ranked_coviddeaths AS (
    SELECT 
        location,
        STR_TO_DATE(date, '%d/%m/%Y') AS formatted_date,
        total_cases,
        population,
        ROW_NUMBER() OVER (PARTITION BY location, 
        YEAR(STR_TO_DATE(date, '%d/%m/%Y')), 
        MONTH(STR_TO_DATE(date, '%d/%m/%Y')) 
        ORDER BY STR_TO_DATE(date, '%d/%m/%Y') DESC) AS row_num
    FROM 
        coviddeaths
    WHERE 
        location LIKE "Spain"
)
-- SELECT *
-- FROM ranked_coviddeaths
SELECT 
    location,
    DATE_FORMAT(formatted_date, '%Y-%m') AS formatted_month,
    MAX(total_cases) AS total_cases_monthly,
    MAX(population) AS population,
    (MAX(total_cases) / MAX(population)) * 100 AS porcentaje_de_casos
FROM 
    ranked_coviddeaths
WHERE 
    row_num = 1
GROUP BY 
    location, formatted_month, population
ORDER BY 
    location, formatted_month DESC;
-- Vemos como el mes con mayor % de casos por población es abril del 2021

-- Qué países tienen los mayores rangos de infección? Es decir, total de casos/ población total
SELECT 
	location,  
    population, 
    MAX(total_cases) AS max_cases,
    MAX(total_cases/ population) * 100 AS infeccion_max_por_pais
FROM 
	coviddeaths
GROUP BY 
	location,  
    population
ORDER BY 
	infeccion_max_por_pais DESC;

-- Qué países tienen la mayor tasa de mortalidad por población?

SELECT 
	location,  
    population, 
    MAX(total_deaths) AS max_deaths,
    MAX(total_deaths/ population) * 100 AS tasa_mortalidad_por_poblacion
FROM 
	coviddeaths
GROUP BY 
	location,  
    population
ORDER BY 
	tasa_mortalidad_por_poblacion DESC;

-- Qué países o continentes tienen  más muertes?
SELECT 
    location,  
    population, 
    MAX(CAST(total_deaths AS SIGNED)) AS max_deaths
FROM  
    coviddeaths
GROUP BY
    location, population
ORDER BY 
    max_deaths DESC;

-- Mostrar los continentes con mayor recuento de muertes por población (tasa de mortalidad por población
Select 
	continent, 
    MAX(CAST(Total_deaths as SIGNED)) as TotalDeathCount
From 
	coviddeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- Números globales, % de muertes globales por fecha
SELECT 
	date, 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths)AS total_deaths,
    SUM(new_deaths) / SUM(new_cases)  * 100 AS porcentaje_muertes_globales
FROM 
	coviddeaths
WHERE continent is not null
GROUP BY date;

-- Números globales, % de muertes globales
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths)AS total_deaths,
    SUM(new_deaths) / SUM(new_cases)  * 100 AS porcentaje_muertes_globales
FROM 
	coviddeaths
WHERE continent is not null;

-- Vamos a unir con la otra tabla
SELECT *
FROM 
	coviddeaths AS cd
JOIN covidvaccinations AS cv
	ON cd.location = cv.location
    AND cd.date = cv.date;
    
-- Total de vacunados vs población total con new_vaccinations, suma acumulada por país(location)
WITH PopvsVac AS (
    SELECT 
        cd.continent, 
        cd.location, 
        STR_TO_DATE(cd.date, '%d/%m/%Y') AS formatted_date,
        cd.population, 
        cv.new_vaccinations,
        (SELECT SUM(cv2.new_vaccinations) 
         FROM covidvaccinations cv2
         WHERE cv2.location = cd.location AND STR_TO_DATE(cv2.date, '%d/%m/%Y') <= STR_TO_DATE(cd.date, '%d/%m/%Y')
        ) AS suma_acumulada_vacunaciones
    FROM 
        coviddeaths cd
    JOIN 
        covidvaccinations cv
    ON 
        cd.location = cv.location
        AND cd.date = cv.date
    WHERE 
        cd.continent IS NOT NULL
)

SELECT 
    *,
    (suma_acumulada_vacunaciones / Population) * 100 AS porcentaje_vacunados
FROM 
    PopvsVac;
    


