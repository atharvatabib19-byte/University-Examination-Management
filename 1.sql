CREATE DATABASE IF NOT EXISTS university_examination_management;

USE university_examination_management;

CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(20) NOT NULL UNIQUE,
    status ENUM('Active', 'Inactive') DEFAULT 'Active'
);

INSERT INTO departments
(department_name, department_code)
VALUES
('Information Technology', 'IT'),
('Computer Science', 'CS'),
('Computer Applications', 'CA'),
('Data Science', 'DS'),
('Artificial Intelligence', 'AI');

SELECT * FROM departments;