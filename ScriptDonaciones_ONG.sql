USE master
GO

RESTORE DATABASE Donaciones_ONG
FROM DISK = 'C:\backups\Donaciones_ONG.bak'
WITH REPLACE, RECOVERY, STATS = 5;
GO
--------------------------------------------------------------
/*
    Proyecto: Sistema de Donaciones

    Base de datos: Donaciones_ONG
    Creado por: 
		Ana Stephanie Salguero Mojica 00007324
		Valeria Lourdes Iraheta Garcia 00002024
		Fiorella Maria Giron Araujo 00149524
		Andrea Elizabeth Monterroza Rodríguez
    Fecha de creación: 20-11-2025
    Última modificación: 20-11-2025
*/

CREATE DATABASE Donaciones_ONG;
GO

--Base de datos autocontenida
EXEC sp_configure 'contained database authentication', 1;​
RECONFIGURE;
GO

ALTER DATABASE Donaciones_ONG  ​
SET CONTAINMENT = PARTIAL;
GO

USE Donaciones_ONG
GO
--Creacion de tablas

CREATE TABLE donantes (
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(50),
	correo VARCHAR(100),
	telefono VARCHAR(9) --Para esto solo se tomara como numeros tipo '0000-0000'
);
GO

CREATE TABLE recaudaciones_eventos (
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(50),
	descripcion VARCHAR(200)
);
GO

CREATE TABLE donaciones (
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	fecha_donacion DATE,
	id_evento INT DEFAULT NULL,
	id_donante INT NOT NULL,

	FOREIGN KEY (id_donante) REFERENCES donantes(id),
    FOREIGN KEY (id_evento) REFERENCES recaudaciones_eventos(id)
);
GO

CREATE TABLE recursos(
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(50),
	cantidad INT NOT NULL
);
GO

CREATE TABLE donacionesXrecursos(
	PRIMARY KEY (id_donacion, id_recursos),
	id_donacion INT FOREIGN KEY REFERENCES donaciones(id),
	id_recursos INT FOREIGN KEY REFERENCES recursos(id)
);
GO

CREATE TABLE monetario(
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	monto DECIMAL(18,2),
	tipo VARCHAR(20) --los tipos se basaran en efectivo o transferencia
);
GO

CREATE TABLE donacionesXmonetario(
	PRIMARY KEY (id_donacion, id_monetario),
	id_donacion INT FOREIGN KEY REFERENCES donaciones(id),
	id_monetario INT FOREIGN KEY REFERENCES monetario(id)
	
);
GO

CREATE TABLE proyectos(
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(100),
	descripcion VARCHAR(200),
	fecha_realizar DATETIME,
	id_categoria INT NOT NULL,

	FOREIGN KEY(id_categoria) REFERENCES categoria(id)
);

GO
CREATE TABLE donacionesXproyectos (
	PRIMARY KEY (id_donacion, id_proyecto),
	id_donacion INT FOREIGN KEY REFERENCES donaciones(id),
	id_proyecto INT FOREIGN KEY REFERENCES proyectos(id),
);
GO

CREATE TABLE tipo_beneficiario(
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(50)
);
GO

CREATE TABLE beneficiario (
	id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	nombre VARCHAR(50) NOT NULL,
	informacion VARCHAR(200),
	contacto VARCHAR(9),
	id_tipobene INT,
	
	FOREIGN KEY(id_tipobene) REFERENCES tipo_beneficiario(id),
);
GO

CREATE TABLE donacionesXbeneficiario (
	PRIMARY KEY (id_donacion, id_beneficiario),
	id_donacion INT FOREIGN KEY REFERENCES donaciones(id),
	id_beneficiario INT FOREIGN KEY REFERENCES beneficiario(id),
);

--Creacion de usuarios
CREATE USER adminUser WITH PASSWORD = 'adminUser1234';​
CREATE USER readerUser  WITH PASSWORD = 'readerUser1234';​
CREATE USER dbaUser  WITH PASSWORD = 'dbaUser1234';​
GO

--Creacion de roles
CREATE ROLE rol_admin
CREATE ROLE rol_reader
CREATE ROLE rol_mantenimiento

--Asignacion de permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: dbo TO rol_admin;
GRANT SELECT ON SCHEMA :: dbo TO rol_reader;
GRANT ALTER, CONTROL, REFERENCES, VIEW DEFINITION ON SCHEMA :: dbo TO rol_mantenimiento;

--Asignacion de roles
ALTER ROLE rol_admin ADD MEMBER adminUser;
ALTER ROLE rol_reader ADD MEMBER readerUser;
ALTER ROLE rol_mantenimiento ADD MEMBER dbaUser;

--Consultas mediante índices

--Donaciones
CREATE INDEX idx_donaciones_iddonante
ON donaciones(id_donante);

CREATE INDEX idx_donaciones_idevento
ON donaciones(id_evento);

--Donantes
CREATE INDEX idx_donantes_nombre
ON donantes(nombre);

CREATE INDEX idx_donantes_correo
ON donantes(correo);

--Recaudacions_eventos
CREATE INDEX idx_eventos_nombre
ON recaudaciones_eventos(nombre);

--DonacionesxRecursos
CREATE INDEX idx_dxr_iddonacion
ON donacionesXrecursos(id_donacion);

CREATE INDEX idx_dxr_idrecurso
ON donacionesXrecursos(id_recursos);

--DonacionesxMonetario
CREATE INDEX idx_dxm_iddonacion
ON donacionesXmonetario(id_donacion);

CREATE INDEX idx_dxm_idmonetario
ON donacionesXmonetario(id_monetario);

--DonacionesxProyectos
CREATE INDEX idx_dxp_iddonacion
ON donacionesXproyectos(id_donacion);

CREATE INDEX idx_dxp_idproyecto
ON donacionesXproyectos(id_proyecto);

--Donacionesxbeneficiario
CREATE INDEX idx_dxb_iddonacion
ON donacionesXbeneficiario(id_donacion);

CREATE INDEX idx_dxb_idbeneficiario
ON donacionesXbeneficiario(id_beneficiario);

--Proyectos
CREATE INDEX idx_proyectos_idcategoria
ON proyectos(id_categoria);

--Beneficiario
CREATE INDEX idx_beneficiario_tipobene
ON beneficiario(id_tipobene);

CREATE INDEX idx_benef_nombre
ON beneficiario(nombre);

--ANDREA
--Se crearon índices en las columnas utilizadas como 
--claves foráneas y en las columnas usadas comúnmente 
--como criterios de búsqueda. Esto mejora el rendimiento 
--en operaciones JOIN y consultas SELECT, reduciendo 
--la lectura de páginas y acelerando el acceso a los 
--registros

 --Funciones ventana
	--Total de donaciones por donante
	SELECT 
		d.nombre, dn.id,
		SUM(m.monto) OVER (PARTITION BY d.id) AS TotalDonadoPorDonante
	FROM donantes AS d
	JOIN donaciones AS dn 
		ON dn.id_donante = d.id
	JOIN donacionesXmonetario dxm 
		ON dxm.id_donacion = dn.id
	JOIN monetario m 
		ON m.id = dxm.id_monetario;

	--Rank de donantes por cantidad donada
	SELECT *
	FROM (
		SELECT 
			d.nombre,
			SUM(m.monto) AS TotalDonado,
			RANK() OVER (ORDER BY SUM(m.monto) DESC) AS RankingDonantes
		FROM donantes AS d
		JOIN donaciones AS dn 
			ON dn.id_donante = d.id
		JOIN donacionesXmonetario AS dxm 
			ON dxm.id_donacion = dn.id
		JOIN monetario AS m 
			ON m.id = dxm.id_monetario
		GROUP BY d.nombre
	) t;

	--Porcentaje total de donaciones por cada donante 
	--referenta al total de donaciones
	SELECT 
		d.id,
		m.monto,
		FORMAT(m.monto * 100.0 / SUM(m.monto) OVER (),'N2') AS PorcentajeDelTotal
	FROM donaciones dn
	JOIN donacionesXmonetario AS dxm 
		ON dxm.id_donacion = dn.id
	JOIN monetario m 
		ON m.id = dxm.id_monetario
	JOIN donantes AS d 
		ON d.id = dn.id_donante;

--ANDREA
--Se utilizaron funciones ventana como SUM() OVER, 
--COUNT() OVER y RANK() OVER para realizar cálculos agregados 
--sin tener que agrupar toda la tabla. Estas funciones 
--permiten calcular totales, rankings y porcentajes por 
--partición (donante, evento, proyecto) manteniendo la 
--estructura original de la consulta y mejorando el 
--rendimiento comparado con subconsultas anidadas.


SELECT 
    name AS FileName, 
    size/128 AS SizeMB, 
    max_size/128 AS MaxSizeMB,
    physical_name
FROM sys.database_files;


--Migracion e Importacion de datos

	--Importacion de datos desde csv. Ejemplo
	BULK INSERT donantes
	FROM 'C:\import\donantes.csv'
	WITH (
		FIRSTROW = 2,               
		FIELDTERMINATOR = ',',     
		ROWTERMINATOR = '\n',      
		TABLOCK
	);
	GO

	--Migracion de datos desde otra base. Ejemplo
	INSERT INTO donaciones (fecha_donacion, id_evento, id_donante)
	SELECT fecha_donacion, id_evento, id_donante
	FROM ONG_OLD.dbo.donaciones;
	GO

	--Importacion manual de datos. Ejemplo
	INSERT INTO recursos (nombre, cantidad)
	VALUES ('nombre', 1111)

--ANDREA
--Se habilitó la importación de datos provenientes de archivos 
--CSV mediante el asistente de SQL Server y el comando 
--BULK INSERT. También se estableció un proceso de migración 
--entre bases mediante INSERT INTO...SELECT e importacion 
--manual de datos por medio de INSERT INTO...VALUES
