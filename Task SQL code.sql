-- Create the employees table
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    start_date DATE
);

-- Create the salary_history table
CREATE TABLE salary_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    department VARCHAR(50) NOT NULL,
    record_year YEAR NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--  Generate 1000 random rows for employee table
INSERT INTO employees (first_name, last_name, department, salary, start_date)
SELECT
    CONCAT(UCASE(LEFT(SUBSTRING(MD5(RAND()), 1, 6), 1)), LOWER(SUBSTRING(MD5(RAND()), 2, 5))) AS first_name,
    CONCAT(UCASE(LEFT(SUBSTRING(MD5(RAND()), 7, 6), 1)), LOWER(SUBSTRING(MD5(RAND()), 8, 5))) AS last_name,
    ELT(FLOOR(1 + RAND() * 7), 'HR', 'Finance', 'Engineering', 'Marketing', 'Sales', 'IT Support', 'Operations') AS department,
    ROUND(30000 + (RAND() * 70000), 2) AS salary,
    DATE_ADD('2015-01-01', INTERVAL FLOOR(RAND() * 3650) DAY) AS start_date
FROM
    (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
            SELECT 9 UNION ALL SELECT 10) AS a
CROSS JOIN
    (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
            SELECT 9 UNION ALL SELECT 10) AS b
CROSS JOIN
    (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
            SELECT 9 UNION ALL SELECT 10) AS c;
-- 10 × 10 × 10 = 1000 rows

-- Check sample results
SELECT * FROM employees LIMIT 10;


-- proc to Insert into salary_history table
DELIMITER $$

CREATE PROCEDURE generate_salary_history()
BEGIN
    DECLARE emp INT DEFAULT 1;
    DECLARE base_salary DECIMAL(10,2);
    DECLARE current_year INT;
    DECLARE growth DECIMAL(10,2);
    DECLARE dept VARCHAR(50);

    WHILE emp <= 1000 DO
        -- get base salary and department from employees table
        SELECT salary, department INTO base_salary, dept 
        FROM employees 
        WHERE employee_id = emp;

        SET current_year = 2016;

        WHILE current_year <= 2024 DO
            -- simulate salary increase between 2%–10% per year
            SET growth = base_salary * (1 + (RAND() * 0.08) + 0.02);
            SET base_salary = ROUND(growth, 2);

            INSERT INTO salary_history (employee_id, department, record_year, salary)
            VALUES (emp, dept, current_year, base_salary);

            SET current_year = current_year + 1;
        END WHILE;

        SET emp = emp + 1;
    END WHILE;
END $$

DELIMITER ;
-- Run it
CALL generate_salary_history();

-- Question 1 : Show employees with second highest salary in each department, make it dynamic, that it can take parameters, where user can change second highest to any other number.

SET @N := 2;  -- Change this to get N-th highest salary per department

WITH rank_employees AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT 
    department,
    employee_id,
    first_name,
    last_name,
    salary
FROM rank_employees
WHERE salary_rank = @N
ORDER BY department, salary DESC;


-- Question 2: Show employees with highest change between their starting salary and current salary for each department.

WITH salary_change AS (
    SELECT 
        sh.employee_id,
        sh.department,
        MIN(sh.salary) AS starting_salary,
        MAX(sh.salary) AS current_salary,
        (MAX(sh.salary) - MIN(sh.salary)) AS salary_difference
    FROM salary_history sh
    GROUP BY sh.employee_id, sh.department
)
SELECT 
    sc.department,
    sc.employee_id,
    e.first_name,
    e.last_name,
    sc.starting_salary,
    sc.current_salary,
    sc.salary_difference
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY department ORDER BY salary_difference DESC) AS rnk
    FROM salary_change
) sc
JOIN employees e ON sc.employee_id = e.employee_id
WHERE sc.rnk = 1
ORDER BY sc.department;


-- Question 3: Create a time series view of the data, showing average salary per department, group by year/month.

CREATE OR REPLACE VIEW avg_salary_time_series AS
SELECT 
    department,
    YEAR(start_date) AS year,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department, YEAR(start_date)
ORDER BY department, year;

select * from avg_salary_time_series;





