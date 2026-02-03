-- **Beginner Level (1-3)**
/*
1. **Retrieve all active patients**
	Write a query to return all patients
	who are active.
*/
SELECT
	id,
	identifier,
	name,
	gender,
	birth_date,
	address,
	telecom,
	active,
	created_at
FROM public."Patient"
WHERE active = true;

/*
2. **Find encounters for a specific patient**
	Given a patient_id, retrieve all encounters
	for that patient, including the status and
	encounter date.
*/
SELECT
	id,
	patient_id,
	status,
	encounter_date
FROM public."Encounter"
WHERE patient_id = '5cca41d6-ba99-4970-8e50-a821cd46dafc'
ORDER BY encounter_date ASC;

/*
3. **List all observations recorded for a patient**
	Write a query to fetch all observations for a given
	patient_id, showing the observation type, value, unit,
	and recorded date.
*/
SELECT
	id,
	patient_id,
	type,
	value,
	unit,
	recorded_at
FROM public."Observation"
WHERE patient_id = 'cefc0751-fabe-4369-a020-ddf874053475'
ORDER BY value DESC;



-- **Intermediate Level (4-7)**
/*
4. **Find the most recent encounter for each patient**
	Retrieve each patient’s most recent encounter (based on
	encounter_date). Return the patient_id, encounter_date,
	and status.
*/
SELECT
	en.patient_id,
	en.encounter_date,
	en.status
FROM public."Encounter" as en
JOIN (
SELECT
	patient_id,
	max(encounter_date) as max_encounter_date
FROM public."Encounter"
GROUP BY 1
) e
ON en.patient_id = e.patient_id
AND EN.encounter_date = e.max_encounter_date
ORDER BY patient_id;

-- Improved and Optimized
	-- single table scan
	-- no join
	-- no subquery
	-- uses sorting instead of grouping and joning
	-- edgecase downside: exact same encounter_date for single patient
SELECT DISTINCT ON (patient_id)
    patient_id,
    encounter_date,
    status
FROM public."Encounter"
ORDER BY patient_id, encounter_date DESC;

/*
5. **Find patients who have had encounters with more than one practitioner**
	Write a query to return a list of patient IDs who have had encounters with
	more than one distinct practitioner.
*/
SELECT
	patient_id,
	COUNT(practitioner_id) AS encounter_counts
FROM public."Encounter"
GROUP BY 1
HAVING COUNT(practitioner_id) > 1
ORDER BY 1 DESC;

-- Improved and Optimized
	-- Answers the question asked
	-- More readable, less verbose
	-- Edge case downside: practitioner_ids that are null
SELECT
	patient_id
FROM public."Encounter"
GROUP BY 1
HAVING COUNT(practitioner_id) > 1;

/*
6. **Find the top 3 most prescribed medications**
	Write a query to find the three most commonly
	prescribed medications from the MedicationRequest
	table, sorted by the number of prescriptions.
*/
SELECT
	medication_name,
	COUNT(medication_name)
FROM public."MedicationRequest"
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

/*
7. **Get practitioners who have never prescribed any medication**
	Write a query to find all practitioners who do not appear in the
	MedicationRequest table as a prescribing practitioner.
*/
SELECT
	p.id
FROM public."Practitioner" AS p
LEFT JOIN public."MedicationRequest" AS mr
	ON p.id = mr.practitioner_id
	WHERE mr.practitioner_id IS NULL;

-- Better
	-- simply better for robustness, and management
select
	p.id
from public."Practitioner" as p
where not exists (
	select
		1
	from public."MedicationRequest" as mr
	where mr.practitioner_id = p.id
);


/*
**Advanced Level (8-10)**

8. **Find the average number of encounters per patient**
	Calculate the average number of encounters per patient,
	rounded to two decimal places.
*/
-- Notes:
	-- A bit confusing
	-- Do all Status' count as encounters?
	-- Should we include all patients from the Patient table?
SELECT
    ROUND(AVG(encounter_count), 2) AS avg_encounters_per_patient
FROM (
    SELECT
        patient_id,
        COUNT(*) AS encounter_count
    FROM public."Encounter"
    GROUP BY patient_id
) t;

-- Assumes we want to take into account all patients in patients table
	-- 30 total patients
	-- only 23 have had encounters
SELECT
    ROUND(COUNT(e.patient_id)::numeric / COUNT(DISTINCT p.id), 2) AS avg_encounters_per_patient
FROM public."Encounter" AS e
FULL JOIN public."Patient" AS p
	ON e.patient_id = p.id;

/*
9. **Identify patients who have never had an encounter but have a medication request**
	Write a query to find patients who have a record in the MedicationRequest table but no
	associated encounters in the Encounter table.
*/
SELECT
	p.id
FROM public."Patient" AS p
WHERE NOT EXISTS (
	SELECT
		1
	FROM public."Encounter" AS e
		WHERE p.id = e.patient_id
)
AND EXISTS (
	SELECT
		1
	FROM public."MedicationRequest" AS mr
	WHERE p.id = mr.patient_id
);

-- Note: a set of joins would be preferred for larger datasets with indexing
SELECT
	p.id
FROM public."Patient" p
LEFT JOIN public."Encounter" AS e
	ON p.id = e.patient_id
JOIN public."MedicationRequest" mr
	ON p.id = mr.patient_id
WHERE e.patient_id IS NULL
GROUP BY p.id;


/*
10.	**Determine patient retention by cohort**
	Write a query to count how many patients had
	their first encounter in each month (YYYY-MM
	format) and still had at least one encounter
	in the following six months.
*/

select
	TO_CHAR(min_date, 'YYYY-MM') AS YearMonth,
	count(patient_id)
from (
select
	patient_id,
	age(max(date(encounter_date)), min(date(encounter_date))) as delta_date,
	min(date(encounter_date)) as min_date,
	max(date(encounter_date)) as max_date
from public."Encounter"
group by patient_id
having age(max(date(encounter_date)), min(date(encounter_date))) > interval '24 days'
) d
group by 1;

-- Better Approach (not really)
WITH first_encounter AS (
    SELECT
        patient_id,
        MIN(encounter_date) AS first_date
    FROM public."Encounter"
    GROUP BY patient_id
)
SELECT
    TO_CHAR(first_date, 'YYYY-MM') AS YearMonth,
    COUNT(distinct f.patient_id) AS retained_patients
FROM first_encounter f
JOIN public."Encounter" e
  ON e.patient_id = f.patient_id
 AND e.encounter_date > f.first_date
 AND e.encounter_date <= f.first_date + INTERVAL '4 days'
GROUP BY 1
ORDER BY 1;