CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[POST_HTML_MAIL]
(    @sender NVARCHAR(MAX),
    @recipient NVARCHAR(MAX),
    @cc_recipient NVARCHAR(MAX),
    @mailtype NVARCHAR(MAX),
    @subject NVARCHAR(MAX),
    @message NVARCHAR(MAX)
)
AS
DECLARE @mailhost NVARCHAR(30) = 'smtp.edah.org.tw';
DECLARE @mail_conn NVARCHAR(MAX);
DECLARE @crlf NVARCHAR(2) = CHAR(13) + CHAR(10);
DECLARE @errnum DECIMAL(38,10);
DECLARE @mesg NVARCHAR(MAX);
DECLARE @ErrorMessage NVARCHAR(500);
BEGIN
BEGIN TRY
    -- TODO(utl_smtp): SET @mail_conn = utl_smtp.open_connection(@mailhost, 25);
    -- TODO(oracle_pkg): utl_smtp.helo(@mail_conn, @mailhost);
    -- TODO(oracle_pkg): utl_smtp.mail(@mail_conn, @sender);
    -- TODO(oracle_pkg): utl_smtp.rcpt(@mail_conn, @recipient);
  
    SET @mesg = @message;
    -- TODO(oracle_pkg): UTL_SMTP.OPEN_DATA(@mail_conn);
    --主旨
    -- TODO(oracle_pkg): UTL_smtp.write_raw_data(@mail_conn,
    -- TODO(oracle_pkg): utl_raw.cast_to_raw('@subject: ' + @subject +
    -- TODO(oracle_pkg): CHAR(13)+CHAR(10)));
    --編碼
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn,
    -- TODO(oracle_pkg): 'Content-Type: text/html;charset=UTF-8' +
    -- TODO(oracle_pkg): CHAR(13)+CHAR(10));
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn,
    -- TODO(oracle_pkg): 'Content-Transfer-Encoding: base64' + CHAR(13)+CHAR(10));
  
    --寄件人
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn, 'From: ' + @sender + CHAR(13)+CHAR(10));
    --收件人
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn, 'To: ' + @recipient + CHAR(13)+CHAR(10));
      -- TODO(oracle_pkg): 'Cc: ' + @cc_recipient + CHAR(13)+CHAR(10));
  
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn, CHAR(13)+CHAR(10));
    -- TODO(oracle_pkg): UTL_SMTP.WRITE_DATA(@mail_conn,
    -- TODO(oracle_pkg): UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(@message))));
  
    -- TODO(oracle_pkg): UTL_SMTP.CLOSE_DATA(@mail_conn);
    -- TODO(oracle_pkg): UTL_SMTP.quit(@mail_conn);
END TRY
BEGIN CATCH
    -- WHEN OTHERS
      SET @errnum = ERROR_NUMBER();
      SET @ErrorMessage = ERROR_MESSAGE();
      INSERT INTO HRA_UNNORMAL_LOG
        (LOG_SEQ,
         PROG_NAME,
         SYS_DATE,
         LOG_CODE,
         LOG_MSG,
         LOG_INFO,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE)
      VALUES
        (FORMAT(GETDATE(), 'MMddhhmmss'),
         SUBSTRING(@subject, 1, 10),
         GETDATE(),
         @errnum,
         '[ehrphrafunc_pkg].[POST_HTML_MAIL寄送異常]',
         @recipient+','+@ErrorMessage,
         'MIS',
         GETDATE(),
         'MIS',
         GETDATE());
      COMMIT TRAN;
END CATCH
END
GO
