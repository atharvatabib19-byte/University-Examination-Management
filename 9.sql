DELIMITER $$

CREATE PROCEDURE calculate_student_result(
    IN p_student_id INT,
    IN p_exam_id INT
)
BEGIN

    DECLARE v_total_obtained DECIMAL(8,2);
    DECLARE v_total_maximum DECIMAL(8,2);
    DECLARE v_percentage DECIMAL(5,2);
    DECLARE v_grade VARCHAR(5);
    DECLARE v_status VARCHAR(10);
    DECLARE v_failed_subjects INT;

    SELECT
        COALESCE(SUM(m.total_marks), 0),
        COALESCE(
            SUM(
                s.theory_max_marks
                + s.practical_max_marks
                + s.internal_max_marks
            ),
            0
        ),
        COALESCE(
            SUM(
                CASE
                    WHEN m.total_marks < s.passing_marks
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
    INTO
        v_total_obtained,
        v_total_maximum,
        v_failed_subjects

    FROM marks m

    INNER JOIN subjects s
        ON m.subject_id = s.subject_id

    WHERE m.student_id = p_student_id
      AND m.exam_id = p_exam_id;

    IF v_total_maximum > 0 THEN

        SET v_percentage =
            ROUND(
                (v_total_obtained / v_total_maximum) * 100,
                2
            );

    ELSE

        SET v_percentage = 0;

    END IF;


    SET v_grade =
        CASE

            WHEN v_failed_subjects > 0 THEN 'F'

            WHEN v_percentage >= 90 THEN 'A+'

            WHEN v_percentage >= 80 THEN 'A'

            WHEN v_percentage >= 70 THEN 'B+'

            WHEN v_percentage >= 60 THEN 'B'

            WHEN v_percentage >= 50 THEN 'C'

            WHEN v_percentage >= 40 THEN 'D'

            ELSE 'F'

        END;


    SET v_status =
        CASE
            WHEN v_failed_subjects = 0
                 AND v_percentage >= 40
            THEN 'PASS'

            ELSE 'FAIL'
        END;


    INSERT INTO results
    (
        student_id,
        exam_id,
        total_obtained,
        total_maximum,
        percentage,
        grade,
        result_status
    )

    VALUES
    (
        p_student_id,
        p_exam_id,
        v_total_obtained,
        v_total_maximum,
        v_percentage,
        v_grade,
        v_status
    )

    ON DUPLICATE KEY UPDATE

        total_obtained = v_total_obtained,
        total_maximum = v_total_maximum,
        percentage = v_percentage,
        grade = v_grade,
        result_status = v_status,
        result_date = CURRENT_DATE;

END$$

DELIMITER ;

CALL calculate_student_result(1, 1);
CALL calculate_student_result(2,1);
CALL calculate_student_result(3,1);

SELECT * FROM results;


DELIMITER $$

CREATE PROCEDURE calculate_all_results(
    IN p_exam_id INT
)
BEGIN

    DECLARE done INT DEFAULT 0;
    DECLARE v_student_id INT;

    DECLARE student_cursor CURSOR FOR
        SELECT student_id
        FROM exam_registrations
        WHERE exam_id = p_exam_id
          AND registration_status = 'Registered';

    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET done = 1;


    OPEN student_cursor;


    result_loop: LOOP

        FETCH student_cursor
        INTO v_student_id;


        IF done = 1 THEN
            LEAVE result_loop;
        END IF;


        CALL calculate_student_result(
            v_student_id,
            p_exam_id
        );


    END LOOP;


    CLOSE student_cursor;

END$$

DELIMITER ;

CALL calculate_all_results(1);


SELECT *
FROM students
JOIN programs
JOIN departments
JOIN results
JOIN examinations;


CREATE VIEW student_result_view AS

SELECT

    s.student_id,

    s.roll_no,

    s.enrollment_no,

    CONCAT(
        s.first_name,
        ' ',
        s.last_name
    ) AS student_name,

    p.program_name,

    d.department_name,

    e.exam_name,

    e.academic_year,

    e.semester,

    r.total_obtained,

    r.total_maximum,

    r.percentage,

    r.grade,

    r.result_status,

    r.result_date

FROM results r

INNER JOIN students s
    ON r.student_id = s.student_id

INNER JOIN programs p
    ON s.program_id = p.program_id

INNER JOIN departments d
    ON p.department_id = d.department_id

INNER JOIN examinations e
    ON r.exam_id = e.exam_id;
    
    SHOW FULL TABLES
WHERE Table_type = 'VIEW';

SELECT * FROM student_result_view;

