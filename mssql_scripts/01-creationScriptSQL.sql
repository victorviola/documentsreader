CREATE DATABASE iProov_DocumentsReaderDB;
GO

USE iProov_DocumentsReaderDB;
GO

-- SourcePhotoEnum
CREATE TABLE SourcePhotoEnum (
    [index] INT PRIMARY KEY,
    [source] VARCHAR(50) NOT NULL
);
GO

-- UserData
CREATE TABLE UserData (
    id INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(100),
    [company] VARCHAR(100),
    [email] VARCHAR(100) NOT NULL,
    emailCode CHAR(5) NULL,
    isEmailVerified BIT NOT NULL DEFAULT 0,
    retriesLeft TINYINT NOT NULL DEFAULT 3 CHECK (retriesLeft IN (0, 1, 2, 3)),
    dateCreated DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_UserData_Email UNIQUE ([email])
);
GO



-- UserApp
CREATE TABLE UserApp (
    userId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    userDataId INT NOT NULL,
    isActive BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_UserApp_UserData FOREIGN KEY (userDataId)
        REFERENCES UserData(id)
);
GO

-- TokenTypeEnum
CREATE TABLE TokenTypeEnum (
    name VARCHAR(10) PRIMARY KEY
);
GO

-- Token
CREATE TABLE Token (
    id INT IDENTITY(1,1) PRIMARY KEY,
    userId UNIQUEIDENTIFIER NOT NULL,
    token VARCHAR(255) NOT NULL,
    type VARCHAR(10) NOT NULL,
    dateCreated DATETIME2 NOT NULL DEFAULT GETDATE(),
    tokenUsed BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Token_User FOREIGN KEY (userId)
        REFERENCES UserApp(userId),
    CONSTRAINT FK_Token_Type FOREIGN KEY (type)
        REFERENCES TokenTypeEnum(name)
);
GO

-- Documents
CREATE TABLE Documents (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    link VARCHAR(MAX) NOT NULL
);
GO

CREATE TABLE VerifyTokenCode (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    code CHAR(5) NOT NULL,
    dateCreated DATETIME2 NOT NULL DEFAULT GETDATE(),
    isConfirmed BIT NOT NULL DEFAULT 0
);
GO

CREATE UNIQUE INDEX UQ_VerifyTokenCode_Email_Active
ON VerifyTokenCode(email)
WHERE isConfirmed = 0;
GO


-- Dados iniciais
INSERT INTO TokenTypeEnum (name)
VALUES ('Enrol'), ('Verify');
GO

INSERT INTO SourcePhotoEnum ([index], [source])
VALUES (0, 'eid'), (1, 'oid'), (2, 'selfie');
GO

INSERT INTO Documents (title, link)
VALUES 
  ('Frankenstein', 'https://www.agr-tc.pt/bibliotecadigital/aetc/download/565/Frankenstein%20-%20Mary%20Shelley.pdf'),
  ('Beowulf', 'https://tile.loc.gov/storage-services/public/gdcmassbookdig/beowulfanglosaxo00hall/beowulfanglosaxo00hall.pdf'),
  ('Hamlet', 'https://socrates.acadiau.ca/courses/engl/rcunningham/resources/Shpe/Hamlet.pdf'),
  ('The Rime of The Ancient Mariner', 'https://resources.saylor.org/wwwresources/archived/site/wp-content/uploads/2014/05/ENGL404-Coleridge-The-Rime-of-the-Ancient-Mariner.pdf');
GO

-- Trigger para impedir alteração do campo dateCreated
CREATE TRIGGER trg_PreventDateCreatedUpdate
ON UserData
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(dateCreated)
    BEGIN
        RAISERROR ('dateCreated cannot be updated.', 16, 1);
        RETURN;
    END

    UPDATE ud
    SET
        [name] = inserted.[name],
        [company] = inserted.[company],
        [email] = inserted.[email],
        emailCode = inserted.emailCode,
        isEmailVerified = inserted.isEmailVerified
    FROM UserData ud
    INNER JOIN inserted ON ud.id = inserted.id;
END;
GO