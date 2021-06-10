--tabla instructor--
CREATE SEQUENCE escuela_danza.escuela_danza_id_instructor_seq;
CREATE TABLE escuela_danza.instructor(
	id_instructor smallint NOT NULL DEFAULT 
	nextval('escuela_danza.escuela_danza_id_instructor_seq'::regclass),
	nombre_instructor varchar(50),
	apellido_mat_instructor varchar(50),
	apellido_pat_instructor varchar(50),
	fecha_nac_instructor date,
	CONSTRAINT pk_id_instructor PRIMARY KEY (id_instructor)
	WITH (FILLFACTOR = 10)
	USING INDEX TABLESPACE pg_default

)
TABLESPACE pg_default;
ALTER TABLE escuela_danza.instructor OWNER TO postgres;

--tabla alumno--
CREATE SEQUENCE escuela_danza.escuela_danza_id_alumno_seq;
CREATE TABLE escuela_danza.alumno(
	id_alumno smallint NOT NULL DEFAULT 
	nextval('escuela_danza.escuela_danza_id_alumno_seq'::regclass),
	nombre_alumno varchar(50),
	apellido_mat_alumno varchar(50),
	apellido_pat_alumno varchar(50),
	fecha_nac_alumno date,
	CONSTRAINT pk_id_alumno PRIMARY KEY (id_alumno)

)
TABLESPACE pg_default;
ALTER TABLE escuela_danza.alumno OWNER TO postgres;

--tabla clase--
CREATE SEQUENCE escuela_danza.escuela_danza_id_clase_seq;
CREATE TABLE escuela_danza.clase(
	id_clase smallint NOT NULL DEFAULT 
	nextval('escuela_danza.escuela_danza_id_clase_seq'::regclass),
	nombre_clase varchar(50),
	hora_clase time,
	lugares_disponibles smallint,
	id_instructor smallint NOT NULL,
	CONSTRAINT pk_id_clase PRIMARY KEY (id_clase)
	WITH (FILLFACTOR = 10)
	USING INDEX TABLESPACE pg_default

)
TABLESPACE pg_default;
ALTER TABLE escuela_danza.clase OWNER TO postgres;

--tabla clase alumno--
CREATE TABLE escuela_danza.clase_alumno(
	id_alumno smallint,
	id_clase smallint,
	CONSTRAINT clase_alumno_pk PRIMARY KEY (id_alumno,id_clase)

)
TABLESPACE pg_default;
ALTER TABLE escuela_danza.clase_alumno OWNER TO postgres;

--relacion maestro clase-
ALTER TABLE escuela_danza.clase ADD CONSTRAINT instructor FOREIGN KEY (id_instructor)
REFERENCES escuela_danza.instructor (id_instructor) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;

--relacion clase clase_alumno--
ALTER TABLE escuela_danza.clase_alumno ADD CONSTRAINT clase_fk FOREIGN KEY (id_clase)
REFERENCES escuela_danza.clase (id_clase) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;

--relacion alumno clase_alumno--
ALTER TABLE escuela_danza.clase_alumno ADD CONSTRAINT alumno FOREIGN KEY (id_alumno)
REFERENCES escuela_danza.alumno (id_alumno) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;

--FUNCIONES--

--agregar instructor--
CREATE OR REPLACE FUNCTION escuela_danza.agregar_instructor(
inombre VARCHAR(50),iapellidomat VARCHAR (50),iapellidopat VARCHAR (50),ifechanac DATE) RETURNS void AS $$
BEGIN
	INSERT INTO escuela_danza.instructor(
	nombre_instructor, apellido_mat_instructor, apellido_pat_instructor, fecha_nac_instructor)
	VALUES (inombre, iapellidomat, iapellidopat, ifechanac);
END
$$ LANGUAGE plpgsql;

select escuela_danza.agregar_instructor('Ana','López','Espinosa','1997-01-10');

--agregar alumno--
CREATE OR REPLACE FUNCTION escuela_danza.agregar_alumno(
anombre VARCHAR(50),aapellidomat VARCHAR (50),aapellidopat VARCHAR (50),afechanac DATE) RETURNS void AS $$
BEGIN
	INSERT INTO escuela_danza.alumno(
	nombre_alumno, apellido_mat_alumno, apellido_pat_alumno, fecha_nac_alumno)
	VALUES (anombre, aapellidomat,aapellidopat,afechanac);
END
$$ LANGUAGE plpgsql;

select escuela_danza.agregar_alumno('Diana','González','Flores','1998-11-05');

--agregar clase--
CREATE OR REPLACE FUNCTION escuela_danza.agregar_clase(
cnombre VARCHAR(50),hora TIME,lugares_dis SMALLINT, instructor SMALLINT ) RETURNS void AS $$
BEGIN
	INSERT INTO escuela_danza.clase(
	nombre_clase, hora_clase, lugares_disponibles, id_instructor)
	VALUES (cnombre, hora, lugares_dis, instructor);
END
$$ LANGUAGE plpgsql;

select escuela_danza.agregar_clase('Contemp','15:00',10::smallint,1::smallint);

--TRIGGER para validar hora en tabla clase--
CREATE OR REPLACE FUNCTION escuela_danza.valida_hora()
RETURNS trigger
LANGUAGE 'plpgsql'
COST 100
VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
vhora TIME:='00:00';
reg RECORD;
bandera_disp BIT:=0;
bandera_horario BIT:=0;
bandera_hExacta BIT:=0;
minutos integer:=0;
BEGIN
	IF(TG_OP='INSERT') THEN
		FOR REG IN SELECT hora_clase FROM escuela_danza.clase LOOP
			vhora:= reg.hora_clase;
			IF (vhora=NEW.hora_clase) THEN
				bandera_disp:=1;
			END IF;	
		END LOOP;
		
		IF (bandera_disp=1::BIT) THEN
			raise notice 'La hora esta ocupada por otra clase';
		END IF;
		
		IF (NEW.hora_clase < '08:00' OR NEW.hora_clase > '19:00' ) THEN
			bandera_horario:=1;
		END IF;
		
		IF (bandera_horario=1::BIT) THEN
			raise notice 'La hora se encuentra fuera del horario de la escuela';
		END IF;
		
		minutos:=extract (minute from NEW.hora_clase);
		
		IF minutos!=0 THEN
			bandera_hExacta:=1;
		END IF;
		
		IF (bandera_hExacta=1::BIT) THEN
			raise notice 'La hora debe ser exacta, sin minutos';
		END IF;
		
		IF (bandera_disp=0::BIT AND bandera_horario=0::BIT AND bandera_hExacta=0::BIT) THEN
			RETURN NEW;
		END IF;
	END IF;
	RETURN NULL;
END;$BODY$;

--Asociación de Trigger en la tabla clase--
CREATE TRIGGER vhoraClase
	BEFORE INSERT
	ON escuela_danza.clase
	FOR EACH ROW
	EXECUTE PROCEDURE escuela_danza.valida_hora();

COMMENT ON TRIGGER vhoraClase on escuela_danza.clase
	IS 'Trigger que valida que la hora de la clase este disponible';

--Inscribir alumno a clase--
CREATE OR REPLACE FUNCTION escuela_danza.inscribir_alumnoAclase(
id_alumnoi SMALLINT,id_clasei SMALLINT ) RETURNS void AS $$
BEGIN
	INSERT INTO escuela_danza.clase_alumno(
	id_alumno, id_clase)
	VALUES (id_alumnoi,id_clasei);
END
$$ LANGUAGE plpgsql;

select escuela_danza.inscribir_alumnoAclase(1::SMALLINT,2::SMALLINT);

--Trigger para validar inscripciones--
CREATE OR REPLACE FUNCTION escuela_danza.valida_inscripcion()
RETURNS trigger
LANGUAGE 'plpgsql'
COST 100
VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
lugares integer:=0;
BEGIN
	IF(TG_OP='INSERT') THEN
		SELECT lugares_disponibles into lugares	FROM escuela_danza.clase
		WHERE id_clase = NEW.id_clase;
		IF lugares>0 THEN
			UPDATE escuela_danza.clase
			SET lugares_disponibles=lugares_disponibles-1
			WHERE id_clase=NEW.id_clase;
			RETURN NEW;
		ELSE
			raise notice 'No hay lugares disponibles en esta clase';
		END IF;
	END IF;
	RETURN NULL;
END;$BODY$;

--Asociación de Trigger en la tabla clase_alumno--
CREATE TRIGGER vinscripcion
	BEFORE INSERT
	ON escuela_danza.clase_alumno
	FOR EACH ROW
	EXECUTE PROCEDURE escuela_danza.valida_inscripcion();

COMMENT ON TRIGGER vinscripcion on escuela_danza.clase_alumno
	IS 'Trigger que valida que la inscripción de alumnos a las clases';

--Vista instructores--
CREATE OR REPLACE VIEW escuela_danza.v_instructores
AS
SELECT id_instructor as "Id Instructor",
CONCAT(nombre_instructor, ' ', apellido_mat_instructor, ' ', apellido_pat_instructor) as "Nombre Completo",
fecha_nac_instructor as "Fecha de nacimiento"
FROM escuela_danza.instructor;

SELECT * FROM escuela_danza.v_instructores;

--Vista alumnos--
CREATE OR REPLACE VIEW escuela_danza.v_alumnos
AS
SELECT id_alumno as "Id Alumno",
CONCAT(nombre_alumno, ' ', apellido_mat_alumno, ' ', apellido_pat_alumno) as "Nombre Completo",
fecha_nac_alumno as "Fecha de nacimiento"
FROM escuela_danza.alumno;

SELECT * FROM escuela_danza.v_alumnos;

--Vista clases--
CREATE OR REPLACE VIEW escuela_danza.v_clases
AS
SELECT nombre_clase as "Clase",
hora_clase as "Hora",
CONCAT(instructor.nombre_instructor, ' ', instructor.apellido_mat_instructor, ' ', instructor.apellido_pat_instructor) as "Instructor",
lugares_disponibles as "Lugares Disponibles"
FROM escuela_danza.clase
INNER JOIN escuela_danza.instructor
ON clase.id_instructor = instructor.id_instructor 
ORDER BY hora_clase;

SELECT * FROM escuela_danza.v_clases;

--Vista inscripciones--
CREATE OR REPLACE VIEW escuela_danza.v_clasesInscritasAlumno
AS
SELECT clase_alumno.id_alumno as "Id Alumno",
CONCAT(alumno.nombre_alumno, ' ', alumno.apellido_mat_alumno, ' ', alumno.apellido_pat_alumno) as "Nombre Completo",
clase.nombre_clase as "Clase",
clase.hora_clase as "Hora",
CONCAT(instructor.nombre_instructor, ' ', instructor.apellido_mat_instructor, ' ', instructor.apellido_pat_instructor) as "Instructor"
FROM escuela_danza.clase_alumno
INNER JOIN escuela_danza.alumno
ON clase_alumno.id_alumno = alumno.id_alumno
INNER JOIN escuela_danza.clase
ON clase_alumno.id_clase = clase.id_clase
INNER JOIN escuela_danza.instructor
ON clase.id_instructor = instructor.id_instructor
ORDER BY clase_alumno.id_alumno,clase.hora_clase;

SELECT * FROM escuela_danza.v_clases;
SELECT * FROM escuela_danza.v_clasesInscritasAlumno where "Id Alumno"=1;
