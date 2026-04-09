CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[CheckMorning_mail]
AS
DECLARE @iCnt DECIMAL(38,10);
DECLARE @__mail_body NVARCHAR(MAX);
BEGIN
    BEGIN TRY
        SELECT @iCnt = COUNT(*)
        FROM HRA_UNNORMAL_LOG
        WHERE CAST(SYS_DATE AS DATE) = CAST(GETDATE() AS DATE);
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (1403, 100) BEGIN
            SET @iCnt = 0;
        END
    END CATCH
    --20220715僅確認收件者有行政長的一級主管假卡、醫師假卡、出國假卡三項通知
    IF @iCnt <> 0 BEGIN
      SET @__mail_body = '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' +
                     'SELECT * FROM HRA_UNNORMAL_LOG WHERE CAST(SYS_DATE AS DATE) = CAST(GETDATE() AS DATE;';
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', 'ed108482@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     @__mail_body;
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', 'ed108154@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     @__mail_body;
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', 'ed100037@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     @__mail_body;
    END

    EXEC [ehrphra7_pkg].[hra9000];
END
GO