CREATE DATABASE ERP_DB
GO

USE ERP_DB;
GO

-- =========================
-- ORDERS
-- =========================
CREATE TABLE dbo.Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    RedQty INT NOT NULL,
    BlackQty INT NOT NULL,
    TotalQty INT NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    StartedDate DATETIME NULL,
    FinishedDate DATETIME NULL,
	QuantityProduced INT NOT NULL DEFAULT 0,
    QuantityProductFault INT NOT NULL DEFAULT 0,
    TimeSpentMinutes DECIMAL(10,2) NULL,
    TestPhase NVARCHAR(20) NULL
);
GO

-- =========================
-- ORDER CUPS
-- =========================
CREATE TABLE dbo.OrderCups (
    CupId INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    CupNo INT NOT NULL,
    Color NVARCHAR(10) NOT NULL,
    WaterPercent INT NOT NULL,
    WeightDifference real NULL,
    RealWeight real NULL,
    TimeSpentMinutes DECIMAL(10,2) NULL,
    CONSTRAINT FK_OrderCups_Orders
        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(OrderId)
);
GO