-- Итоговое задание (Вариант 1)
	--! 1. Добавить возможность того, что студент может состоять только в одной учебной группе


USE p41_mystat_db;	
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

	-- 2. Добавить возможность определять тему каждой пары

	CREATE TABLE subjects_topics (
		id int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		title nvarchar(128) NOT NULL,
		info nvarchar(256) NOT NULL,
		
		-- Тема зависит от предмета, который в свою очередь зависит от flow
		subject_id int NOT NULL,

		CONSTRAINT FK_themes_flow FOREIGN KEY (subject_id) REFERENCES subjects(id)
	);


	ALTER TABLE pairs
	ADD topic_id int NOT NULL;


	ALTER TABLE pairs 
	ADD CONSTRAINT FK_pairs_topic FOREIGN KEY (topic_id) REFERENCES subjects_topics(id);

	-- Конечно, логику соответствия между pairs.subject_id и subjects_topics.subject_id 
	-- можно реализовать у клиента, но я все-таки потренеируюсь и реализую логику простенького триггера
	CREATE TRIGGER trg_pairs_topic_check
	ON pairs
	AFTER INSERT, UPDATE
	AS
	BEGIN
		SET NOCOUNT ON; -- чтобы не было лишних сообщений

		IF EXISTS (
			SELECT 1
			FROM inserted i
			JOIN subjects_topics t ON i.topic_id = t.id
			WHERE i.subject_id <> t.subject_id
		)
		BEGIN
			RAISERROR('Topic does not match the subject!', 16, 1);
			ROLLBACK TRANSACTION;
		END
	END;


	-- 3. Добавить возможность на паре:
    --3.1. Отмечать статус студента (отсутствует, опоздал, присутствует)
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

			-- один студент = одна запись в журнале (если нужна такая логика)
			-- CONSTRAINT UQ_register_student UNIQUE (class_register_id, student_id)
		);


		-- Логика автоматического создания журнала может быть имплементирована
		-- в бэкенде. Ради практики сделаю через тригер
		CREATE TRIGGER trg_create_class_register
		ON pairs
		AFTER INSERT
		AS
		BEGIN
			SET NOCOUNT ON;
			INSERT INTO class_registers (pair_id)
			SELECT id 
			FROM inserted;
		END;




    --3.2. Выставлять студентам оценку за пару (от 1 до 12)

	CREATE TABLE grades (
		id int PRIMARY KEY IDENTITY(1, 1),
		grade tinyint NOT NULL,

		CONSTRAINT CH_grades_grade CHECK (1 <= grade AND grade <= 12)
	);


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


	--! Возможность добавдения коментария учителем
	ALTER TABLE class_register_notes
	-- комента может не быть, поэтому NULL
	ADD teacher_comment_id int NULL;

	ALTER TABLE class_register_notes
	ADD CONSTRAINT FK_class_register_notes_teacher_comment  FOREIGN KEY (teacher_comment_id) REFERENCES comments (id);

	--! Возможность добавдения коментария учеником
	ALTER TABLE class_register_notes
	-- комента может не быть, поэтому NULL
	ADD student_comment_id int NULL;

	ALTER TABLE class_register_notes
	ADD CONSTRAINT FK_class_register_notes_student_comment  FOREIGN KEY (student_comment_id) REFERENCES comments (id);


	--ALTER TABLE class_register_notes
	--DROP CONSTRAINT FK_class_register_notes_student_comment, FK_class_register_notes_teacher_comment;








