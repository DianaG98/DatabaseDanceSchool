-- agregar instructores --
SELECT escuela_danza.agregar_instructor('Omar','Cruz','Martínez','1985-09-13');

-- vista instructores --
SELECT * FROM escuela_danza.v_instructores;

-- agregar alumno --
SELECT escuela_danza.agregar_alumno('Viridiana','Delgado','Díaz','2002-11-27');

-- vista alumnos --
SELECT * FROM escuela_danza.v_alumnos;

-- agregar clase capacidad,id instruc. --
SELECT escuela_danza.agregar_clase('Ballet','07:00',2::smallint,1::smallint);
SELECT escuela_danza.agregar_clase('Ballet','14:30',2::smallint,1::smallint);
SELECT escuela_danza.agregar_clase('Ballet','14:00',2::smallint,1::smallint);

-- vistas clases --
SELECT * FROM escuela_danza.v_clases;

-- inscribir alumno a clase id alumno, id clase (revisar) --
select escuela_danza.inscribir_alumnoAclase(1::SMALLINT,6::SMALLINT);
select escuela_danza.inscribir_alumnoAclase(2::SMALLINT,6::SMALLINT);
select escuela_danza.inscribir_alumnoAclase(3::SMALLINT,6::SMALLINT);

-- vista inscripciones --
SELECT * FROM escuela_danza.v_clasesInscritasAlumno;
SELECT * FROM escuela_danza.v_clasesInscritasAlumno where "Id Alumno"=1;