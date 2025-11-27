-- · Dimensionamiento y gestión del almacenamiento.
-- · Estrategias de respaldo y recuperación.

--hacemos una auditoria a nivel de servidor
USE master;

CREATE SERVER AUDIT Audit_Donaciones
TO FILE (FILEPATH = 'C:\auditoria\',
MAXSIZE = 50 MB,MAX_FILES = 100)
WITH (QUEUE_DELAY = 1000,
ON_FAILURE = CONTINUE);
GO
ALTER SERVER AUDIT Audit_Donaciones WITH (STATE = ON);


--generamos una auditoria a cada apartado con informacion considerada sensible
USE Donaciones_ONG;

CREATE DATABASE AUDIT SPECIFICATION Audit_DonacionesONG
FOR SERVER AUDIT Audit_Donaciones

    --Para esquema de donaciones
    ADD (INSERT ON SCHEMA::donaciones BY PUBLIC),
    ADD (UPDATE ON SCHEMA::donaciones BY PUBLIC),
    ADD (DELETE ON SCHEMA::donaciones BY PUBLIC),

    -- Para el esquema de personas
    ADD (INSERT ON SCHEMA::personas BY PUBLIC),
    ADD (UPDATE ON SCHEMA::personas BY PUBLIC),
    ADD (DELETE ON SCHEMA::personas BY PUBLIC),

    --Para el esquema de Aporte
    ADD (INSERT ON SCHEMA::Aporte BY PUBLIC),
    ADD (UPDATE ON SCHEMA::Aporte BY PUBLIC),
    ADD (DELETE ON SCHEMA::Aporte BY PUBLIC),

    -- Para esquema proyecto
    ADD (INSERT ON SCHEMA::proyectos BY PUBLIC),
    ADD (UPDATE ON SCHEMA::proyectos BY PUBLIC),
    ADD (DELETE ON SCHEMA::proyectos BY PUBLIC),

    -- Para esquema eventos
    ADD (INSERT ON SCHEMA::eventos BY PUBLIC),
    ADD (UPDATE ON SCHEMA::eventos BY PUBLIC),
    ADD (DELETE ON SCHEMA::eventos BY PUBLIC)
    WITH (STATE = ON);

GO;

