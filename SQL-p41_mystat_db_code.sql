-- student
-- teacher
-- grade
-- homework
-- pair
-- subject
-- group
--------

use p41_mystat_db;

CREATE TABLE countries (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(64) NULL
);

CREATE TABLE cities (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(64) NULL,
	country_id int NOT NULL,

	CONSTRAINT FK_cities_country FOREIGN KEY(country_id) REFERENCES countries(id)
);

CREATE TABLE branches (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(64) NULL,
	country_id int NOT NULL,
	city_id int NOT NULL,

	CONSTRAINT FK_branches_country FOREIGN KEY(country_id) REFERENCES countries(id),
	CONSTRAINT FK_branches_city FOREIGN KEY(city_id) REFERENCES cities(id),
);

CREATE TABLE classrooms (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	number nvarchar(32) NOT NULL,
	title nvarchar(64) NULL,
	branch_id int NOT NULL,

	CONSTRAINT FK_classrooms_branch FOREIGN KEY(branch_id) REFERENCES branches(id),

);

CREATE TABLE schedule_items (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	number tinyint NOT NULL,
	item_start time NOT NULL,
	item_end time NOT NULL,
	status tinyint DEFAULT(1) NOT NULL
);

CREATE TABLE flows (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(128) NOT NULL,
	created_at datetime DEFAULT(GETDATE()) NOT NULL,
	deleted_at datetime NULL
);

CREATE TABLE subjects (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(128) NOT NULL,
	deleted_at datetime NULL,
	flow_id int NOT NULL,

	CONSTRAINT FK_subjects_flow FOREIGN KEY(flow_id) REFERENCES flows(id)
);

CREATE TABLE groups (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(32) NOT NULL,
	status tinyint DEFAULT(1) NOT NULL,
	flow_id int NOT NULL,

	CONSTRAINT FK_groups_flow FOREIGN KEY(flow_id) REFERENCES flows(id)
);

----------- auth----

CREATE TABLE users (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	email varchar(128) UNIQUE NOT NULL,
	pass_hash char(256) NOT NULL,
	created_at datetime DEFAULT(GETDATE()) NOT NULL,
	deleted_at datetime NULL
);

CREATE TABLE roles (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(32) NOT NULL,						-- Админ
	slug varchar(32) UNIQUE NOT NULL,					-- admin
);

CREATE TABLE permissions (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	title nvarchar(128) NOT NULL,						-- Create homework
	slug varchar(128) UNIQUE NOT NULL,					-- create_hw
);

CREATE TABLE permissions_roles (
	permission_id int NOT NULL,
	role_id int NOT NULL,

	CONSTRAINT PK_permissions_roles PRIMARY KEY (permission_id, role_id),
	CONSTRAINT FK_permissions_roles_permission FOREIGN KEY (permission_id) REFERENCES permissions (id),
	CONSTRAINT FK_permissions_roles_role FOREIGN KEY (role_id) REFERENCES roles (id)
);

CREATE TABLE roles_users (
	role_id int NOT NULL,
	user_id int NOT NULL,

	CONSTRAINT PK_roles_users PRIMARY KEY (role_id, user_id),
	CONSTRAINT FK_roles_users_role FOREIGN KEY (role_id) REFERENCES roles (id),
	CONSTRAINT FK_roles_users_user FOREIGN KEY (user_id) REFERENCES users (id)

);

CREATE TABLE permissions_users (
	permission_id int NOT NULL,
	user_id int NOT NULL,

	CONSTRAINT PK_permissions_users PRIMARY KEY (permission_id, user_id),
	CONSTRAINT FK_permissions_users_permission FOREIGN KEY (permission_id) REFERENCES permissions (id),
	CONSTRAINT FK_permissions_users_user FOREIGN KEY (user_id) REFERENCES users (id)
);

--------------------

----------- profiles -----

CREATE TABLE employee_profiles (
	id int PRIMARY KEY NOT NULL,
	first_name nvarchar(64) NOT NULL,
	last_name nvarchar(64) NOT NULL,
	phone varchar(32) NULL,
	-- ....

	CONSTRAINT FK_employee_profiles_user FOREIGN KEY(id) REFERENCES users(id)
);

CREATE TABLE student_profiles (
	id int PRIMARY KEY NOT NULL,
	first_name nvarchar(64) NOT NULL,
	last_name nvarchar(64) NOT NULL,
	phone varchar(32) NULL,
	-- ....

	CONSTRAINT FK_student_profiles_user FOREIGN KEY(id) REFERENCES users(id)
);

--------------------------


CREATE TABLE pairs (
	id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	pair_date date NOT NULL,
	is_online bit DEFAULT(1) NOT NULL,
	schedule_item_id int NOT NULL,
	subject_id int NOT NULL,
	classroom_id int NOT NULL,
	teacher_id int NOT NULL,


	CONSTRAINT FK_pairs_schedule_item FOREIGN KEY(schedule_item_id) REFERENCES schedule_items(id),
	CONSTRAINT FK_pairs_schedule_subject FOREIGN KEY(subject_id) REFERENCES subjects(id),
	CONSTRAINT FK_pairs_classrooms FOREIGN KEY(classroom_id) REFERENCES classrooms(id),
	CONSTRAINT FK_pairs_teacher FOREIGN KEY(teacher_id) REFERENCES employee_profiles(id),
);


CREATE TABLE groups_pairs (
	group_id int NOT NULL,
	pair_id int NOT NULL,

	CONSTRAINT PK_groups_pairs PRIMARY KEY (group_id, pair_id),
	CONSTRAINT FK_groups_pairs_group FOREIGN KEY (group_id) REFERENCES groups (id),
	CONSTRAINT FK_groups_pairs_pair FOREIGN KEY (pair_id) REFERENCES pairs (id)
);


------------------------------------------
-- Доработка (оптимизация)
ALTER TABLE branches
DROP CONSTrAINT FK_branches_country

ALTER TABLE branches
DROP COLUMN country_id