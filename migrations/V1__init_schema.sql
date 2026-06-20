-- ============================================================
-- BASE DE DATOS: Sistema de Gestión Académica
-- Motor: PostgreSQL
-- ============================================================

-- IMPORTANTE:
-- Si quieres crear la base desde cero, ejecuta esto separado:
-- CREATE DATABASE academic_management_db;

-- Luego conéctate a la base academic_management_db y ejecuta el resto.

-- Si estás en desarrollo y quieres reiniciar todo, puedes descomentar:
-- DROP SCHEMA IF EXISTS academic CASCADE;

CREATE SCHEMA IF NOT EXISTS academic;

SET search_path TO academic, public;

-- ============================================================
-- EXTENSIONES
-- ============================================================

-- CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================================
-- TIPOS ENUM
-- ============================================================

CREATE TYPE user_status AS ENUM (
    'active',
    'inactive',
    'blocked'
);

CREATE TYPE general_status AS ENUM (
    'active',
    'inactive',
    'archived'
);

CREATE TYPE academic_person_status AS ENUM (
    'active',
    'inactive',
    'graduated',
    'suspended',
    'withdrawn'
);

CREATE TYPE period_status AS ENUM (
    'planned',
    'active',
    'closed',
    'archived'
);

CREATE TYPE section_status AS ENUM (
    'planned',
    'open',
    'closed',
    'cancelled',
    'completed'
);

CREATE TYPE enrollment_status AS ENUM (
    'draft',
    'pending',
    'approved',
    'rejected',
    'cancelled'
);

CREATE TYPE enrollment_course_status AS ENUM (
    'enrolled',
    'withdrawn',
    'completed',
    'passed',
    'failed'
);

CREATE TYPE request_type AS ENUM (
    'enrollment_approval',
    'withdrawal',
    'section_change',
    'grade_review',
    'document_update',
    'academic_certificate',
    'other'
);

CREATE TYPE request_status AS ENUM (
    'pending',
    'in_review',
    'approved',
    'rejected',
    'cancelled'
);

CREATE TYPE attendance_status AS ENUM (
    'present',
    'absent',
    'late',
    'excused'
);

CREATE TYPE notification_status AS ENUM (
    'unread',
    'read'
);

CREATE TYPE document_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);

CREATE TYPE course_modality AS ENUM (
    'onsite',
    'virtual',
    'hybrid'
);

-- ============================================================
-- FUNCIÓN PARA updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION academic.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- USUARIOS, ROLES Y PERMISOS
-- ============================================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    avatar_url TEXT,
    status user_status NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, role_id),

    CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
        ON DELETE CASCADE
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (role_id, permission_id),

    CONSTRAINT fk_role_permissions_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_role_permissions_permission
        FOREIGN KEY (permission_id)
        REFERENCES permissions(permission_id)
        ON DELETE CASCADE
);

-- ============================================================
-- ESTRUCTURA ACADÉMICA
-- Facultades, carreras, mallas y cursos
-- ============================================================

CREATE TABLE faculties (
    faculty_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE programs (
    program_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    degree_title VARCHAR(150),
    duration_semesters INT NOT NULL,
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_programs_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES faculties(faculty_id),

    CONSTRAINT chk_program_duration
        CHECK (duration_semesters > 0)
);

CREATE TABLE curricula (
    curriculum_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL,
    version VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    start_year INT,
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_curricula_program
        FOREIGN KEY (program_id)
        REFERENCES programs(program_id),

    CONSTRAINT uq_curriculum_program_version
        UNIQUE (program_id, version)
);

CREATE TABLE courses (
    course_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    credits INT NOT NULL DEFAULT 0,
    theory_hours INT NOT NULL DEFAULT 0,
    practice_hours INT NOT NULL DEFAULT 0,
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_course_credits
        CHECK (credits >= 0),

    CONSTRAINT chk_course_hours
        CHECK (theory_hours >= 0 AND practice_hours >= 0)
);

CREATE TABLE curriculum_courses (
    curriculum_course_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_id UUID NOT NULL,
    course_id UUID NOT NULL,
    semester_number INT NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_curriculum_courses_curriculum
        FOREIGN KEY (curriculum_id)
        REFERENCES curricula(curriculum_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_curriculum_courses_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id),

    CONSTRAINT chk_curriculum_semester
        CHECK (semester_number > 0),

    CONSTRAINT uq_curriculum_course
        UNIQUE (curriculum_id, course_id)
);

CREATE TABLE course_prerequisites (
    course_id UUID NOT NULL,
    prerequisite_course_id UUID NOT NULL,

    PRIMARY KEY (course_id, prerequisite_course_id),

    CONSTRAINT fk_course_prerequisites_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_course_prerequisites_prerequisite
        FOREIGN KEY (prerequisite_course_id)
        REFERENCES courses(course_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_no_self_prerequisite
        CHECK (course_id <> prerequisite_course_id)
);

-- ============================================================
-- PERSONAS ACADÉMICAS
-- Estudiantes, docentes y personal administrativo
-- ============================================================

CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    program_id UUID NOT NULL,
    curriculum_id UUID,
    student_code VARCHAR(50) NOT NULL UNIQUE,
    document_number VARCHAR(50) UNIQUE,
    birth_date DATE,
    address VARCHAR(255),
    phone VARCHAR(30),
    admission_date DATE,
    current_semester INT DEFAULT 1,
    status academic_person_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_students_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_students_program
        FOREIGN KEY (program_id)
        REFERENCES programs(program_id),

    CONSTRAINT fk_students_curriculum
        FOREIGN KEY (curriculum_id)
        REFERENCES curricula(curriculum_id),

    CONSTRAINT chk_student_semester
        CHECK (current_semester IS NULL OR current_semester > 0)
);

CREATE TABLE teachers (
    teacher_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    faculty_id UUID,
    teacher_code VARCHAR(50) NOT NULL UNIQUE,
    document_number VARCHAR(50) UNIQUE,
    specialty VARCHAR(150),
    academic_degree VARCHAR(150),
    hire_date DATE,
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_teachers_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_teachers_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES faculties(faculty_id)
);

CREATE TABLE administrative_staff (
    staff_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    staff_code VARCHAR(50) NOT NULL UNIQUE,
    department_name VARCHAR(150),
    position VARCHAR(150),
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_staff_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- ============================================================
-- PERIODOS ACADÉMICOS
-- ============================================================

CREATE TABLE academic_periods (
    academic_period_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    enrollment_start_date DATE,
    enrollment_end_date DATE,
    grading_start_date DATE,
    grading_end_date DATE,
    status period_status NOT NULL DEFAULT 'planned',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_period_dates
        CHECK (start_date < end_date),

    CONSTRAINT chk_enrollment_dates
        CHECK (
            enrollment_start_date IS NULL
            OR enrollment_end_date IS NULL
            OR enrollment_start_date <= enrollment_end_date
        ),

    CONSTRAINT chk_grading_dates
        CHECK (
            grading_start_date IS NULL
            OR grading_end_date IS NULL
            OR grading_start_date <= grading_end_date
        )
);

-- ============================================================
-- AULAS, PARALELOS Y HORARIOS
-- ============================================================

CREATE TABLE classrooms (
    classroom_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100),
    capacity INT NOT NULL DEFAULT 0,
    location VARCHAR(150),
    status general_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_classroom_capacity
        CHECK (capacity >= 0)
);

CREATE TABLE course_sections (
    course_section_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL,
    academic_period_id UUID NOT NULL,
    teacher_id UUID,
    section_code VARCHAR(30) NOT NULL,
    modality course_modality NOT NULL DEFAULT 'onsite',
    capacity INT NOT NULL,
    enrolled_count INT NOT NULL DEFAULT 0,
    virtual_link TEXT,
    status section_status NOT NULL DEFAULT 'planned',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_course_sections_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id),

    CONSTRAINT fk_course_sections_period
        FOREIGN KEY (academic_period_id)
        REFERENCES academic_periods(academic_period_id),

    CONSTRAINT fk_course_sections_teacher
        FOREIGN KEY (teacher_id)
        REFERENCES teachers(teacher_id),

    CONSTRAINT chk_section_capacity
        CHECK (capacity > 0),

    CONSTRAINT chk_enrolled_count
        CHECK (enrolled_count >= 0),

    CONSTRAINT uq_course_section_period
        UNIQUE (course_id, academic_period_id, section_code)
);

CREATE TABLE section_schedules (
    section_schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_section_id UUID NOT NULL,
    classroom_id UUID,
    day_of_week SMALLINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_section_schedules_section
        FOREIGN KEY (course_section_id)
        REFERENCES course_sections(course_section_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_section_schedules_classroom
        FOREIGN KEY (classroom_id)
        REFERENCES classrooms(classroom_id),

    CONSTRAINT chk_day_of_week
        CHECK (day_of_week BETWEEN 1 AND 7),

    CONSTRAINT chk_schedule_time
        CHECK (start_time < end_time)
);

-- ============================================================
-- MATRÍCULAS
-- ============================================================

CREATE TABLE enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    academic_period_id UUID NOT NULL,
    enrollment_number VARCHAR(50) NOT NULL UNIQUE,
    status enrollment_status NOT NULL DEFAULT 'draft',
    submitted_at TIMESTAMP,
    approved_by UUID,
    approved_at TIMESTAMP,
    observations TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id),

    CONSTRAINT fk_enrollments_period
        FOREIGN KEY (academic_period_id)
        REFERENCES academic_periods(academic_period_id),

    CONSTRAINT fk_enrollments_approved_by
        FOREIGN KEY (approved_by)
        REFERENCES users(user_id),

    CONSTRAINT uq_student_period_enrollment
        UNIQUE (student_id, academic_period_id)
);

CREATE TABLE enrollment_courses (
    enrollment_course_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL,
    course_section_id UUID NOT NULL,
    status enrollment_course_status NOT NULL DEFAULT 'enrolled',
    final_grade NUMERIC(5,2),
    final_observation TEXT,
    withdrawn_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_enrollment_courses_enrollment
        FOREIGN KEY (enrollment_id)
        REFERENCES enrollments(enrollment_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_enrollment_courses_section
        FOREIGN KEY (course_section_id)
        REFERENCES course_sections(course_section_id),

    CONSTRAINT chk_final_grade
        CHECK (final_grade IS NULL OR final_grade BETWEEN 0 AND 100),

    CONSTRAINT uq_enrollment_section
        UNIQUE (enrollment_id, course_section_id)
);

-- ============================================================
-- CALIFICACIONES
-- ============================================================

CREATE TABLE grade_items (
    grade_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_section_id UUID NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    weight NUMERIC(5,2) NOT NULL,
    max_score NUMERIC(5,2) NOT NULL DEFAULT 100,
    due_date DATE,
    order_index INT DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_grade_items_section
        FOREIGN KEY (course_section_id)
        REFERENCES course_sections(course_section_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_grade_item_weight
        CHECK (weight > 0 AND weight <= 100),

    CONSTRAINT chk_grade_item_max_score
        CHECK (max_score > 0),

    CONSTRAINT uq_grade_item_section_name
        UNIQUE (course_section_id, name)
);

CREATE TABLE grades (
    grade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_course_id UUID NOT NULL,
    grade_item_id UUID NOT NULL,
    score NUMERIC(5,2) NOT NULL,
    feedback TEXT,
    registered_by UUID NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_grades_enrollment_course
        FOREIGN KEY (enrollment_course_id)
        REFERENCES enrollment_courses(enrollment_course_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_grades_grade_item
        FOREIGN KEY (grade_item_id)
        REFERENCES grade_items(grade_item_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_grades_registered_by
        FOREIGN KEY (registered_by)
        REFERENCES users(user_id),

    CONSTRAINT chk_grade_score
        CHECK (score BETWEEN 0 AND 100),

    CONSTRAINT uq_grade_per_item
        UNIQUE (enrollment_course_id, grade_item_id)
);

-- ============================================================
-- ASISTENCIA
-- ============================================================

CREATE TABLE attendance_sessions (
    attendance_session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_section_id UUID NOT NULL,
    class_date DATE NOT NULL,
    topic VARCHAR(255),
    created_by UUID,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_attendance_sessions_section
        FOREIGN KEY (course_section_id)
        REFERENCES course_sections(course_section_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_attendance_sessions_created_by
        FOREIGN KEY (created_by)
        REFERENCES users(user_id),

    CONSTRAINT uq_attendance_session
        UNIQUE (course_section_id, class_date)
);

CREATE TABLE attendance_records (
    attendance_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_session_id UUID NOT NULL,
    enrollment_course_id UUID NOT NULL,
    status attendance_status NOT NULL DEFAULT 'present',
    observation TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_attendance_records_session
        FOREIGN KEY (attendance_session_id)
        REFERENCES attendance_sessions(attendance_session_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_attendance_records_enrollment_course
        FOREIGN KEY (enrollment_course_id)
        REFERENCES enrollment_courses(enrollment_course_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_attendance_record
        UNIQUE (attendance_session_id, enrollment_course_id)
);

-- ============================================================
-- SOLICITUDES ADMINISTRATIVAS
-- ============================================================

CREATE TABLE academic_requests (
    academic_request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    request_type request_type NOT NULL,
    enrollment_id UUID,
    enrollment_course_id UUID,
    course_section_id UUID,
    description TEXT NOT NULL,
    status request_status NOT NULL DEFAULT 'pending',
    reviewed_by UUID,
    reviewed_at TIMESTAMP,
    response TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_academic_requests_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id),

    CONSTRAINT fk_academic_requests_enrollment
        FOREIGN KEY (enrollment_id)
        REFERENCES enrollments(enrollment_id),

    CONSTRAINT fk_academic_requests_enrollment_course
        FOREIGN KEY (enrollment_course_id)
        REFERENCES enrollment_courses(enrollment_course_id),

    CONSTRAINT fk_academic_requests_section
        FOREIGN KEY (course_section_id)
        REFERENCES course_sections(course_section_id),

    CONSTRAINT fk_academic_requests_reviewed_by
        FOREIGN KEY (reviewed_by)
        REFERENCES users(user_id)
);

-- ============================================================
-- DOCUMENTOS ESTUDIANTILES
-- ============================================================

CREATE TABLE student_documents (
    student_document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255),
    file_url TEXT NOT NULL,
    status document_status NOT NULL DEFAULT 'pending',
    reviewed_by UUID,
    reviewed_at TIMESTAMP,
    observation TEXT,
    uploaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_student_documents_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_student_documents_reviewed_by
        FOREIGN KEY (reviewed_by)
        REFERENCES users(user_id)
);

-- ============================================================
-- NOTIFICACIONES
-- ============================================================

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    status notification_status NOT NULL DEFAULT 'unread',
    read_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- ============================================================
-- AUDITORÍA
-- ============================================================

CREATE TABLE audit_logs (
    audit_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID,
    action VARCHAR(100) NOT NULL,
    entity_name VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_audit_logs_actor
        FOREIGN KEY (actor_user_id)
        REFERENCES users(user_id)
);

-- ============================================================
-- TRIGGERS updated_at
-- ============================================================

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'users',
        'roles',
        'permissions',
        'faculties',
        'programs',
        'curricula',
        'courses',
        'students',
        'teachers',
        'administrative_staff',
        'academic_periods',
        'classrooms',
        'course_sections',
        'enrollments',
        'enrollment_courses',
        'grade_items',
        'grades',
        'attendance_sessions',
        'attendance_records',
        'academic_requests',
        'student_documents',
        'notifications'
    ]
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON academic.%I',
            'trg_' || tbl || '_updated_at',
            tbl
        );

        EXECUTE format(
            'CREATE TRIGGER %I
             BEFORE UPDATE ON academic.%I
             FOR EACH ROW
             EXECUTE FUNCTION academic.set_updated_at()',
            'trg_' || tbl || '_updated_at',
            tbl
        );
    END LOOP;
END $$;

-- ============================================================
-- FUNCIÓN PARA ACTUALIZAR enrolled_count
-- ============================================================

CREATE OR REPLACE FUNCTION academic.refresh_section_enrolled_count(p_course_section_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE academic.course_sections cs
    SET enrolled_count = (
        SELECT COUNT(*)
        FROM academic.enrollment_courses ec
        INNER JOIN academic.enrollments e
            ON e.enrollment_id = ec.enrollment_id
        WHERE ec.course_section_id = p_course_section_id
          AND ec.status = 'enrolled'
          AND e.status IN ('pending', 'approved')
    )
    WHERE cs.course_section_id = p_course_section_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION academic.trg_refresh_section_enrolled_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM academic.refresh_section_enrolled_count(NEW.course_section_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM academic.refresh_section_enrolled_count(NEW.course_section_id);

        IF OLD.course_section_id IS DISTINCT FROM NEW.course_section_id THEN
            PERFORM academic.refresh_section_enrolled_count(OLD.course_section_id);
        END IF;

        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM academic.refresh_section_enrolled_count(OLD.course_section_id);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enrollment_courses_refresh_count ON academic.enrollment_courses;

CREATE TRIGGER trg_enrollment_courses_refresh_count
AFTER INSERT OR UPDATE OR DELETE ON academic.enrollment_courses
FOR EACH ROW
EXECUTE FUNCTION academic.trg_refresh_section_enrolled_count();

-- ============================================================
-- ÍNDICES
-- ============================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

CREATE INDEX idx_students_user ON students(user_id);
CREATE INDEX idx_students_program ON students(program_id);
CREATE INDEX idx_students_status ON students(status);

CREATE INDEX idx_teachers_user ON teachers(user_id);
CREATE INDEX idx_teachers_faculty ON teachers(faculty_id);

CREATE INDEX idx_programs_faculty ON programs(faculty_id);
CREATE INDEX idx_curricula_program ON curricula(program_id);
CREATE INDEX idx_curriculum_courses_curriculum ON curriculum_courses(curriculum_id);
CREATE INDEX idx_curriculum_courses_course ON curriculum_courses(course_id);

CREATE INDEX idx_courses_code ON courses(code);
CREATE INDEX idx_course_sections_course ON course_sections(course_id);
CREATE INDEX idx_course_sections_period ON course_sections(academic_period_id);
CREATE INDEX idx_course_sections_teacher ON course_sections(teacher_id);
CREATE INDEX idx_course_sections_status ON course_sections(status);

CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_period ON enrollments(academic_period_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

CREATE INDEX idx_enrollment_courses_enrollment ON enrollment_courses(enrollment_id);
CREATE INDEX idx_enrollment_courses_section ON enrollment_courses(course_section_id);
CREATE INDEX idx_enrollment_courses_status ON enrollment_courses(status);

CREATE INDEX idx_grade_items_section ON grade_items(course_section_id);
CREATE INDEX idx_grades_enrollment_course ON grades(enrollment_course_id);
CREATE INDEX idx_grades_grade_item ON grades(grade_item_id);

CREATE INDEX idx_attendance_sessions_section ON attendance_sessions(course_section_id);
CREATE INDEX idx_attendance_records_session ON attendance_records(attendance_session_id);
CREATE INDEX idx_attendance_records_enrollment_course ON attendance_records(enrollment_course_id);

CREATE INDEX idx_academic_requests_student ON academic_requests(student_id);
CREATE INDEX idx_academic_requests_status ON academic_requests(status);
CREATE INDEX idx_academic_requests_type ON academic_requests(request_type);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);

CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_name, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

CREATE OR REPLACE VIEW v_student_enrollments AS
SELECT
    e.enrollment_id,
    e.enrollment_number,
    e.status AS enrollment_status,
    e.created_at AS enrollment_created_at,
    s.student_id,
    s.student_code,
    u.full_name AS student_name,
    u.email AS student_email,
    ap.academic_period_id,
    ap.code AS academic_period_code,
    ap.name AS academic_period_name,
    p.program_id,
    p.name AS program_name
FROM enrollments e
INNER JOIN students s
    ON s.student_id = e.student_id
INNER JOIN users u
    ON u.user_id = s.user_id
INNER JOIN academic_periods ap
    ON ap.academic_period_id = e.academic_period_id
INNER JOIN programs p
    ON p.program_id = s.program_id;

CREATE OR REPLACE VIEW v_course_sections_detail AS
SELECT
    cs.course_section_id,
    c.code AS course_code,
    c.name AS course_name,
    cs.section_code,
    cs.modality,
    cs.capacity,
    cs.enrolled_count,
    cs.status AS section_status,
    ap.code AS academic_period_code,
    ap.name AS academic_period_name,
    tu.full_name AS teacher_name
FROM course_sections cs
INNER JOIN courses c
    ON c.course_id = cs.course_id
INNER JOIN academic_periods ap
    ON ap.academic_period_id = cs.academic_period_id
LEFT JOIN teachers t
    ON t.teacher_id = cs.teacher_id
LEFT JOIN users tu
    ON tu.user_id = t.user_id;

CREATE OR REPLACE VIEW v_student_grades AS
SELECT
    s.student_id,
    s.student_code,
    u.full_name AS student_name,
    e.enrollment_id,
    ap.code AS academic_period_code,
    c.code AS course_code,
    c.name AS course_name,
    cs.section_code,
    gi.name AS grade_item_name,
    gi.weight,
    g.score,
    ec.final_grade
FROM grades g
INNER JOIN grade_items gi
    ON gi.grade_item_id = g.grade_item_id
INNER JOIN enrollment_courses ec
    ON ec.enrollment_course_id = g.enrollment_course_id
INNER JOIN enrollments e
    ON e.enrollment_id = ec.enrollment_id
INNER JOIN students s
    ON s.student_id = e.student_id
INNER JOIN users u
    ON u.user_id = s.user_id
INNER JOIN course_sections cs
    ON cs.course_section_id = ec.course_section_id
INNER JOIN courses c
    ON c.course_id = cs.course_id
INNER JOIN academic_periods ap
    ON ap.academic_period_id = e.academic_period_id;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

INSERT INTO roles (name, description)
VALUES
    ('admin', 'Administrador general del sistema'),
    ('student', 'Estudiante'),
    ('teacher', 'Docente'),
    ('secretary', 'Secretaría académica'),
    ('coordinator', 'Coordinador académico')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (code, description)
VALUES
    ('users.manage', 'Gestionar usuarios'),
    ('roles.manage', 'Gestionar roles y permisos'),
    ('students.manage', 'Gestionar estudiantes'),
    ('teachers.manage', 'Gestionar docentes'),
    ('programs.manage', 'Gestionar carreras'),
    ('courses.manage', 'Gestionar cursos'),
    ('periods.manage', 'Gestionar periodos académicos'),
    ('sections.manage', 'Gestionar paralelos'),
    ('enrollments.manage', 'Gestionar matrículas'),
    ('grades.manage', 'Gestionar calificaciones'),
    ('attendance.manage', 'Gestionar asistencia'),
    ('requests.manage', 'Gestionar solicitudes académicas'),
    ('reports.view', 'Ver reportes')
ON CONFLICT (code) DO NOTHING;

-- Asignar todos los permisos al rol admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'admin'
ON CONFLICT DO NOTHING;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
