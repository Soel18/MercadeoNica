-- ============================================================
-- BASE DE DATOS: MANTENIMIENTO DE MOTOS (Re-ejecutable)
-- SQL Server 2022
-- ============================================================

IF DB_ID('MantenimientoMotos') IS NULL
    CREATE DATABASE MantenimientoMotos;
GO

USE MantenimientoMotos;
GO

-- ============================================================
-- 0. LIMPIEZA (por si ya existen objetos)
-- ============================================================
IF OBJECT_ID('sp_HistorialPorMoto', 'P') IS NOT NULL DROP PROCEDURE sp_HistorialPorMoto;
IF OBJECT_ID('sp_PiezasMasCambiadas', 'P') IS NOT NULL DROP PROCEDURE sp_PiezasMasCambiadas;
IF OBJECT_ID('sp_ProximoMantenimientoGeneral', 'P') IS NOT NULL DROP PROCEDURE sp_ProximoMantenimientoGeneral;
IF OBJECT_ID('sp_AgregarPieza', 'P') IS NOT NULL DROP PROCEDURE sp_AgregarPieza;
IF OBJECT_ID('sp_RegistrarMantenimiento', 'P') IS NOT NULL DROP PROCEDURE sp_RegistrarMantenimiento;
IF OBJECT_ID('vw_MantenimientosCompletos', 'V') IS NOT NULL DROP VIEW vw_MantenimientosCompletos;
IF OBJECT_ID('trg_Piezas_Insert', 'TR') IS NOT NULL DROP TRIGGER trg_Piezas_Insert;
IF OBJECT_ID('DetalleMantenimientoTipo', 'TT') IS NOT NULL DROP TYPE DetalleMantenimientoTipo;
GO

-- ============================================================
-- 1. TABLA: TALLERES
-- ============================================================
IF OBJECT_ID('Talleres', 'U') IS NULL
BEGIN
    CREATE TABLE Talleres (
        IdTaller INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(100) NOT NULL UNIQUE,
        Direccion VARCHAR(200),
        Telefono VARCHAR(30),
        Activo BIT NOT NULL DEFAULT 1
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM Talleres WHERE Nombre = 'Taller Principal')
    INSERT INTO Talleres (Nombre, Direccion) VALUES ('Taller Principal', 'Dirección pendiente');
GO

-- ============================================================
-- 2. TABLA: USUARIOS
-- ============================================================
IF OBJECT_ID('Usuarios', 'U') IS NULL
BEGIN
    CREATE TABLE Usuarios (
        IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(50) NOT NULL UNIQUE,
        PasswordHash VARCHAR(255) NOT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        FechaCreacion DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- ============================================================
-- 3. TABLA: MARCAS DE MOTO
-- ============================================================
IF OBJECT_ID('MarcasMoto', 'U') IS NULL
BEGIN
    CREATE TABLE MarcasMoto (
        IdMarca INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(50) NOT NULL UNIQUE
    );
END
GO

INSERT INTO MarcasMoto (Nombre)
SELECT Nombre FROM (VALUES 
('Honda'), ('Yamaha'), ('Suzuki'), ('Kawasaki'), ('Bajaj'),
('Italika'), ('Vento'), ('KTM'), ('BMW'), ('Otra')
) AS M(Nombre)
WHERE NOT EXISTS (SELECT 1 FROM MarcasMoto WHERE Nombre = M.Nombre);
GO

-- ============================================================
-- 4. TABLA: MODELOS DE MOTO
-- ============================================================
IF OBJECT_ID('ModelosMoto', 'U') IS NULL
BEGIN
    CREATE TABLE ModelosMoto (
        IdModelo INT IDENTITY(1,1) PRIMARY KEY,
        IdMarca INT NOT NULL,
        Nombre VARCHAR(80) NOT NULL,
        CONSTRAINT FK_Modelos_Marcas FOREIGN KEY (IdMarca) REFERENCES MarcasMoto(IdMarca)
    );
END
GO

-- ============================================================
-- 5. TABLA: CATEGORIAS
-- ============================================================
IF OBJECT_ID('Categorias', 'U') IS NULL
BEGIN
    CREATE TABLE Categorias (
        IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(80) NOT NULL UNIQUE
    );
END
GO

INSERT INTO Categorias (Nombre)
SELECT Nombre FROM (VALUES 
('Motor y Sistema de Encendido'), ('Transmisión y Embrague'),
('Sistema Eléctrico y Luces'), ('Sistema de Frenos'),
('Suspensión y Dirección'), ('Ruedas y Neumáticos'),
('Carrocería, Asiento y Accesorios'), ('Filtros y Fluidos'),
('Sistema de Combustible'), ('Instrumentos y Medidores'),
('Arranque'), ('Otros')
) AS C(Nombre)
WHERE NOT EXISTS (SELECT 1 FROM Categorias WHERE Nombre = C.Nombre);
GO

-- ============================================================
-- 6. TABLA: PIEZAS
-- ============================================================
IF OBJECT_ID('Piezas', 'U') IS NULL
BEGIN
    CREATE TABLE Piezas (
        IdPieza INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(100) NOT NULL,
        IdCategoria INT NOT NULL,
        EsPersonalizada BIT NOT NULL DEFAULT 0,
        UsuarioCreacion VARCHAR(50),
        FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Piezas_Categorias FOREIGN KEY (IdCategoria) REFERENCES Categorias(IdCategoria),
        CONSTRAINT UQ_Pieza_Categoria UNIQUE (Nombre, IdCategoria)
    );
END
GO

-- Inserta piezas evitando duplicados
INSERT INTO Piezas (Nombre, IdCategoria)
SELECT P.Nombre, C.IdCategoria
FROM (VALUES 
('Aceite','Filtros y Fluidos'),
('Arandela de la Catarina','Transmisión y Embrague'),
('Arnes (Sistema electrico)','Sistema Eléctrico y Luces'),
('Barra delantera','Suspensión y Dirección'),
('Batería','Sistema Eléctrico y Luces'),
('Bobina','Motor y Sistema de Encendido'),
('Bujía / Chispero','Motor y Sistema de Encendido'),
('Cable del Cluth','Transmisión y Embrague'),
('Cable del velocímetro','Instrumentos y Medidores'),
('Canasta de 73 dientes del cluth','Transmisión y Embrague'),
('Caputa de la bujía','Motor y Sistema de Encendido'),
('Catarina','Transmisión y Embrague'),
('CDI / Cerebro','Motor y Sistema de Encendido'),
('Disco del Cluth','Transmisión y Embrague'),
('Espejos','Carrocería, Asiento y Accesorios'),
('Filtro de aire','Filtros y Fluidos'),
('Filtro de combustible','Sistema de Combustible'),
('Fricciones (Pastilla / Balatas)','Sistema de Frenos'),
('Funda del asiento','Carrocería, Asiento y Accesorios'),
('Llantas delanteras','Ruedas y Neumáticos'),
('Llantas traseras','Ruedas y Neumáticos'),
('Llave de combustible','Sistema de Combustible'),
('Luces delanteras','Sistema Eléctrico y Luces'),
('Luces traseras','Sistema Eléctrico y Luces'),
('Manguera del freno delantero','Sistema de Frenos'),
('Medidor de aceite','Motor y Sistema de Encendido'),
('Mordaza (Caliper / Pinza)','Sistema de Frenos'),
('Neumático delantero','Ruedas y Neumáticos'),
('Neumático trasero','Ruedas y Neumáticos'),
('Overhaul del motor','Motor y Sistema de Encendido'),
('Pata','Carrocería, Asiento y Accesorios'),
('Patada','Arranque'),
('Pescante','Suspensión y Dirección'),
('Pie de vía delantero','Suspensión y Dirección'),
('Pie de vía trasero','Suspensión y Dirección'),
('Rayos','Ruedas y Neumáticos'),
('Rectificador / Regulador','Sistema Eléctrico y Luces'),
('Rines','Ruedas y Neumáticos'),
('Sensor','Sistema Eléctrico y Luces'),
('Sensor de Cambio','Sistema Eléctrico y Luces'),
('Switck del Cluth','Transmisión y Embrague'),
('Switck del encendido de la moto','Sistema Eléctrico y Luces'),
('Tablero','Instrumentos y Medidores'),
('Transmisión','Transmisión y Embrague')
) AS P(Nombre, Cat)
INNER JOIN Categorias C ON C.Nombre = P.Cat
WHERE NOT EXISTS (
    SELECT 1 FROM Piezas WHERE Nombre = P.Nombre AND IdCategoria = C.IdCategoria
);
GO

-- ============================================================
-- 7. TABLA: TIPOS DE MANTENIMIENTO
-- ============================================================
IF OBJECT_ID('TiposMantenimiento', 'U') IS NULL
BEGIN
    CREATE TABLE TiposMantenimiento (
        IdTipoMantenimiento INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(50) NOT NULL UNIQUE,
        Descripcion VARCHAR(200)
    );
END
GO

INSERT INTO TiposMantenimiento (Nombre, Descripcion)
SELECT Nombre, Descripcion FROM (VALUES
('Ajuste', 'Ajuste de piezas sin reemplazo'),
('Cambio de Piezas', 'Reemplazo de una pieza'),
('Mantenimiento', 'Mantenimiento preventivo'),
('Mantenimiento General', 'Revisión completa de la moto'),
('Revisión', 'Inspección visual o diagnóstica')
) AS T(Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM TiposMantenimiento WHERE Nombre = T.Nombre);
GO

-- ============================================================
-- 8. TABLA: MOTOS
-- ============================================================
IF OBJECT_ID('Motos', 'U') IS NULL
BEGIN
    CREATE TABLE Motos (
        IdMoto INT IDENTITY(1,1) PRIMARY KEY,
        IdMarca INT NOT NULL,
        IdModelo INT NULL,
        Color VARCHAR(30),
        Placa VARCHAR(20) NOT NULL UNIQUE,
        Estilo VARCHAR(50),
        Serie VARCHAR(50),
        KilometrajeActual DECIMAL(10,2) NOT NULL DEFAULT 0,
        FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Motos_Marcas FOREIGN KEY (IdMarca) REFERENCES MarcasMoto(IdMarca),
        CONSTRAINT FK_Motos_Modelos FOREIGN KEY (IdModelo) REFERENCES ModelosMoto(IdModelo)
    );
END
GO

-- ============================================================
-- 9. TABLA: MANTENIMIENTOS
-- ============================================================
IF OBJECT_ID('Mantenimientos', 'U') IS NULL
BEGIN
    CREATE TABLE Mantenimientos (
        IdMantenimiento INT IDENTITY(1,1) PRIMARY KEY,
        IdMoto INT NOT NULL,
        IdTaller INT NOT NULL,
        IdTipoMantenimiento INT NOT NULL,
        Fecha DATE NOT NULL DEFAULT GETDATE(),
        CantKm DECIMAL(10,2) NOT NULL,
        Observacion VARCHAR(500),
        CONSTRAINT FK_Mant_Motos FOREIGN KEY (IdMoto) REFERENCES Motos(IdMoto),
        CONSTRAINT FK_Mant_Talleres FOREIGN KEY (IdTaller) REFERENCES Talleres(IdTaller),
        CONSTRAINT FK_Mant_Tipos FOREIGN KEY (IdTipoMantenimiento) REFERENCES TiposMantenimiento(IdTipoMantenimiento)
    );
END
GO

-- ============================================================
-- 10. TABLA: DETALLE DE MANTENIMIENTO
-- ============================================================
IF OBJECT_ID('DetalleMantenimiento', 'U') IS NULL
BEGIN
    CREATE TABLE DetalleMantenimiento (
        IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
        IdMantenimiento INT NOT NULL,
        IdPieza INT NOT NULL,
        MarcaPieza VARCHAR(50),
        Tipo VARCHAR(50),
        Serie VARCHAR(50),
        Cantidad INT NOT NULL DEFAULT 1,
        Observacion VARCHAR(300),
        CONSTRAINT FK_Det_Mant FOREIGN KEY (IdMantenimiento) REFERENCES Mantenimientos(IdMantenimiento) ON DELETE CASCADE,
        CONSTRAINT FK_Det_Pieza FOREIGN KEY (IdPieza) REFERENCES Piezas(IdPieza)
    );
END
GO

-- ============================================================
-- 11. TABLA: AUDITORIA DE PIEZAS
-- ============================================================
IF OBJECT_ID('AuditoriaPiezas', 'U') IS NULL
BEGIN
    CREATE TABLE AuditoriaPiezas (
        IdAuditoria INT IDENTITY(1,1) PRIMARY KEY,
        IdPieza INT NOT NULL,
        Accion VARCHAR(20) NOT NULL,
        Usuario VARCHAR(50),
        Fecha DATETIME NOT NULL DEFAULT GETDATE(),
        Detalle VARCHAR(500),
        CONSTRAINT FK_Aud_Piezas FOREIGN KEY (IdPieza) REFERENCES Piezas(IdPieza)
    );
END
GO

-- ============================================================
-- TYPE (debe ir ANTES del SP que lo usa)
-- ============================================================
IF TYPE_ID('DetalleMantenimientoTipo') IS NOT NULL
    DROP TYPE DetalleMantenimientoTipo;
GO

CREATE TYPE DetalleMantenimientoTipo AS TABLE (
    IdPieza INT,
    MarcaPieza VARCHAR(50),
    Tipo VARCHAR(50),
    Serie VARCHAR(50),
    Cantidad INT,
    Observacion VARCHAR(300)
);
GO

-- ============================================================
-- TRIGGER
-- ============================================================
IF OBJECT_ID('trg_Piezas_Insert', 'TR') IS NOT NULL
    DROP TRIGGER trg_Piezas_Insert;
GO

CREATE TRIGGER trg_Piezas_Insert
ON Piezas
AFTER INSERT
AS
BEGIN
    INSERT INTO AuditoriaPiezas (IdPieza, Accion, Usuario, Detalle)
    SELECT IdPieza, 'INSERT', UsuarioCreacion, 'Pieza agregada: ' + Nombre
    FROM inserted;
END;
GO

-- ============================================================
-- VISTA
-- ============================================================
IF OBJECT_ID('vw_MantenimientosCompletos', 'V') IS NOT NULL
    DROP VIEW vw_MantenimientosCompletos;
GO

CREATE VIEW vw_MantenimientosCompletos AS
SELECT 
    M.IdMantenimiento, MA.Nombre AS MarcaMoto, MO.Nombre AS Modelo,
    MT.Placa, MT.Color, T.Nombre AS Taller, TM.Nombre AS TipoMantenimiento,
    M.Fecha, M.CantKm, M.Observacion,
    C.Nombre AS Categoria, P.Nombre AS Pieza,
    D.MarcaPieza, D.Tipo, D.Serie, D.Cantidad
FROM Mantenimientos M
INNER JOIN Motos MT ON M.IdMoto = MT.IdMoto
INNER JOIN MarcasMoto MA ON MT.IdMarca = MA.IdMarca
LEFT JOIN ModelosMoto MO ON MT.IdModelo = MO.IdModelo
INNER JOIN Talleres T ON M.IdTaller = T.IdTaller
INNER JOIN TiposMantenimiento TM ON M.IdTipoMantenimiento = TM.IdTipoMantenimiento
INNER JOIN DetalleMantenimiento D ON M.IdMantenimiento = D.IdMantenimiento
INNER JOIN Piezas P ON D.IdPieza = P.IdPieza
INNER JOIN Categorias C ON P.IdCategoria = C.IdCategoria;
GO

-- ============================================================
-- SP: Registrar mantenimiento con varias piezas
-- ============================================================
IF OBJECT_ID('sp_RegistrarMantenimiento', 'P') IS NOT NULL
    DROP PROCEDURE sp_RegistrarMantenimiento;
GO

CREATE PROCEDURE sp_RegistrarMantenimiento
    @IdMoto INT,
    @IdTaller INT,
    @IdTipoMantenimiento INT,
    @Fecha DATE,
    @CantKm DECIMAL(10,2),
    @Observacion VARCHAR(500) = NULL,
    @Detalle DetalleMantenimientoTipo READONLY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Mantenimientos (IdMoto, IdTaller, IdTipoMantenimiento, Fecha, CantKm, Observacion)
        VALUES (@IdMoto, @IdTaller, @IdTipoMantenimiento, @Fecha, @CantKm, @Observacion);

        DECLARE @IdMant INT = SCOPE_IDENTITY();

        INSERT INTO DetalleMantenimiento (IdMantenimiento, IdPieza, MarcaPieza, Tipo, Serie, Cantidad, Observacion)
        SELECT @IdMant, IdPieza, MarcaPieza, Tipo, Serie, Cantidad, Observacion
        FROM @Detalle;

        UPDATE Motos
        SET KilometrajeActual = @CantKm
        WHERE IdMoto = @IdMoto AND @CantKm > KilometrajeActual;

        COMMIT;
        SELECT @IdMant AS IdMantenimiento;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- ============================================================
-- SP: Agregar pieza nueva
-- ============================================================
IF OBJECT_ID('sp_AgregarPieza', 'P') IS NOT NULL
    DROP PROCEDURE sp_AgregarPieza;
GO

CREATE PROCEDURE sp_AgregarPieza
    @Nombre VARCHAR(100),
    @IdCategoria INT,
    @Usuario VARCHAR(50) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Piezas WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria)
    BEGIN
        SELECT 'YA_EXISTE' AS Resultado, IdPieza FROM Piezas 
        WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria;
        RETURN;
    END

    INSERT INTO Piezas (Nombre, IdCategoria, EsPersonalizada, UsuarioCreacion)
    VALUES (@Nombre, @IdCategoria, 1, @Usuario);

    SELECT 'OK' AS Resultado, SCOPE_IDENTITY() AS IdPieza;
END;
GO

-- ============================================================
-- SP: Próximo mantenimiento general (km + 1500)
-- ============================================================
IF OBJECT_ID('sp_ProximoMantenimientoGeneral', 'P') IS NOT NULL
    DROP PROCEDURE sp_ProximoMantenimientoGeneral;
GO

CREATE PROCEDURE sp_ProximoMantenimientoGeneral
    @IdMoto INT
AS
BEGIN
    DECLARE @UltimoKm DECIMAL(10,2);
    DECLARE @UltimaFecha DATE;

    SELECT TOP 1 @UltimoKm = M.CantKm, @UltimaFecha = M.Fecha
    FROM Mantenimientos M
    INNER JOIN TiposMantenimiento TM ON M.IdTipoMantenimiento = TM.IdTipoMantenimiento
    WHERE M.IdMoto = @IdMoto AND TM.Nombre = 'Mantenimiento General'
    ORDER BY M.Fecha DESC, M.IdMantenimiento DESC;

    IF @UltimoKm IS NULL
        SELECT @IdMoto AS IdMoto, NULL AS UltimoKm, NULL AS UltimaFecha,
               NULL AS ProximoKm, 'No hay mantenimiento general registrado' AS Mensaje;
    ELSE
        SELECT @IdMoto AS IdMoto, @UltimoKm AS UltimoKm, @UltimaFecha AS UltimaFecha,
               @UltimoKm + 1500 AS ProximoKm,
               'Próximo mantenimiento general a los ' + CAST(@UltimoKm + 1500 AS VARCHAR) + ' km' AS Mensaje;
END;
GO

-- ============================================================
-- SP: Piezas más cambiadas
-- ============================================================
IF OBJECT_ID('sp_PiezasMasCambiadas', 'P') IS NOT NULL
    DROP PROCEDURE sp_PiezasMasCambiadas;
GO

CREATE PROCEDURE sp_PiezasMasCambiadas
AS
BEGIN
    SELECT TOP 20 P.Nombre AS Pieza, C.Nombre AS Categoria, COUNT(*) AS VecesCambiada
    FROM DetalleMantenimiento D
    INNER JOIN Piezas P ON D.IdPieza = P.IdPieza
    INNER JOIN Categorias C ON P.IdCategoria = C.IdCategoria
    GROUP BY P.Nombre, C.Nombre
    ORDER BY VecesCambiada DESC;
END;
GO

-- ============================================================
-- SP: Historial por moto
-- ============================================================
IF OBJECT_ID('sp_HistorialPorMoto', 'P') IS NOT NULL
    DROP PROCEDURE sp_HistorialPorMoto;
GO

CREATE PROCEDURE sp_HistorialPorMoto
    @IdMoto INT
AS
BEGIN
    SELECT M.Fecha, TM.Nombre AS TipoMantenimiento, T.Nombre AS Taller,
           M.CantKm, P.Nombre AS Pieza, D.Cantidad, D.MarcaPieza, M.Observacion
    FROM Mantenimientos M
    INNER JOIN TiposMantenimiento TM ON M.IdTipoMantenimiento = TM.IdTipoMantenimiento
    INNER JOIN Talleres T ON M.IdTaller = T.IdTaller
    INNER JOIN DetalleMantenimiento D ON M.IdMantenimiento = D.IdMantenimiento
    INNER JOIN Piezas P ON D.IdPieza = P.IdPieza
    WHERE M.IdMoto = @IdMoto
    ORDER BY M.Fecha DESC;
END;
GO

PRINT '✅ Base de datos MantenimientoMotos creada/actualizada correctamente.';
GO