/* =====================================================================
   SCRIPT LIMPIO PARA GENERAR EL DIAGRAMA E/R - BD OSF
   Contiene SOLO la estructura de tablas (DDL) sin datos,
   sin triggers, sin procedimientos ni funciones.
   Ideal para importar en SSMS Database Diagrams o en herramientas
   online como dbdiagram.io, drawSQL o Lucidchart o en otras aplicacion.
   ===================================================================== */

CREATE DATABASE OSF_ER;
GO
USE OSF_ER;
GO

/* -------------------- 1. CustomerCategories -------------------- */
CREATE TABLE CustomerCategories (
  categoryid           INT IDENTITY(1,1) NOT NULL,
  categoryname         VARCHAR(50)  NOT NULL,
  discount_percentage  DECIMAL(5,2) NOT NULL DEFAULT 0,
  CONSTRAINT PK_CustomerCategories PRIMARY KEY (categoryid),
  CONSTRAINT UQ_CustomerCategories_Name UNIQUE (categoryname)
);
GO

/* -------------------- 2. customers -------------------- */
CREATE TABLE customers (
  customerid             INT IDENTITY(1,1) NOT NULL,
  name                   VARCHAR(100) NOT NULL,
  email                  VARCHAR(100) NOT NULL,
  city                   VARCHAR(50),
  state                  VARCHAR(50),
  zip                    INT,
  phone                  VARCHAR(20) NULL,
  password_hash          VARCHAR(255) NULL,
  active                 BIT NOT NULL DEFAULT 1,
  debe_cambiar_password  BIT NOT NULL DEFAULT 0,
  categoryid             INT NULL,
  CONSTRAINT PK_CUSTOMERS_CUSTOMERID PRIMARY KEY (customerid),
  CONSTRAINT UQ_CUSTOMERS_EMAIL      UNIQUE (email),
  CONSTRAINT FK_Customers_CustomerCategories FOREIGN KEY (categoryid)
      REFERENCES CustomerCategories(categoryid)
);
GO

/* -------------------- 3. sellers -------------------- */
CREATE TABLE sellers (
  sellerid       INT IDENTITY(1,1) NOT NULL,
  name           VARCHAR(50)  NOT NULL,
  email          VARCHAR(50)  NOT NULL,
  phone          VARCHAR(20)  NULL,
  password_hash  VARCHAR(255) NOT NULL,
  role           VARCHAR(15)  NOT NULL,
  active         BIT NOT NULL DEFAULT 1,
  created_at     DATETIME2 DEFAULT SYSDATETIME(),
  CONSTRAINT PK_SELLERS_SELLERID PRIMARY KEY (sellerid),
  CONSTRAINT UQ_SELLERS_EMAIL    UNIQUE (email)
);
GO

/* -------------------- 4. ProductCategories -------------------- */
CREATE TABLE ProductCategories (
  categoryid    INT IDENTITY(1,1) NOT NULL,
  categoryname  VARCHAR(50) NOT NULL,
  description   VARCHAR(150),
  CONSTRAINT PK_CATEGORIES_CATEGORYID PRIMARY KEY (categoryid),
  CONSTRAINT UQ_CATEGORIES_NAME       UNIQUE (categoryname)
);
GO

/* -------------------- 5. products -------------------- */
CREATE TABLE products (
  productid          INT IDENTITY(1,1) NOT NULL,
  productname        VARCHAR(100) NOT NULL,
  availablequantity  INT NOT NULL,
  unitprice          DECIMAL(10,2) NOT NULL,
  categoryid         INT,
  CONSTRAINT PK_PRODUCTS_PRODUCTID  PRIMARY KEY (productid),
  CONSTRAINT FK_PRODUCTS_CATEGORIES FOREIGN KEY (categoryid)
      REFERENCES ProductCategories(categoryid)
);
GO

/* -------------------- 6. orders -------------------- */
CREATE TABLE orders (
  orderid     INT IDENTITY(1,1) NOT NULL,
  customerid  INT,
  sellerid    INT NULL,
  orderdate   DATETIME,
  cc_number   BIGINT NULL,
  status      VARCHAR(15) NOT NULL DEFAULT 'PENDIENTE',
  total       DECIMAL(10,2) DEFAULT 0,
  CONSTRAINT PK_ORDERS_ORDERID   PRIMARY KEY (orderid),
  CONSTRAINT FK_ORDERS_CUSTOMERS FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_ORDERS_SELLERS   FOREIGN KEY (sellerid)   REFERENCES sellers(sellerid)
);
GO

/* -------------------- 7. order_details -------------------- */
CREATE TABLE order_details (
  detailid   INT IDENTITY(1,1) NOT NULL,
  orderid    INT NOT NULL,
  productid  INT NOT NULL,
  quantity   INT NOT NULL,
  unitprice  DECIMAL(10,2) NOT NULL,
  subtotal   AS (quantity * unitprice) PERSISTED,
  CONSTRAINT PK_ORDER_DETAILS_DETAILID PRIMARY KEY (detailid),
  CONSTRAINT FK_OD_ORDERS    FOREIGN KEY (orderid)   REFERENCES orders(orderid) ON DELETE CASCADE,
  CONSTRAINT FK_OD_PRODUCTS  FOREIGN KEY (productid) REFERENCES products(productid)
);
GO

/* -------------------- 8. inventory_movements -------------------- */
CREATE TABLE inventory_movements (
  movementid     INT IDENTITY(1,1) NOT NULL,
  productid      INT NOT NULL,
  sellerid       INT NULL,
  movement_type  VARCHAR(15) NOT NULL,
  quantity       INT NOT NULL,
  reason         VARCHAR(150),
  movement_date  DATETIME2 DEFAULT SYSDATETIME(),
  CONSTRAINT PK_INVMOV_ID      PRIMARY KEY (movementid),
  CONSTRAINT FK_INVMOV_PRODUCT FOREIGN KEY (productid) REFERENCES products(productid),
  CONSTRAINT FK_INVMOV_SELLER  FOREIGN KEY (sellerid)  REFERENCES sellers(sellerid)
);
GO

/* -------------------- 9. creditcards -------------------- */
CREATE TABLE creditcards (
  customerID        INT,
  creditcard        BIGINT,
  creditcard_type   VARCHAR(15),
  expiration_year   INT,
  expiration_month  INT,
  CONSTRAINT PK_CREDITCARDS_NUMBER PRIMARY KEY (creditcard),
  CONSTRAINT FK_CREDITCARDS_CUST   FOREIGN KEY (customerid) REFERENCES customers(customerid)
);
GO

/* -------------------- 10. invoices -------------------- */
CREATE TABLE invoices (
  invoiceid   INT IDENTITY(1,1) NOT NULL,
  orderid     INT,
  customerid  INT,
  creditcard  BIGINT,
  amount      DECIMAL(10,2),
  CONSTRAINT PK_INVOICES_INVOICEID  PRIMARY KEY (invoiceid),
  CONSTRAINT FK_INVOICES_ORDERS     FOREIGN KEY (orderid)    REFERENCES orders(orderid),
  CONSTRAINT FK_INVOICES_CUSTOMERS  FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_INVOICES_CREDITCARD FOREIGN KEY (creditcard) REFERENCES creditcards(creditcard)
);
GO

/* -------------------- 11. reviews -------------------- */
CREATE TABLE reviews (
  reviewID        INT IDENTITY(1,1) NOT NULL,
  productID       INT,
  reviewer_email  VARCHAR(50),
  starsgiven      INT,
  review_text     VARCHAR(200),
  CONSTRAINT PK_REVIEWS_REVIEWID PRIMARY KEY (reviewID),
  CONSTRAINT FK_REVIEWS_PRODUCTS FOREIGN KEY (productID) REFERENCES products(productID)
);
GO

/* -------------------- 12. recommendations -------------------- */
CREATE TABLE recommendations (
  recommendationid          INT IDENTITY(1,1) NOT NULL,
  customerid                INT,
  recommendation_productid  INT,
  CONSTRAINT PK_RECOMMENDATIONS_ID PRIMARY KEY (recommendationid),
  CONSTRAINT FK_REC_CUSTOMERS      FOREIGN KEY (customerid) REFERENCES customers(customerid),
  CONSTRAINT FK_REC_PRODUCTS       FOREIGN KEY (recommendation_productid) REFERENCES products(productid)
);
GO

/* -------------------- 13. audit_log -------------------- */
CREATE TABLE audit_log (
  audit_id    INT IDENTITY(1,1) PRIMARY KEY,
  table_name  VARCHAR(50)  NOT NULL,
  action      VARCHAR(20)  NOT NULL,
  record_id   INT,
  user_name   VARCHAR(50)  DEFAULT SUSER_SNAME(),
  action_date DATETIME2    DEFAULT SYSDATETIME(),
  old_values  NVARCHAR(MAX),
  new_values  NVARCHAR(MAX)
);
GO

PRINT '✅ BD OSF_ER creada. Ahora abre SSMS > OSF_ER > Database Diagrams > New Diagram.';
GO