
USE p41_mystat_db;	

-- Итоговое задание (Вариант 1)
	--! 1. Добавить возможность того, что студент может состоять только в одной учебной группе

	ALTER TABLE student_profiles
	ADD group_id int NOT NULL;

	ALTER TABLE student_profiles
	ADD CONSTRAINT FK_student_profiles_group 
	FOREIGN KEY (group_id) REFERENCES groups(id);

--#############################################################################################################################################################################

	-- 2. Добавить возможность определять тему каждой пары

	CREATE TABLE topics (
		id int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		title nvarchar(128) NOT NULL,
		info nvarchar(256) NOT NULL,
	);


	ALTER TABLE pairs
	ADD topic_id int NOT NULL;


	ALTER TABLE pairs 
	ADD CONSTRAINT FK_pairs_topic FOREIGN KEY (topic_id) REFERENCES topics(id);

--#############################################################################################################################################################################

	-- 3. Добавить возможность на паре:
    -- 3.1. Отмечать статус студента (отсутствует, опоздал, присутствует)
		CREATE TABLE student_presence_status (
			id tinyint PRIMARY KEY IDENTITY(1, 1),
			title nvarchar(128) NOT NULL,
			slag nvarchar(64) NULL, 
		);

		INSERT INTO student_presence_status (title, slag) VALUES ('present', 'pres');
		INSERT INTO student_presence_status (title, slag) VALUES ('late', 'late');
		INSERT INTO student_presence_status (title, slag) VALUES ('absent', 'abst');

		-- Это журналы - у каждой пары свой журнал (имеется ввиду, что когда назнавчается(создается) пара, то будет создан и, скажем так, журнал пары)
		CREATE TABLE class_registers (
			id int PRIMARY KEY IDENTITY(1, 1),
			pair_id int UNIQUE NOT NULL,

			CONSTRAINT FK_class_register_pair FOREIGN KEY (pair_id) REFERENCES pairs(id)
		);

		-- Заметки по поводу каждоо ученика
		CREATE TABLE class_register_notes (
			id int PRIMARY KEY IDENTITY(1, 1),
			student_id int NOT NULL,
			status_id tinyint NOT NULL,
			class_register_id int NOT NULL,

			CONSTRAINT FK_class_register_notes_student FOREIGN KEY (student_id) REFERENCES student_profiles (id),
			CONSTRAINT FK_class_register_notes_status FOREIGN KEY (status_id) REFERENCES student_presence_status (id),
			CONSTRAINT FK_class_register FOREIGN KEY (class_register_id) REFERENCES class_registers (id),
		);


		-- Логика автоматического создания журнала может быть имплементирована
		-- в бэкенде. Ради практики сделаю через тригер
		--CREATE TRIGGER trg_create_class_register
		--ON pairs
		--AFTER INSERT
		--AS
		--BEGIN
		--	SET NOCOUNT ON;
		--	INSERT INTO class_registers (pair_id)
		--	SELECT id 
		--	FROM inserted;
		--END;




    --3.2. Выставлять студентам оценку за пару (от 1 до 12)

	CREATE TABLE grades (
		id int PRIMARY KEY IDENTITY(1, 1),
		grade tinyint NOT NULL,

		CONSTRAINT CH_grades_grade CHECK (1 <= grade AND grade <= 12)
	);

	-- Заполнение таблички grades оценками
	INSERT INTO grades (grade) VALUES 
	(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12);


	ALTER TABLE class_register_notes
	ADD grade_id int NULL;

	ALTER TABLE class_register_notes
	ADD CONSTRAINT FK_class_register_notes_grade FOREIGN KEY (grade_id) REFERENCES grades (id);

	ALTER TABLE class_register_notes
	ADD CONSTRAINT UQ_register_student UNIQUE (class_register_id, student_id); -- Мнение поменялось: думаю, что такой констрєйнт имеет место быть



    --3.3. Оставлять комментарий преподавателя для учебной части, относительно отсутствующего студента

	-- Сразу реализовываем логику, что оставлять комментарий может любой юзер
	CREATE TABLE comments (
		id int PRIMARY KEY IDENTITY(1, 1),
		user_id int NOT NULL,
		comment_text nvarchar(MAX) NULL

		CONSTRAINT FK_comments_user FOREIGN KEY (user_id) REFERENCES users (id)
	);

	
	CREATE TABLE class_register_notes_comments (
		id int PRIMARY KEY IDENTITY(1, 1),
		comment_id int UNIQUE NOT NULL,
		class_register_notes_id int NOT NULL, -- НО НЕ UNIQUE! Значит, может быть больше одного коммментария

		CONSTRAINT FK_class_register_notes_comment_id FOREIGN KEY (comment_id) REFERENCES comments (id),
		CONSTRAINT FK_class_register_note_id FOREIGN KEY (class_register_notes_id) REFERENCES class_register_notes (id),
	);
	-- Получается для каждой записи (class_register_note) можно оставлять сколько угодно коментариев

--#############################################################################################################################################################################


 --4 (дополнительно) Добавить возможность преподавателю создавать ДЗ для каждой пары
 --   - тема
 --   - файл с заданием
 --   - описание
 --   - установка крайней даты сдачи ДЗ

 CREATE TABLE file_paths (
	id int PRIMARY KEY IDENTITY(1, 1),
	file_path nvarchar(500),
 );

 CREATE TABLE homeworks (
	id int PRIMARY KEY IDENTITY(1, 1),
	pair_id int NOT NULL,
	task_file_path int NOT NULL,
	description nvarchar(MAX) NULL,
	deadline datetime2 NOT NULL,

	CONSTRAINT FK_homework_topic FOREIGN KEY (pair_id) REFERENCES pairs(id),
	CONSTRAINT FK_task_file_path FOREIGN KEY (task_file_path) REFERENCES file_paths(id),
 );


 --#############################################################################################################################################################################

 --5 (дополнительно) Добавить возможность студенту загружать ДЗ (с возможностью пересдачи)
 --   - файл с решением
 --   - комментарий
 --   - дата загрузки

CREATE TABLE homework_submissions (
	id int PRIMARY KEY IDENTITY(1, 1),
	homework_id int NOT NULL,
	student_id int NOT NULL,
	file_path_id int NOT NULL,      -- Файл с решением
	student_comment_id int NULL,
	submission_date datetime2 NOT NULL DEFAULT GETDATE(),

	CONSTRAINT FK_submissions_homework FOREIGN KEY (homework_id) REFERENCES homeworks(id),
    CONSTRAINT FK_submissions_student FOREIGN KEY (student_id) REFERENCES student_profiles(id), -- Предполагается наличие таблицы students
    CONSTRAINT FK_submissions_file FOREIGN KEY (file_path_id) REFERENCES file_paths(id),
	CONSTRAINT FK_student_comment FOREIGN KEY (student_comment_id) REFERENCES comments(id),
);

--#############################################################################################################################################################################

--6 (дополнительно) Добавить возможность преподавателю оценивать загруженное студентом ДЗ

CREATE TABLE homework_grades (
	id int PRIMARY KEY IDENTITY(1, 1),
	submission_id int NOT NULL UNIQUE, -- Оценка привязана к конкретной попытке
	teacher_id int NOT NULL,
	grade_id int NOT NULL,
	teacher_comment_id int NULL,
	graded_at datetime2 NOT NULL DEFAULT GETDATE(),

	CONSTRAINT FK_grades_submission FOREIGN KEY (submission_id) REFERENCES homework_submissions(id),
    CONSTRAINT FK_grades_teacher FOREIGN KEY (teacher_id) REFERENCES employee_profiles(id), 
    CONSTRAINT FK_grades_value FOREIGN KEY (grade_id) REFERENCES grades(id),
	CONSTRAINT FK_teacher_comment FOREIGN KEY (teacher_comment_id) REFERENCES comments(id), 
);








