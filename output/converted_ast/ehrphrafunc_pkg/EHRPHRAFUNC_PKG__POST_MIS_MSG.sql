CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[POST_MIS_MSG]
(    @msgno NVARCHAR(MAX),
    @sender NVARCHAR(MAX),
    @recipient NVARCHAR(MAX),
    @subject NVARCHAR(MAX),
    @message NVARCHAR(MAX),
    @msgdate NVARCHAR(MAX)
)
AS
DECLARE @organtype NVARCHAR(10);
BEGIN
    BEGIN TRY
    SELECT @organtype = ORGAN_TYPE
    FROM HRE_EMPBAS
     WHERE EMP_NO = @recipient;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @organtype = 'ED';
END CATCH
    INSERT INTO PUS_MSGMST
      (MSG_NO, MSG_FROM, MSG_TO, subject, MSG_DESC, MSG_DATE, ORG_BY, ORGAN_TYPE)
    VALUES
      (@msgno,
       @sender,
       @recipient,
       @subject,
       @message,
       CONVERT(DATETIME2, @msgdate),
       @organtype, @organtype);
    INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE) VALUES (@msgno, @recipient, @organtype, @organtype);
    COMMIT TRAN;
END
GO
