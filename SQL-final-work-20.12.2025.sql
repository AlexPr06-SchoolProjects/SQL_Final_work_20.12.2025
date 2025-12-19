-- Итоговое задание (Вариант 1)
	-- Extract Primary key for student_profiles
	--DECLARE @pk_name sysname;
	--SELECT @pk_name = kc.name
	--FROM sys.key_constraints kc
	--JOIN sys.tables t 
	--	ON kc.parent_object_id = t.object_id
	--WHERE kc.type = 'PK'
	--  AND t.name = 'student_profiles';

	--SELECT @pk_name AS PrimaryKeyName;

	--! 1. Добавить возможность того, что студент может состоять только в одной учебной группе
	
	-- Option 1
	ALTER TABLE student_profiles
	ADD group_id int NOT NULL;

	ALTER TABLE student_profiles
	ADD CONSTRAINT FK_student_profiles_group 
	FOREIGN KEY (group_id) REFERENCES groups(id);


	-- Option 2 if some extra logic will be required
	CREATE TABLE groups_students (
		group_id int NOT NULL,
		student_id int NOT NULL,

		CONSTRAINT PK_groups_students PRIMARY KEY (group_id, student_id),
		CONSTRAINT FK_groups_students_group FOREIGN KEY (group_id) REFERENCES groups (id),
		CONSTRAINT FK_groups_students_pair FOREIGN KEY (student_id) REFERENCES student_profiles (id)
	);







