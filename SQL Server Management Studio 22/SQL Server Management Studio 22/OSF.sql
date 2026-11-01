/*************************************************************************************
|*                                                                                   *|
|*                          SCRIPT DE LA BASE DE DATOS OSF                           *|
|*                          OLINNE SALES FORCE (OSF)                                 *|
|*                    SISTEMA DE TIENDA ONLINE + GESTION COMERCIAL                   *|
|*                                                                                   *|
|*  AUTORES: SOFIA ELIENAI GUEVARA JARQUIN                                           *|
|*           FRANKLIN OSMAN SALINAS RIVAS                                            *|
|*           HARVIN ULISES GONZALEZ HERRERA                                          *|
|*                                                                                   *|
|*  FECHA: 2026    VERSIÓN: 6.0                                                      *|
|*  MOTOR: Microsoft SQL Server 2022                                                 *|
|*                                                                                   *|
|*  PROPÓSITO ACADÉMICO:                                                             *|
|*  Base de datos relacional que soporta un sistema de tienda online con             *|
|*  gestión comercial. Implementa integridad referencial mediante PRIMARY KEY,       *|
|*  FOREIGN KEY, CHECK, UNIQUE y DEFAULT. Incluye triggers de auditoría y de         *|
|*  alerta de inventario bajo, procedimientos almacenados para la lógica de          *|
|*  negocio y una función escalar auxiliar.                                          *|
|*                                                                                   *|
|*  ===============================================================================  *|
|*  ESTRUCTURA (13 tablas)                                                           *|
|*  ===============================================================================  *|
|*    1.  CustomerCategories   - Niveles de fidelidad y % de descuento (5 filas)     *|
|*    2.  customers            - Clientes con login, teléfono y categoría (soft del) *|
|*    3.  sellers              - Vendedores y administradores (rol ADMIN/VENDEDOR)   *|
|*    4.  ProductCategories    - 40 categorías de productos                          *|
|*    5.  products             - Catálogo con stock y precio (CHECK >= 0 / > 0)      *|
|*    6.  orders               - Cabecera de pedidos (estados y total)               *|
|*    7.  order_details        - Detalle N:M con columna calculada PERSISTED         *|
|*    8.  inventory_movements  - Bitácora ENTRADA/SALIDA/AJUSTE/DEVOLUCION           *|
|*    9.  creditcards          - Tarjetas por cliente (VISA/MC/AMEX/Discover)        *|
|*   10.  invoices             - Facturas vinculadas a pedido y tarjeta              *|
|*   11.  reviews              - Reseñas 1–5 estrellas (sin restricción 1/cliente)   *|
|*   12.  recommendations      - Recomendaciones producto-cliente                    *|
|*   13.  audit_log            - Bitácora protegida contra UPDATE/DELETE             *|
|*                                                                                   *|
|*  ===============================================================================  *|
|*  OBJETOS PROGRAMABLES                                                             *|
|*  ===============================================================================  *|
|*  TRIGGERS:                                                                        *|
|*    - trg_audit_products / _invoices / _customers / _sellers / _order_details      *|
|*    - report_low_inventory      (PRINT si stock < 50)                              *|
|*    - trg_proteger_audit_update / _delete  (bloquean la bitácora)                  *|
|*                                                                                   *|
|*  FUNCIÓN:                                                                         *|
|*    - dbo.FIND_PRODUCT_CATEGORY_ID(nombre) -> INT (-1 si no existe)                *|
|*                                                                                   *|
|*  PROCEDIMIENTOS (por módulo):                                                     *|
|*    Clientes/Vendedores: add_customer, add_cliente_completo, add_seller,           *|
|*                         show_sellers, show_all_customers_in_state                 *|
|*    Catálogo:            Add_Category, Add_Product, Report_Inventory,              *|
|*                         Report_Cards_Expire                                       *|
|*    Pedidos:             find_customer_id, find_product_id, find_order_by_date,    *|
|*                         place_order_full, add_orders, place_order, show_orders,   *|
|*                         report_orders_by_state, report_best_customers,            *|
|*                         find_stingy_customers                                     *|
|*    Facturación:         invoice_customer, calculate_credit_card_fees             *|
|*    Inventario:          Update_Inventory, update_inventory1,                      *|
|*                         register_inventory_movement, report_inventory_movements,  *|
|*                         report_sales_by_seller                                    *|
|*    Reseñas/Recom.:      add_review, buy_or_beware, Recommend_To_Customer,         *|
|*                         List_Recommendations                                      *|
|*    Wrappers:            agregar_detalle_pedido, agregar_recomendacion,            *|
|*                         agregar_movimiento_inventario, agregar_factura,           *|
|*                         agregar_resena                                            *|
|*                                                                                   *|
|*  ===============================================================================  *|
|*  NOTAS DE IMPLEMENTACIÓN                                                          *|
|*  ===============================================================================  *|
|*    - Si la BD existe, el script la elimina (SINGLE_USER + DROP) y la recrea.      *|
|*    - 'phone' es NULL-able en customers y sellers.                                 *|
|*    - customers.active y sellers.active implementan soft delete.                   *|
|*    - Las contraseñas se almacenan tal cual en 'password_hash' (texto plano       *|
|*      en entorno académico; en producción debe usarse un hash real).               *|
|*    - El stock NO se descuenta automáticamente al insertar en order_details;      *|
|*      debe llamarse a Update_Inventory o register_inventory_movement.              *|
|*    - 'reviews' NO restringe 1 reseña por cliente/producto a nivel de BD;         *|
|*      esa validación (si se desea) corresponde a la capa de aplicación.            *|
|*    - Los descuentos por categoría de cliente están modelados en                  *|
|*      CustomerCategories.discount_percentage, pero su aplicación al total         *|
|*      del pedido es responsabilidad de la capa Java, no del script SQL.            *|
|*    - Auditoría íntegramente vía triggers AFTER sobre audit_log.                   *|
|*                                                                                   *|
|*  ===============================================================================  *|
|*  CREDENCIALES DE PRUEBA (texto plano, solo entorno académico)                     *|
|*  ===============================================================================  *|
|*    ADMIN:    admin@mercadeonica.com       / admin123                              *|
|*    VENDEDOR: franklin.v@mercadeonica.com  / vendedor123                           *|
|*    CLIENTE:  franklin@gmail.com           / cliente123                            *|
|*                                                                                   *|
|*  ===============================================================================  *|
|*  HISTORIAL DE VERSIONES                                                           *|
|*  ===============================================================================  *|
|*    v6.0 - Script consolidado; auditoría, inventario y wrappers completos.         *|
|*    v5.1 - Teléfono en clientes y vendedores.                                      *|
|*    v5.0 - Login de clientes; 40 categorías; CustomerCategories con descuentos.    *|
|*    v4.0 - Roles ADMIN/VENDEDOR; order_details; inventario; auditoría.             *|
|*    v1.0 - Versión inicial (clientes, productos, pedidos, reseñas).                *|
|*                                                                                   *|
*************************************************************************************/


USE master;
GO

IF DB_ID('OSF') IS NOT NULL
BEGIN
    ALTER DATABASE OSF SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OSF;
END
GO

CREATE DATABASE OSF;
GO

USE OSF;
GO


/* ============================================================
   PASO 1: CREAR LAS TABLAS
   ============================================================ */

-- TABLA: Categorías de Clientes (NUEVO)
CREATE TABLE CustomerCategories(
  categoryid            INT IDENTITY(1,1) NOT NULL,
  categoryname          VARCHAR(50) NOT NULL,
  discount_percentage   DECIMAL(5,2) NOT NULL DEFAULT 0,
  CONSTRAINT PK_CustomerCategories PRIMARY KEY (categoryid),
  CONSTRAINT UQ_CustomerCategories_Name UNIQUE (categoryname)
);
GO

-- Insertar las 5 categorías por defecto
INSERT INTO CustomerCategories (categoryname, discount_percentage) VALUES 
('Regular', 0.00),
('Bronce', 5.00),
('Plata', 10.00),
('Oro', 15.00),
('Platino', 20.00);
GO

-- TABLA: clientes (con login)
CREATE TABLE customers(
  customerid    INT IDENTITY(1,1) NOT NULL,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(100) NOT NULL,
  city          VARCHAR(50),
  state         VARCHAR(50),
  zip           INT,
  phone         VARCHAR(20) NULL,
  password_hash VARCHAR(255) NULL,
  active        BIT NOT NULL DEFAULT 1,
  debe_cambiar_password BIT NOT NULL DEFAULT 0,
  categoryid    INT NULL,
  CONSTRAINT PK_CUSTOMERS_CUSTOMERID PRIMARY KEY (customerid),
  CONSTRAINT UQ_CUSTOMERS_EMAIL      UNIQUE (email),
  CONSTRAINT CHK_CUSTOMERS_EMAIL_FMT CHECK (email LIKE '%@%.%'),
  CONSTRAINT CHK_CUSTOMERS_ZIP       CHECK (zip BETWEEN 1000 AND 99999),
  CONSTRAINT FK_Customers_CustomerCategories FOREIGN KEY (categoryid) 
      REFERENCES CustomerCategories(categoryid)
);
CREATE INDEX IX_CUSTOMERS_STATE ON customers(state);
CREATE INDEX IX_CUSTOMERS_CITY  ON customers(city);
GO

-- TABLA: vendedores
CREATE TABLE sellers(
  sellerid      INT IDENTITY(1,1) NOT NULL,
  name          VARCHAR(50) NOT NULL,
  email         VARCHAR(50) NOT NULL,
  phone         VARCHAR(20) NULL, -- 🔥 NUEVO
  password_hash VARCHAR(255) NOT NULL,
  role          VARCHAR(15) NOT NULL,
  active        BIT NOT NULL DEFAULT 1,
  created_at    DATETIME2 DEFAULT SYSDATETIME(),
  CONSTRAINT PK_SELLERS_SELLERID   PRIMARY KEY (sellerid),
  CONSTRAINT UQ_SELLERS_EMAIL      UNIQUE (email),
  CONSTRAINT CHK_SELLERS_EMAIL_FMT CHECK (email LIKE '%@%.%'),
  CONSTRAINT CHK_SELLERS_ROLE      CHECK (role IN ('ADMIN','VENDEDOR'))
);
CREATE INDEX IX_SELLERS_ROLE ON sellers(role);
GO

-- TABLA: categorías de productos
CREATE TABLE ProductCategories(
  categoryid    INT IDENTITY(1,1) NOT NULL,
  categoryname  VARCHAR(50) NOT NULL,
  description   VARCHAR(150),
  CONSTRAINT PK_CATEGORIES_CATEGORYID PRIMARY KEY (categoryid),
  CONSTRAINT UQ_CATEGORIES_NAME       UNIQUE (categoryname)
);
CREATE INDEX IX_CATEGORIES_NAME ON ProductCategories(categoryname);
GO

-- TABLA: productos
CREATE TABLE products(
  productid         INT IDENTITY(1,1) NOT NULL,
  productname       VARCHAR(100) NOT NULL,
  availablequantity INT NOT NULL,
  unitprice         DECIMAL(10,2) NOT NULL,
  categoryid        INT,
  CONSTRAINT PK_PRODUCTS_PRODUCTID   PRIMARY KEY (productid),
  CONSTRAINT FK_PRODUCTS_CATEGORIES  FOREIGN KEY (categoryid)
                                     REFERENCES ProductCategories(categoryid),
  CONSTRAINT CHK_PRODUCTS_QUANTITY   CHECK (availablequantity >= 0),
  CONSTRAINT CHK_PRODUCTS_UNITPRICE  CHECK (unitprice > 0)
);
CREATE INDEX IX_PRODUCTS_CATEGORYID ON products(categoryid);
CREATE INDEX IX_PRODUCTS_NAME       ON products(productname);
GO

-- TABLA: pedidos
CREATE TABLE orders(
  orderid      INT IDENTITY(1,1) NOT NULL,
  customerid   INT,
  sellerid     INT NULL,
  orderdate    DATETIME,       
  cc_number    BIGINT NULL,    
  status       VARCHAR(15) NOT NULL DEFAULT 'PENDIENTE',
  total        DECIMAL(10,2) DEFAULT 0,
  CONSTRAINT PK_ORDERS_ORDERID     PRIMARY KEY (orderid),
  CONSTRAINT FK_ORDERS_CUSTOMERS   FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_ORDERS_SELLERS     FOREIGN KEY (sellerid)   REFERENCES sellers(sellerid),
  CONSTRAINT CHK_ORDERS_STATUS     CHECK (status IN ('PENDIENTE','CONFIRMADO','CANCELADO','ENTREGADO'))
);
CREATE INDEX IX_ORDERS_CUSTOMERID ON orders(customerid);
CREATE INDEX IX_ORDERS_SELLERID   ON orders(sellerid);
CREATE INDEX IX_ORDERS_ORDERDATE  ON orders(orderdate);
CREATE INDEX IX_ORDERS_STATUS     ON orders(status);
GO

-- TABLA: detalle_pedido
CREATE TABLE order_details(
  detailid    INT IDENTITY(1,1) NOT NULL,
  orderid     INT NOT NULL,
  productid   INT NOT NULL,
  quantity    INT NOT NULL,
  unitprice   DECIMAL(10,2) NOT NULL,
  subtotal    AS (quantity * unitprice) PERSISTED,
  CONSTRAINT PK_ORDER_DETAILS_DETAILID PRIMARY KEY (detailid),
  CONSTRAINT FK_OD_ORDERS    FOREIGN KEY (orderid)   REFERENCES orders(orderid) ON DELETE CASCADE,
  CONSTRAINT FK_OD_PRODUCTS  FOREIGN KEY (productid) REFERENCES products(productid),
  CONSTRAINT CHK_OD_QUANTITY CHECK (quantity > 0),
  CONSTRAINT CHK_OD_PRICE    CHECK (unitprice > 0)
);
CREATE INDEX IX_OD_ORDERID   ON order_details(orderid);
CREATE INDEX IX_OD_PRODUCTID ON order_details(productid);
GO

-- TABLA: movimientos de inventario
CREATE TABLE inventory_movements(
  movementid    INT IDENTITY(1,1) NOT NULL,
  productid     INT NOT NULL,
  sellerid      INT NULL,
  movement_type VARCHAR(15) NOT NULL,
  quantity      INT NOT NULL,
  reason        VARCHAR(150),
  movement_date DATETIME2 DEFAULT SYSDATETIME(),
  CONSTRAINT PK_INVMOV_ID       PRIMARY KEY (movementid),
  CONSTRAINT FK_INVMOV_PRODUCT  FOREIGN KEY (productid) REFERENCES products(productid),
  CONSTRAINT FK_INVMOV_SELLER   FOREIGN KEY (sellerid)  REFERENCES sellers(sellerid),
  CONSTRAINT CHK_INVMOV_TYPE    CHECK (movement_type IN ('ENTRADA','SALIDA','AJUSTE','DEVOLUCION')),
  CONSTRAINT CHK_INVMOV_QTY     CHECK (quantity <> 0)
);
CREATE INDEX IX_INVMOV_PRODUCT ON inventory_movements(productid);
CREATE INDEX IX_INVMOV_DATE    ON inventory_movements(movement_date);
GO

-- TABLA: tarjetas de crédito
CREATE TABLE creditcards(
  customerID        INT,
  creditcard        BIGINT,
  creditcard_type   VARCHAR(15),
  expiration_year   INT,
  expiration_month  INT,
  CONSTRAINT PK_CREDITCARDS_NUMBER  PRIMARY KEY (creditcard),
  CONSTRAINT FK_CREDITCARDS_CUST    FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT CHK_CC_MONTH           CHECK (expiration_month BETWEEN 1 AND 12),
  CONSTRAINT CHK_CC_YEAR            CHECK (expiration_year BETWEEN 2000 AND 2100),
  CONSTRAINT CHK_CC_TYPE            CHECK (creditcard_type IN ('VISA','MC','AMEX','Discover'))
);
CREATE INDEX IX_CREDITCARDS_CUSTID ON creditcards(customerid);
GO

-- TABLA: facturas
CREATE TABLE invoices(
  invoiceid     INT IDENTITY(1,1) NOT NULL,
  orderid       INT,
  customerid    INT,
  creditcard    BIGINT,
  amount        DECIMAL(10,2),
  CONSTRAINT PK_INVOICES_INVOICEID  PRIMARY KEY (invoiceid),
  CONSTRAINT FK_INVOICES_ORDERS     FOREIGN KEY (orderid)    REFERENCES orders(orderid),
  CONSTRAINT FK_INVOICES_CUSTOMERS  FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_INVOICES_CREDITCARD FOREIGN KEY (creditcard) REFERENCES creditcards(creditcard),
  CONSTRAINT CHK_INVOICES_AMOUNT    CHECK (amount > 0)
);
CREATE INDEX IX_INVOICES_ORDERID    ON invoices(orderid);
CREATE INDEX IX_INVOICES_CUSTOMERID ON invoices(customerid);
GO

-- TABLA: reseñas
CREATE TABLE reviews(
  reviewID        INT IDENTITY(1,1) NOT NULL,
  productID       INT,
  reviewer_email  VARCHAR(50),
  starsgiven      INT,
  review_text     VARCHAR(200),
  CONSTRAINT PK_REVIEWS_REVIEWID    PRIMARY KEY (reviewID),
  CONSTRAINT FK_REVIEWS_PRODUCTS    FOREIGN KEY (productID) REFERENCES products(productID),
  CONSTRAINT CHK_REVIEWS_STARS      CHECK (starsgiven BETWEEN 1 AND 5)
);
CREATE INDEX IX_REVIEWS_PRODUCTID ON reviews(productID);
CREATE INDEX IX_REVIEWS_EMAIL     ON reviews(reviewer_email);
GO

-- TABLA: recomendaciones
CREATE TABLE recommendations(
  recommendationid           INT IDENTITY(1,1) NOT NULL,
  customerid                 INT,
  recommendation_productid   INT,
  CONSTRAINT PK_RECOMMENDATIONS_ID  PRIMARY KEY (recommendationid),
  CONSTRAINT FK_REC_CUSTOMERS       FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_REC_PRODUCTS        FOREIGN KEY (recommendation_productid) REFERENCES products(productid)
);
CREATE INDEX IX_REC_CUSTOMERID ON recommendations(customerid);
GO

-- TABLA: bitácora de auditoría
CREATE TABLE audit_log(
  audit_id      INT IDENTITY(1,1) PRIMARY KEY,
  table_name    VARCHAR(50)  NOT NULL,
  action        VARCHAR(20)  NOT NULL,
  record_id     INT,
  user_name     VARCHAR(50)  DEFAULT SUSER_SNAME(),
  action_date   DATETIME2    DEFAULT SYSDATETIME(),
  old_values    NVARCHAR(MAX),
  new_values    NVARCHAR(MAX),
  CONSTRAINT CHK_AUDIT_ACTION CHECK (action IN ('INSERT','UPDATE','DELETE'))
);
CREATE INDEX IX_AUDIT_TABLE_DATE ON audit_log(table_name, action_date);
CREATE INDEX IX_AUDIT_USER       ON audit_log(user_name);
CREATE INDEX IX_AUDIT_RECORD     ON audit_log(record_id);
GO


/* ============================================================
   PASO 2: CREAR DISPARADORES
   ============================================================ */

CREATE OR ALTER TRIGGER trg_audit_products
ON products AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log(table_name, action, record_id, new_values)
    SELECT 'PRODUCTS', 'INSERT', i.productid,
           'productoid=' + CAST(i.productid AS VARCHAR(10)) +
           ', nombre=' + i.productname +
           ', cantidad=' + CAST(i.availablequantity AS VARCHAR(10)) +
           ', precio=' + CAST(i.unitprice AS VARCHAR(20))
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.productid = i.productid);

    INSERT INTO audit_log(table_name, action, record_id, old_values, new_values)
    SELECT 'PRODUCTS', 'UPDATE', i.productid,
           'productoid=' + CAST(d.productid AS VARCHAR(10)) +
           ', cantidad=' + CAST(d.availablequantity AS VARCHAR(10)) +
           ', precio=' + CAST(d.unitprice AS VARCHAR(20)),
           'productoid=' + CAST(i.productid AS VARCHAR(10)) +
           ', cantidad=' + CAST(i.availablequantity AS VARCHAR(10)) +
           ', precio=' + CAST(i.unitprice AS VARCHAR(20))
    FROM inserted i
    INNER JOIN deleted d ON i.productid = d.productid;

    INSERT INTO audit_log(table_name, action, record_id, old_values)
    SELECT 'PRODUCTS', 'DELETE', d.productid,
           'productoid=' + CAST(d.productid AS VARCHAR(10)) +
           ', nombre=' + d.productname
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.productid = d.productid);
END;
GO

CREATE OR ALTER TRIGGER trg_audit_invoices
ON invoices AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log(table_name, action, record_id, new_values)
    SELECT 'INVOICES', 'INSERT', i.invoiceid, 'monto=' + CAST(i.amount AS VARCHAR(20))
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.invoiceid = i.invoiceid);

    INSERT INTO audit_log(table_name, action, record_id, old_values, new_values)
    SELECT 'INVOICES', 'UPDATE', i.invoiceid,
           'monto=' + CAST(d.amount AS VARCHAR(20)),
           'monto=' + CAST(i.amount AS VARCHAR(20))
    FROM inserted i
    INNER JOIN deleted d ON i.invoiceid = d.invoiceid;

    INSERT INTO audit_log(table_name, action, record_id, old_values)
    SELECT 'INVOICES', 'DELETE', d.invoiceid, 'monto=' + CAST(d.amount AS VARCHAR(20))
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.invoiceid = d.invoiceid);
END;
GO

CREATE OR ALTER TRIGGER trg_audit_customers
ON customers AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log(table_name, action, record_id, new_values)
    SELECT 'CUSTOMERS', 'INSERT', i.customerid,
           'nombre=' + i.name + ', correo=' + i.email
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.customerid = i.customerid);

    INSERT INTO audit_log(table_name, action, record_id, old_values, new_values)
    SELECT 'CUSTOMERS', 'UPDATE', i.customerid,
           'nombre=' + d.name + ', correo=' + d.email,
           'nombre=' + i.name + ', correo=' + i.email
    FROM inserted i
    INNER JOIN deleted d ON i.customerid = d.customerid;

    INSERT INTO audit_log(table_name, action, record_id, old_values)
    SELECT 'CUSTOMERS', 'DELETE', d.customerid,
           'nombre=' + d.name + ', correo=' + d.email
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.customerid = d.customerid);
END;
GO

CREATE OR ALTER TRIGGER trg_audit_sellers
ON sellers AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log(table_name, action, record_id, new_values)
    SELECT 'SELLERS', 'INSERT', i.sellerid,
           'nombre=' + i.name + ', correo=' + i.email + ', rol=' + i.role
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.sellerid = i.sellerid);

    INSERT INTO audit_log(table_name, action, record_id, old_values, new_values)
    SELECT 'SELLERS', 'UPDATE', i.sellerid,
           'rol=' + d.role + ', activo=' + CAST(d.active AS VARCHAR(2)),
           'rol=' + i.role + ', activo=' + CAST(i.active AS VARCHAR(2))
    FROM inserted i
    INNER JOIN deleted d ON i.sellerid = d.sellerid;

    INSERT INTO audit_log(table_name, action, record_id, old_values)
    SELECT 'SELLERS', 'DELETE', d.sellerid,
           'nombre=' + d.name + ', rol=' + d.role
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.sellerid = d.sellerid);
END;
GO

CREATE OR ALTER TRIGGER trg_audit_order_details
ON order_details AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log(table_name, action, record_id, new_values)
    SELECT 'ORDER_DETAILS', 'INSERT', i.detailid,
           'pedidoid=' + CAST(i.orderid AS VARCHAR(10)) +
           ', productoid=' + CAST(i.productid AS VARCHAR(10)) +
           ', cantidad=' + CAST(i.quantity AS VARCHAR(10))
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.detailid = i.detailid);

    INSERT INTO audit_log(table_name, action, record_id, old_values, new_values)
    SELECT 'ORDER_DETAILS', 'UPDATE', i.detailid,
           'cantidad=' + CAST(d.quantity AS VARCHAR(10)),
           'cantidad=' + CAST(i.quantity AS VARCHAR(10))
    FROM inserted i
    INNER JOIN deleted d ON i.detailid = d.detailid;

    INSERT INTO audit_log(table_name, action, record_id, old_values)
    SELECT 'ORDER_DETAILS', 'DELETE', d.detailid,
           'pedidoid=' + CAST(d.orderid AS VARCHAR(10)) +
           ', productoid=' + CAST(d.productid AS VARCHAR(10))
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.detailid = d.detailid);
END;
GO


CREATE OR ALTER TRIGGER report_low_inventory
ON products AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @msg NVARCHAR(MAX) = '';

    SELECT @msg = @msg + '*** ALERTA DE INVENTARIO BAJO ***' + CHAR(13) +
                         'ID del producto: ' + CAST(i.productid AS VARCHAR(10)) + CHAR(13) +
                         'Nombre del producto: ' + i.productname + CHAR(13) +
                         'Cantidad disponible: ' + CAST(i.availablequantity AS VARCHAR(10)) + CHAR(13) +
                         '----------------------------' + CHAR(13)
    FROM inserted i
    WHERE i.availablequantity < 50;

    IF LEN(@msg) > 0 PRINT @msg;
END;
GO

CREATE OR ALTER TRIGGER trg_proteger_audit_update
ON audit_log AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    ROLLBACK TRANSACTION;
    THROW 50002, 'No se permite modificar la bitácora de auditoría.', 1;
END;
GO

CREATE OR ALTER TRIGGER trg_proteger_audit_delete
ON audit_log AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ROLLBACK TRANSACTION;
    THROW 50003, 'No se permite borrar registros de la bitácora de auditoría.', 1;
END;
GO


/* ============================================================
   PASO 3: FUNCIÓN AUXILIAR
   ============================================================ */

CREATE FUNCTION dbo.FIND_PRODUCT_CATEGORY_ID
(
    @category_n VARCHAR(50)
)
RETURNS INT
AS
BEGIN
    RETURN ISNULL(
        (SELECT categoryid FROM ProductCategories WHERE categoryname = @category_n),
        -1
    );
END;
GO


/* ============================================================
   PASO 4: PROCEDIMIENTOS ALMACENADOS
   ============================================================ */

-- ============================================================
-- GRUPO 1: CLIENTES Y VENDEDORES
-- ============================================================

CREATE OR ALTER PROCEDURE add_customer
    @p_name             VARCHAR(100),
    @p_email            VARCHAR(100),
    @p_city             VARCHAR(50),
    @p_state            VARCHAR(50),
    @p_zip              INT,
    @p_password         VARCHAR(255),
    @p_creditcard       BIGINT,
    @p_creditcard_type  VARCHAR(15),
    @p_expiration_month INT,
    @p_expiration_year  INT,
    @p_telefono         VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO customers (name, email, city, state, zip, phone, password_hash, active, debe_cambiar_password)
        VALUES (@p_name, @p_email, @p_city, @p_state, @p_zip, @p_telefono, @p_password, 1, 1);

        DECLARE @v_customerid INT = SCOPE_IDENTITY();

        INSERT INTO creditcards (customerid, creditcard, creditcard_type, expiration_month, expiration_year)
        VALUES (@v_customerid, @p_creditcard, @p_creditcard_type, @p_expiration_month, @p_expiration_year);

        COMMIT TRANSACTION;
        PRINT 'Cliente agregado con ID: ' + CAST(@v_customerid AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error al agregar cliente: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE add_cliente_completo
    @p_name             VARCHAR(100),
    @p_email            VARCHAR(100),
    @p_city             VARCHAR(50),
    @p_state            VARCHAR(50),
    @p_zip              INT,
    @p_password_hash    VARCHAR(255),
    @p_telefono         VARCHAR(20) = NULL,
    @p_creditcard       BIGINT = NULL,
    @p_creditcard_type  VARCHAR(15) = NULL,
    @p_expiration_month INT = NULL,
    @p_expiration_year  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO customers (name, email, city, state, zip, phone, password_hash, active)
        VALUES (@p_name, @p_email, @p_city, @p_state, @p_zip, @p_telefono, @p_password_hash, 1);

        DECLARE @v_customerid INT = SCOPE_IDENTITY();

        IF @p_creditcard IS NOT NULL AND @p_creditcard_type IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM creditcards WHERE creditcard = @p_creditcard)
            BEGIN
                INSERT INTO creditcards (customerid, creditcard, creditcard_type, expiration_month, expiration_year)
                VALUES (@v_customerid, @p_creditcard, @p_creditcard_type, @p_expiration_month, @p_expiration_year);
            END
        END

        COMMIT TRANSACTION;
        PRINT 'Cliente registrado con ID: ' + CAST(@v_customerid AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE add_seller
    @p_name          VARCHAR(50),
    @p_email         VARCHAR(50),
    @p_password_hash VARCHAR(255),
    @p_role          VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @p_role NOT IN ('ADMIN','VENDEDOR')
        BEGIN
            PRINT 'Rol inválido. Debe ser ADMIN o VENDEDOR.';
            RETURN;
        END

        INSERT INTO sellers (name, email, password_hash, role)
        VALUES (@p_name, @p_email, @p_password_hash, @p_role);

        PRINT 'Vendedor agregado con ID: ' + CAST(SCOPE_IDENTITY() AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Error al agregar vendedor: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE show_sellers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT sellerid   AS [ID del Vendedor],
           name       AS [Nombre],
           email      AS [Correo],
           role       AS [Rol],
           active     AS [Activo],
           created_at AS [Fecha de Creación]
    FROM sellers
    ORDER BY role, name;
END;
GO

CREATE OR ALTER PROCEDURE show_all_customers_in_state
    @p_state VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_count INT = 0;

    DECLARE cur CURSOR FOR
        SELECT c.name, c.email, c.city, cc.creditcard, cc.creditcard_type
        FROM customers c
        JOIN creditcards cc ON c.customerid = cc.customerid
        WHERE c.state = @p_state;

    DECLARE @name VARCHAR(100), @email VARCHAR(100), @city VARCHAR(50),
            @card BIGINT, @card_type VARCHAR(15);

    OPEN cur;
    FETCH NEXT FROM cur INTO @name, @email, @city, @card, @card_type;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Nombre: ' + @name;
        PRINT 'Correo: ' + @email;
        PRINT 'Dirección: ' + @city + ', ' + @p_state;
        PRINT 'Tarjeta: ' + CAST(@card AS VARCHAR(20)) + ' tipo: ' + @card_type;
        PRINT '-----------------------';
        SET @v_count = @v_count + 1;
        FETCH NEXT FROM cur INTO @name, @email, @city, @card, @card_type;
    END
    CLOSE cur;
    DEALLOCATE cur;

    IF @v_count = 0
        PRINT 'No se encontraron clientes en el estado: ' + @p_state;
END;
GO

-- ============================================================
-- GRUPO 2: CATÁLOGO
-- ============================================================

CREATE OR ALTER PROCEDURE Report_Cards_Expire
    @expire_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_customer_info NVARCHAR(MAX) = '';
    DECLARE @found BIT = 0;

    SELECT @v_customer_info = @v_customer_info + c.name + ' - ' +
                              CAST(cc.creditcard AS VARCHAR(20)) + ' (' + cc.creditcard_type + ')' + CHAR(13),
           @found = 1
    FROM customers c
    JOIN creditcards cc ON c.customerID = cc.customerID
    WHERE DATEFROMPARTS(cc.expiration_year, cc.expiration_month, 1)
          BETWEEN DATEADD(MONTH, -2, @expire_date) AND @expire_date;

    IF @found = 0
        PRINT 'No hay tarjetas de crédito que expiren en los próximos dos meses.';
    ELSE
    BEGIN
        PRINT 'Las siguientes tarjetas de crédito expiran en los próximos dos meses:';
        PRINT @v_customer_info;
    END
END;
GO

CREATE OR ALTER PROCEDURE Add_Category
    @category_name VARCHAR(50),
    @category_desc VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO ProductCategories (categoryname, description)
        VALUES (@category_name, @category_desc);
        PRINT 'Categoría agregada exitosamente: ' + @category_name;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627
            PRINT 'La categoría ya existe: ' + @category_name;
        ELSE
        BEGIN
            PRINT 'SQLCODE: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
            PRINT 'SQLERRM: ' + ERROR_MESSAGE();
        END
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Add_Product
    @product_name       VARCHAR(100),
    @available_quantity INT,
    @unit_price         DECIMAL(10,2),
    @category_name      VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @category_ID INT;
        SET @category_ID = dbo.FIND_PRODUCT_CATEGORY_ID(@category_name);

        IF @category_ID = -1
        BEGIN
            PRINT 'Producto no agregado - categoría no encontrada: ' + @category_name;
            RETURN;
        END

        INSERT INTO products (productname, availablequantity, unitprice, categoryid)
        VALUES (@product_name, @available_quantity, @unit_price, @category_ID);

        PRINT 'Producto agregado exitosamente: ' + @product_name;
    END TRY
    BEGIN CATCH
        PRINT 'SQLCODE: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        PRINT 'SQLERRM: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Report_Inventory
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Nombre de categoría: Total de productos en existencia';
    PRINT '---------------------------------------------------';

    SELECT pc.categoryname + ': ' + CAST(ISNULL(SUM(p.availablequantity), 0) AS VARCHAR(20)) AS [Reporte por Categoría]
    FROM ProductCategories pc
    LEFT JOIN products p ON pc.categoryid = p.categoryid
    GROUP BY pc.categoryname;
END;
GO

-- ============================================================
-- GRUPO 3: PEDIDOS Y VENTAS
-- ============================================================

CREATE OR ALTER PROCEDURE find_customer_id
    @email_address VARCHAR(100),
    @customer_id   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @customer_id = -1;

    SELECT @customer_id = customerid FROM customers WHERE email = @email_address;

    IF @customer_id = -1
        PRINT 'La dirección de correo no existe: ' + @email_address;
    ELSE
        PRINT 'El ID del cliente es ' + CAST(@customer_id AS VARCHAR(10));
END;
GO

CREATE OR ALTER PROCEDURE find_product_id
    @product_name VARCHAR(100),
    @product_id   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @product_id = -1;

    SELECT @product_id = productid FROM products WHERE productname = @product_name;

    IF @product_id = -1
        PRINT 'El nombre del producto no existe: ' + @product_name;
    ELSE
        PRINT 'El ID del producto es ' + CAST(@product_id AS VARCHAR(10));
END;
GO

CREATE OR ALTER PROCEDURE find_order_by_date
    @p_order_date DATE,
    @p_order_id   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @p_order_id = -1;

    SELECT TOP 1 @p_order_id = orderid FROM orders WHERE orderdate = @p_order_date;

    IF @p_order_id = -1
        PRINT 'No se encontró pedido para la fecha ' + CAST(@p_order_date AS VARCHAR(20));
    ELSE
        PRINT 'ID del pedido: ' + CAST(@p_order_id AS VARCHAR(10));
END;
GO

-- ============================================================
-- PROCEDIMIENTO MODIFICADO (v5.2): acepta @status, efectivo y datetime
-- ============================================================

USE OSF;
GO

CREATE OR ALTER PROCEDURE place_order_full
    @cust_id     INT,
    @seller_id   INT = NULL,
    @order_date  DATETIME,
    @cc_num      BIGINT = NULL,
    @items       NVARCHAR(MAX),
    @amount      DECIMAL(10,2) = 0,
    @status      VARCHAR(15) = 'PENDIENTE'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 🔥 Si el vendedor es nulo o 0, asignar Admin (ID 1)
        DECLARE @vendedor_final INT = @seller_id;
        IF (@vendedor_final IS NULL OR @vendedor_final = 0)
        BEGIN
            SET @vendedor_final = 1;
        END

        INSERT INTO orders (customerid, sellerid, orderdate, cc_number, status, total)
        VALUES (@cust_id, @vendedor_final, @order_date, @cc_num, @status, @amount);

        DECLARE @oid INT = SCOPE_IDENTITY();

        INSERT INTO order_details (orderid, productid, quantity, unitprice)
        SELECT @oid, j.productid, j.quantity, p.unitprice
        FROM OPENJSON(@items)
             WITH (productid INT '$.productid', quantity INT '$.quantity') AS j
        JOIN products p ON p.productid = j.productid;

        UPDATE orders
        SET total = (SELECT ISNULL(SUM(subtotal), 0) FROM order_details WHERE orderid = @oid)
        WHERE orderid = @oid;

        -- 🔥 SOLO INSERTAR EN INVOICES SI HAY TARJETA (cc_num > 0)
        IF @amount > 0 AND @cc_num IS NOT NULL AND @cc_num > 0
        BEGIN
            INSERT INTO invoices (orderid, customerid, creditcard, amount)
            VALUES (@oid, @cust_id, @cc_num, @amount);
        END

        COMMIT TRANSACTION;
        PRINT 'Pedido ' + CAST(@oid AS VARCHAR(10)) + ' registrado correctamente con estado: ' + @status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error al registrar pedido: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE add_orders
    @cust_id    INT,
    @prod_id    INT,
    @quant      INT,
    @order_date DATE,
    @cc_num     BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @items NVARCHAR(MAX) =
            '[{"productid":' + CAST(@prod_id AS VARCHAR(10)) +
            ',"quantity":'  + CAST(@quant   AS VARCHAR(10)) + '}]';

        EXEC place_order_full @cust_id, NULL, @order_date, @cc_num, @items, 0, 'CONFIRMADO';
    END TRY
    BEGIN CATCH
        PRINT 'Error al agregar pedido: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE place_order
    @cust_email   VARCHAR(100),
    @product_name VARCHAR(100),
    @quant        INT,
    @cc_num       BIGINT,
    @amt          DECIMAL(10,2),
    @order_date   DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @cust_id INT, @prod_id INT;

        EXEC find_customer_id @cust_email, @cust_id OUTPUT;
        EXEC find_product_id  @product_name, @prod_id OUTPUT;

        IF @cust_id = -1 OR @prod_id = -1
        BEGIN
            PRINT 'Pedido no realizado - datos faltantes.';
            RETURN;
        END

        DECLARE @items NVARCHAR(MAX) =
            '[{"productid":' + CAST(@prod_id AS VARCHAR(10)) +
            ',"quantity":'  + CAST(@quant   AS VARCHAR(10)) + '}]';

        EXEC place_order_full @cust_id, NULL, @order_date, @cc_num, @items, @amt, 'CONFIRMADO';

        PRINT 'Pedido realizado exitosamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error al realizar pedido: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE show_orders
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.name          AS [Cliente],
           p.productname   AS [Producto],
           od.quantity     AS [Cantidad],
           od.subtotal     AS [Subtotal],
           o.status        AS [Estado]
    FROM orders o
    JOIN customers c     ON o.customerid = c.customerid
    JOIN order_details od ON o.orderid   = od.orderid
    JOIN products p      ON od.productid = p.productid;

    SELECT COUNT(DISTINCT o.orderid)   AS [Total de Pedidos],
           ISNULL(SUM(od.subtotal), 0) AS [Monto Total]
    FROM orders o
    JOIN order_details od ON o.orderid = od.orderid;
END;
GO

CREATE OR ALTER PROCEDURE report_orders_by_state
    @c_state VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.name  AS [Nombre del Cliente],
           c.email AS [Correo del Cliente],
           COUNT(DISTINCT o.orderid)   AS [Total de Pedidos],
           ISNULL(SUM(od.subtotal), 0) AS [Monto Total]
    FROM orders o
    INNER JOIN customers c     ON o.customerid = c.customerid
    INNER JOIN order_details od ON o.orderid   = od.orderid
    WHERE c.state = @c_state
    GROUP BY c.name, c.email;

    SELECT COUNT(DISTINCT o.orderid)   AS [Total General de Pedidos],
           ISNULL(SUM(od.subtotal), 0) AS [Monto General Total]
    FROM orders o
    INNER JOIN customers c ON o.customerid = c.customerid
    INNER JOIN order_details od ON o.orderid = od.orderid
    WHERE c.state = @c_state;
END;
GO

CREATE OR ALTER PROCEDURE report_best_customers
    @a INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM order_details od
        INNER JOIN orders o ON o.orderid = od.orderid
        WHERE od.subtotal > @a
    )
    BEGIN
        PRINT 'No existe ningún cliente con monto mayor a ' + CAST(@a AS VARCHAR(20));
        RETURN;
    END

    SELECT c.name          AS [Nombre del Cliente],
           SUM(od.subtotal) AS [Monto Total]
    FROM order_details od
    INNER JOIN orders o    ON o.orderid = od.orderid
    INNER JOIN customers c ON c.customerid = o.customerid
    GROUP BY c.name
    HAVING SUM(od.subtotal) > @a
    ORDER BY SUM(od.subtotal) DESC;
END;
GO

CREATE OR ALTER PROCEDURE find_stingy_customers
    @X INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @counter1 INT;
    SELECT @counter1 = COUNT(DISTINCT customerid) FROM orders;

    IF @counter1 < @X
    BEGIN
        PRINT 'Máximo de clientes: ' + CAST(@counter1 AS VARCHAR(10)) +
              ' | Valor ingresado: ' + CAST(@X AS VARCHAR(10));
    END

    IF @X <= 0
    BEGIN
        PRINT 'Ingrese un número válido mayor a 0';
        RETURN;
    END

    SELECT TOP (@X) o.customerid     AS [ID del Cliente],
                    SUM(od.subtotal) AS [Total Gastado]
    FROM orders o
    JOIN order_details od ON o.orderid = od.orderid
    GROUP BY o.customerid
    ORDER BY SUM(od.subtotal) ASC;
END;
GO

-- ============================================================
-- GRUPO 4: FACTURACIÓN Y PAGOS
-- ============================================================

CREATE OR ALTER PROCEDURE invoice_customer
    @p_order_id        INT,
    @p_customer_id     INT,
    @p_credit_card_num BIGINT,
    @p_amount          DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @counter1 INT, @counter2 INT, @cc_exists INT;

        SELECT @counter1 = COUNT(*) FROM orders    WHERE orderid    = @p_order_id;
        SELECT @counter2 = COUNT(*) FROM customers WHERE customerid = @p_customer_id;

        IF @counter1 <= 0 AND @counter2 > 0 BEGIN PRINT 'No existe ese pedido'; RETURN; END
        IF @counter2 <= 0 AND @counter1 > 0 BEGIN PRINT 'No existe ese cliente'; RETURN; END
        IF @counter2 <= 0 AND @counter1 <= 0 BEGIN PRINT 'No existe ni el pedido ni el cliente'; RETURN; END

        SELECT @cc_exists = COUNT(*) FROM creditcards WHERE creditcard = @p_credit_card_num;
        IF @cc_exists = 0
        BEGIN
            PRINT 'La tarjeta de crédito no existe: ' + CAST(@p_credit_card_num AS VARCHAR(20));
            RETURN;
        END

        INSERT INTO invoices (orderid, customerid, creditcard, amount)
        VALUES (@p_order_id, @p_customer_id, @p_credit_card_num, @p_amount);

        PRINT 'Factura creada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error al crear factura: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE calculate_credit_card_fees
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @visa_fee     DECIMAL(10,2) = 0;
    DECLARE @mc_fee       DECIMAL(10,2) = 0;
    DECLARE @amex_fee     DECIMAL(10,2) = 0;
    DECLARE @discover_fee DECIMAL(10,2) = 0;

    SELECT @visa_fee     = ISNULL(SUM(i.amount * 0.03), 0)
    FROM invoices i JOIN creditcards c ON i.creditcard = c.creditcard
    WHERE c.creditcard_type = 'VISA';

    SELECT @mc_fee       = ISNULL(SUM(i.amount * 0.03), 0)
    FROM invoices i JOIN creditcards c ON i.creditcard = c.creditcard
    WHERE c.creditcard_type = 'MC';

    SELECT @amex_fee     = ISNULL(SUM(i.amount * 0.05), 0)
    FROM invoices i JOIN creditcards c ON i.creditcard = c.creditcard
    WHERE c.creditcard_type = 'AMEX';

    SELECT @discover_fee = ISNULL(SUM(i.amount * 0.02), 0)
    FROM invoices i JOIN creditcards c ON i.creditcard = c.creditcard
    WHERE c.creditcard_type = 'Discover';

    PRINT 'Comisión VISA:     $' + CAST(@visa_fee     AS VARCHAR(20));
    PRINT 'Comisión MC:       $' + CAST(@mc_fee       AS VARCHAR(20));
    PRINT 'Comisión AMEX:     $' + CAST(@amex_fee     AS VARCHAR(20));
    PRINT 'Comisión Discover: $' + CAST(@discover_fee AS VARCHAR(20));
END;
GO

-- ============================================================
-- GRUPO 5: INVENTARIO
-- ============================================================

CREATE OR ALTER PROCEDURE Update_Inventory
    @product_id INT, @quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE products SET availablequantity = availablequantity - @quantity
        WHERE productid = @product_id;

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'No se encontró inventario para el producto con ID ' + CAST(@product_id AS VARCHAR(10));
            RETURN;
        END

        DECLARE @new_quant INT;
        SELECT @new_quant = availablequantity FROM products WHERE productid = @product_id;
        PRINT 'Cantidad actualizada: ' + CAST(@new_quant AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE update_inventory1
    @product_id INT, @quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE products SET availablequantity = availablequantity + @quantity
        WHERE productid = @product_id;

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'No se encontró inventario para el producto con ID ' + CAST(@product_id AS VARCHAR(10));
            RETURN;
        END

        DECLARE @new_quant INT;
        SELECT @new_quant = availablequantity FROM products WHERE productid = @product_id;
        PRINT 'Cantidad actualizada: ' + CAST(@new_quant AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE register_inventory_movement
    @product_id    INT,
    @seller_id     INT = NULL,
    @movement_type VARCHAR(15),
    @quantity      INT,
    @reason        VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @movement_type NOT IN ('ENTRADA','SALIDA','AJUSTE','DEVOLUCION')
        BEGIN
            PRINT 'Tipo de movimiento inválido.';
            RETURN;
        END

        BEGIN TRANSACTION;

        INSERT INTO inventory_movements(productid, sellerid, movement_type, quantity, reason)
        VALUES (@product_id, @seller_id, @movement_type, @quantity, @reason);

        IF @movement_type IN ('ENTRADA','DEVOLUCION')
            UPDATE products SET availablequantity = availablequantity + @quantity WHERE productid = @product_id;
        ELSE IF @movement_type = 'SALIDA'
            UPDATE products SET availablequantity = availablequantity - @quantity WHERE productid = @product_id;
        ELSE IF @movement_type = 'AJUSTE'
            UPDATE products SET availablequantity = @quantity WHERE productid = @product_id;

        COMMIT TRANSACTION;
        PRINT 'Movimiento registrado.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE report_inventory_movements
    @product_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.movementid    AS [ID del Movimiento],
           p.productname   AS [Producto],
           m.movement_type AS [Tipo de Movimiento],
           m.quantity      AS [Cantidad],
           m.reason        AS [Motivo],
           s.name          AS [Vendedor],
           m.movement_date AS [Fecha del Movimiento]
    FROM inventory_movements m
    JOIN products p ON m.productid = p.productid
    LEFT JOIN sellers s ON m.sellerid = s.sellerid
    WHERE (@product_id IS NULL OR m.productid = @product_id)
    ORDER BY m.movement_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE report_sales_by_seller
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.sellerid AS [ID del Vendedor],
           s.name     AS [Nombre del Vendedor],
           s.role     AS [Rol],
           COUNT(DISTINCT o.orderid)   AS [Total de Pedidos],
           ISNULL(SUM(od.subtotal), 0) AS [Total Vendido]
    FROM sellers s
    LEFT JOIN orders o         ON o.sellerid  = s.sellerid
    LEFT JOIN order_details od ON od.orderid  = o.orderid
    GROUP BY s.sellerid, s.name, s.role
    ORDER BY [Total Vendido] DESC;
END;
GO

-- ============================================================
-- GRUPO 6: RESEÑAS Y RECOMENDACIONES
-- ============================================================

CREATE OR ALTER PROCEDURE add_review
    @product_name VARCHAR(100),
    @cust_email   VARCHAR(100),
    @star_given   INT,
    @review_text  VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @cust_email IS NULL
        BEGIN PRINT 'No tiene un correo electrónico'; RETURN; END

        IF @star_given < 1 OR @star_given > 5
        BEGIN PRINT 'Las estrellas deben estar entre 1 y 5'; RETURN; END

        DECLARE @prod_id INT;
        EXEC find_product_id @product_name, @prod_id OUTPUT;

        IF @prod_id = -1
        BEGIN PRINT 'Reseña no agregada - producto no encontrado.'; RETURN; END

        INSERT INTO reviews (productid, reviewer_email, starsgiven, review_text)
        VALUES (@prod_id, @cust_email, @star_given, @review_text);

        PRINT 'Reseña insertada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error al agregar reseña: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE buy_or_beware
    @x INT
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Productos mejor calificados:';
    SELECT TOP (@x)
           AVG(r.starsgiven)   AS [Calificación Promedio],
           STDEV(r.starsgiven) AS [Desviación Estándar],
           p.productid         AS [ID del Producto],
           p.productname       AS [Nombre del Producto]
    FROM reviews r
    JOIN products p ON r.productid = p.productid
    GROUP BY p.productid, p.productname
    ORDER BY AVG(r.starsgiven) DESC;

    PRINT 'Cuidado comprador: manténgase alejado de...';
    SELECT TOP (@x)
           AVG(r.starsgiven)   AS [Calificación Promedio],
           STDEV(r.starsgiven) AS [Desviación Estándar],
           p.productid         AS [ID del Producto],
           p.productname       AS [Nombre del Producto]
    FROM reviews r
    JOIN products p ON r.productid = p.productid
    GROUP BY p.productid, p.productname
    ORDER BY AVG(r.starsgiven) ASC;
END;
GO

CREATE OR ALTER PROCEDURE Recommend_To_Customer
    @in_custid INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @tmp_productid INT, @tmp_productname VARCHAR(100),
                @tmp_categoryid INT, @tmp_avg_rating DECIMAL(10,2);

        SELECT TOP 1
               @tmp_avg_rating  = AVG(r.starsgiven),
               @tmp_categoryid  = p.categoryid,
               @tmp_productid   = p.productid,
               @tmp_productname = p.productname
        FROM reviews r
        JOIN products p ON r.productid = p.productid
        WHERE r.productid NOT IN (
                SELECT od.productid FROM order_details od
                JOIN orders o ON od.orderid = o.orderid
                WHERE o.customerid = @in_custid
              )
          AND p.categoryid IN (
                SELECT p2.categoryid FROM products p2
                JOIN order_details od2 ON p2.productid = od2.productid
                JOIN orders o2 ON od2.orderid = o2.orderid
                WHERE o2.customerid = @in_custid
              )
        GROUP BY p.categoryid, p.productid, p.productname
        ORDER BY AVG(r.starsgiven) DESC;

        IF @tmp_productid IS NULL
        BEGIN PRINT 'Producto recomendado no encontrado'; RETURN; END

        PRINT 'Producto recomendado: ' + @tmp_productname;

        DECLARE @tmp_count INT;
        SELECT @tmp_count = COUNT(*) FROM recommendations
        WHERE customerid = @in_custid AND recommendation_productid = @tmp_productid;

        IF @tmp_count > 0
        BEGIN PRINT 'Ya existe la recomendación.'; RETURN; END
        ELSE
        BEGIN
            INSERT INTO recommendations (customerid, recommendation_productid)
            VALUES (@in_custid, @tmp_productid);
        END
    END TRY
    BEGIN CATCH
        PRINT 'Producto recomendado no encontrado';
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE List_Recommendations
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.name       AS [Cliente],
           p.categoryid AS [Categoría],
           (SELECT TOP 1 p2.productname
            FROM reviews r JOIN products p2 ON r.productid = p2.productid
            WHERE p2.categoryid = p.categoryid
              AND p2.productid NOT IN (
                  SELECT od.productid FROM order_details od
                  JOIN orders o2 ON od.orderid = o2.orderid
                  WHERE o2.customerid = o.customerid)
            GROUP BY p2.productname
            ORDER BY AVG(r.starsgiven) DESC) AS [Producto Recomendado]
    FROM products p
    JOIN order_details od ON p.productid = od.productid
    JOIN orders o         ON od.orderid  = o.orderid
    JOIN customers c      ON c.customerid = o.customerid
    GROUP BY c.name, p.categoryid, o.customerid;
END;
GO

-- ============================================================
-- GRUPO 7: INSERCIÓN ADICIONAL
-- ============================================================

CREATE OR ALTER PROCEDURE agregar_detalle_pedido
    @order_id INT, @product_id INT, @quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @precio DECIMAL(10,2);
        SELECT @precio = unitprice FROM products WHERE productid = @product_id;

        IF @precio IS NULL
        BEGIN PRINT 'Producto no encontrado.'; RETURN; END

        INSERT INTO order_details (orderid, productid, quantity, unitprice)
        VALUES (@order_id, @product_id, @quantity, @precio);

        PRINT 'Detalle agregado al pedido ' + CAST(@order_id AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE agregar_recomendacion
    @customer_id INT, @product_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO recommendations (customerid, recommendation_productid)
        VALUES (@customer_id, @product_id);
        PRINT 'Recomendación agregada.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE agregar_movimiento_inventario
    @product_id INT, @seller_id INT = NULL, @movement_type VARCHAR(15),
    @quantity INT, @reason VARCHAR(150) = NULL
AS
BEGIN
    EXEC register_inventory_movement @product_id, @seller_id, @movement_type, @quantity, @reason;
END;
GO

CREATE OR ALTER PROCEDURE agregar_factura
    @order_id INT, @customer_id INT, @credit_card_num BIGINT, @amount DECIMAL(10,2)
AS
BEGIN
    EXEC invoice_customer @order_id, @customer_id, @credit_card_num, @amount;
END;
GO

CREATE OR ALTER PROCEDURE agregar_resena
    @product_name VARCHAR(100), @cust_email VARCHAR(100),
    @star_given INT, @review_text VARCHAR(200)
AS
BEGIN
    EXEC add_review @product_name, @cust_email, @star_given, @review_text;
END;
GO


/* ============================================================
   PASO 5: CARGAR DATOS DE PRUEBA
   ============================================================ */

PRINT '==========================================';
PRINT ' INICIANDO CARGA DE DATOS';
PRINT '==========================================';

-- 1) CATEGORÍAS
PRINT '--- Insertando 40 categorías ---';
EXEC Add_Category 'Electrónica',                  'Dispositivos electrónicos y gadgets';
EXEC Add_Category 'Computadoras y Tablets',        'Laptops, PCs, tablets y accesorios';
EXEC Add_Category 'Celulares y Accesorios',        'Smartphones, fundas, cargadores';
EXEC Add_Category 'Audio y Video',                 'Parlantes, audífonos, televisores';
EXEC Add_Category 'Videojuegos y Consolas',        'Consolas, juegos, accesorios gamer';
EXEC Add_Category 'Cámaras y Fotografía',          'Cámaras, lentes, drones';
EXEC Add_Category 'Software y Productos Digitales','Programas, cursos, apps';
EXEC Add_Category 'Electrodomésticos',             'Refrigeradoras, lavadoras, microondas';
EXEC Add_Category 'Cocina y Comedor',              'Utensilios, vajilla, ollas';
EXEC Add_Category 'Hogar y Jardín',                'Decoración, jardinería, exteriores';
EXEC Add_Category 'Iluminación',                   'Lámparas, focos, tiras LED';
EXEC Add_Category 'Herramientas y Ferretería',     'Taladros, llaves, tornillos';
EXEC Add_Category 'Ropa y Accesorios',             'Camisas, pantalones, vestidos';
EXEC Add_Category 'Calzado',                       'Zapatos, tenis, botas, sandalias';
EXEC Add_Category 'Joyería y Relojes',             'Anillos, collares, relojes';
EXEC Add_Category 'Bolsos y Carteras',             'Mochilas, maletas, carteras';
EXEC Add_Category 'Belleza y Cuidado Personal',    'Maquillaje, cremas, cuidado capilar';
EXEC Add_Category 'Perfumes',                      'Perfumes y fragancias';
EXEC Add_Category 'Gafas y Lentes',                'Lentes de sol y de aumento';
EXEC Add_Category 'Salud y Bienestar',             'Equipos médicos, vitaminas';
EXEC Add_Category 'Suplementos y Vitaminas',       'Proteínas, vitaminas, suplementos';
EXEC Add_Category 'Deportes y Aire Libre',         'Camping, pesca, senderismo';
EXEC Add_Category 'Fitness y Musculación',         'Pesas, bandas, ropa fitness';
EXEC Add_Category 'Bicicletas y Accesorios',       'Bicicletas, cascos, accesorios';
EXEC Add_Category 'Juguetes y Juegos',             'Juguetes educativos, juegos de mesa';
EXEC Add_Category 'Bebés y Niños',                 'Pañales, ropa de bebé, cuidado';
EXEC Add_Category 'Mascotas',                      'Alimentos, juguetes, accesorios';
EXEC Add_Category 'Ropa Deportiva',                'Sudaderas, shorts, tops deportivos';
EXEC Add_Category 'Libros, Música y Películas',    'Libros, CDs, DVDs, vinyl';
EXEC Add_Category 'Instrumentos Musicales',        'Guitarras, teclados, baterías';
EXEC Add_Category 'Arte, Manualidades y Costura',  'Pinturas, telas, hilos';
EXEC Add_Category 'Coleccionables y Hobbies',      'Figuras, antigüedades, cartas';
EXEC Add_Category 'Oficina y Papelería',           'Cuadernos, bolígrafos, archivos';
EXEC Add_Category 'Automotriz',                    'Repuestos, aceites, accesorios';
EXEC Add_Category 'Motocicletas y Accesorios',     'Motos, cascos, repuestos';
EXEC Add_Category 'Industria y Ciencia',           'Instrumentos, maquinaria';
EXEC Add_Category 'Alimentos y Bebidas',           'Despensa, snacks, bebidas';
EXEC Add_Category 'Productos de Limpieza',         'Detergentes, desinfectantes';
EXEC Add_Category 'Regalos y Novedades',           'Regalos, decoración, novedades';
EXEC Add_Category 'Jardinería',                    'Plantas, macetas, herramientas de jardín';
GO

-- 2) PRODUCTOS
PRINT '--- Insertando productos ---';
EXEC Add_Product 'TV 40 pulgadas',            100, 200,  'Electrónica';
EXEC Add_Product 'TV 50 pulgadas',            100, 300,  'Electrónica';
EXEC Add_Product 'TV 60 pulgadas',            100, 400,  'Electrónica';
EXEC Add_Product 'TV 80 pulgadas',            100, 1000, 'Electrónica';
EXEC Add_Product 'Lo mejor de Beyoncé',       100, 20,   'Libros, Música y Películas';
EXEC Add_Product 'Lo mejor de Taylor Swift',  100, 20,   'Libros, Música y Películas';
EXEC Add_Product 'Lo mejor de Eminem',        100, 20,   'Libros, Música y Películas';
EXEC Add_Product 'Lo mejor de The Weeknd',    100, 20,   'Libros, Música y Películas';
EXEC Add_Product 'Pelota',                     50, 10.50,'Deportes y Aire Libre';
EXEC Add_Product 'Cocina Quemador',             2, 12000, 'Electrodomésticos';
GO

-- 3) VENDEDORES
PRINT '--- Insertando vendedores ---';
EXEC add_seller 'Admin General',     'admin@mercadeonica.com',    'admin123',    'ADMIN';
EXEC add_seller 'Franklin Salinas',  'franklin.v@mercadeonica.com','vendedor123', 'VENDEDOR';
EXEC add_seller 'Sofia Guevara',     'sofia.v@mercadeonica.com',   'vendedor123', 'VENDEDOR';
EXEC add_seller 'Harvin Gonzalez',   'harvin.v@mercadeonica.com',  'vendedor123', 'VENDEDOR';
GO

-- 4) CLIENTES
PRINT '--- Insertando clientes ---';
EXEC add_cliente_completo 'Franklin Salinas',   'franklin@gmail.com', 'Rusia',       'MD', 21250, 'cliente123', NULL, 12345, 'VISA',     10, 2026;
EXEC add_cliente_completo 'Sofia Guevara',      'sofia@gmail.com',    'Velezuela',   'DC', 20001, 'cliente123', NULL, 12348, 'VISA',     10, 2026;
EXEC add_cliente_completo 'Harvin Gonzalez',    'harvin@gmail.com',   'Los Angeles', 'CA', 90001, 'cliente123', NULL, 45678, 'Discover', 11, 2026;
EXEC add_cliente_completo 'Rosa Solano',        'rosa@gmail.org',     'Columbia',    'SC', 44250, 'cliente123', NULL, 45679, 'Discover', 10, 2026;
EXEC add_cliente_completo 'Carlos Martinez',    'carlos@gmail.com',   'Corea',       'MD', 21250, 'cliente123', NULL, 12346, 'VISA',     10, 2026;
GO

-- 🔥 Asignar categoría "Regular" a todos los clientes de prueba
UPDATE customers 
SET categoryid = (SELECT categoryid FROM CustomerCategories WHERE categoryname = 'Regular')
WHERE categoryid IS NULL;
GO

-- 5) PEDIDOS
EXEC place_order_full 1, 2, '2023-05-10 10:30:00', 12345,
     '[{"productid":2,"quantity":2},{"productid":5,"quantity":30}]', 600.00, 'CONFIRMADO';

EXEC place_order_full 5, 2, '2023-05-11 14:15:00', 12346,
     '[{"productid":4,"quantity":1}]', 1000.00, 'CONFIRMADO';

EXEC place_order_full 3, 3, '2023-06-20 20:45:00', 45678,
     '[{"productid":6,"quantity":10},{"productid":7,"quantity":10},{"productid":8,"quantity":10},{"productid":5,"quantity":25}]',
     11000.00, 'CONFIRMADO';

-- Pedido de prueba en EFECTIVO (cc_number = 0)
EXEC place_order_full 1, 2, '2023-05-12 15:00:00', 0, 
     '[{"productid":1,"quantity":2}]', 400.00, 'CONFIRMADO';
GO

-- 6) MOVIMIENTOS DE INVENTARIO
PRINT '--- Insertando movimientos de inventario ---';
EXEC register_inventory_movement 1, 1, 'ENTRADA', 50, 'Reposición de stock TV 40 pulgadas';
EXEC register_inventory_movement 6, 1, 'ENTRADA', 20, 'Reposición BestOfTaylorSwift';
GO

-- 7) RESEÑAS
PRINT '--- Insertando reseñas ---';
EXEC add_review 'TV 50 pulgadas',        'franklin@gmail.com', 2, 'No es un buen televisor. Podría ser mejor';
EXEC add_review 'TV 50 pulgadas',        'carlos@gmail.com',   1, 'No lo compren';
EXEC add_review 'TV 80 pulgadas',        'harvin@gmail.com',   5, 'Excelente. Este es el mejor televisor';
EXEC add_review 'TV 80 pulgadas',        'martha@gmail.com',   5, 'Excelente. El mejor de todos';
EXEC add_review 'Lo mejor de Beyoncé',   'martha@gmail.com',   5, 'Excelente. El mejor de todos';
EXEC add_review 'Lo mejor de Beyoncé',   'eduardo@gmail.com',  4, 'Lo disfruté';
GO


/* ============================================================
   PASO 6: VERIFICACIÓN FINAL Y RESTRICCIONES
   ============================================================ */

PRINT '';
PRINT '==========================================';
PRINT ' RESUMEN DE DATOS CARGADOS';
PRINT '==========================================';

SELECT 'CUSTOMERS'           AS tabla, COUNT(*) AS filas FROM customers
UNION ALL SELECT 'SELLERS',             COUNT(*) FROM sellers
UNION ALL SELECT 'CATEGORIES',          COUNT(*) FROM ProductCategories
UNION ALL SELECT 'PRODUCTS',            COUNT(*) FROM products
UNION ALL SELECT 'ORDERS',              COUNT(*) FROM orders
UNION ALL SELECT 'ORDER_DETAILS',       COUNT(*) FROM order_details
UNION ALL SELECT 'INVENTORY_MOVEMENTS', COUNT(*) FROM inventory_movements
UNION ALL SELECT 'CREDITCARDS',         COUNT(*) FROM creditcards
UNION ALL SELECT 'INVOICES',            COUNT(*) FROM invoices
UNION ALL SELECT 'REVIEWS',             COUNT(*) FROM reviews
UNION ALL SELECT 'RECOMMENDATIONS',     COUNT(*) FROM recommendations
UNION ALL SELECT 'AUDIT_LOG',           COUNT(*) FROM audit_log;
GO

-- Verificar columnas de customers
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers' ORDER BY ORDINAL_POSITION;
GO

-- Ver categorías
SELECT categoryid, categoryname FROM ProductCategories ORDER BY categoryid;
GO

PRINT '';
PRINT '==========================================';
PRINT ' ✅ BASE DE DATOS OSF v5.0 LISTA';
PRINT '==========================================';
PRINT 'Credenciales de prueba:';
PRINT '  ADMIN:    admin@mercadeonica.com     / hash_admin';
PRINT '  VENDEDOR: franklin.v@mercadeonica.com / hash_franklin';
PRINT '  CLIENTE:  franklin@gmail.com          / cliente123';
PRINT '';
PRINT 'Próximo paso: trabajar con Java (NetBeans)';
PRINT '==========================================';
GO