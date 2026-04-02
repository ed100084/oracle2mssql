
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$OFFREC_UNI_BACKUP'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$OFFREC_UNI_BACKUP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$OFFREC_UNI_BACKUP  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_STATUS varchar(max),
   @P_ITEM_TYPE varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      SET @RTNCODE = NULL

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @ICNT numeric(1)

      SET @RTNCODE = 0

      SELECT @ICNT = count_big(HRA_OFFREC.EMP_NO)
      FROM HRP.HRA_OFFREC
      WHERE 
         HRA_OFFREC.EMP_NO = @P_EMP_NO AND 
         HRA_OFFREC.START_DATE = ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd') AND 
         HRA_OFFREC.START_TIME = @P_START_TIME AND 
         HRA_OFFREC.STATUS = @P_STATUS AND 
         HRA_OFFREC.ITEM_TYPE = @P_ITEM_TYPE

      IF (@ICNT <> 0)
         BEGIN

            INSERT HRP.HRA_OFFREC_UNI(
               EMP_NO, 
               SEQ, 
               DEPT_NO, 
               START_DATE, 
               START_TIME, 
               END_DATE, 
               END_TIME, 
               OTM_HRS, 
               ORG_FEE, 
               REG_FEE, 
               OTM_REA, 
               REMARK, 
               STATUS, 
               PERMIT_ID, 
               PERMIT_DATE, 
               CREATED_BY, 
               CREATION_DATE, 
               LAST_UPDATED_BY, 
               LAST_UPDATE_DATE, 
               ITEM_TYPE, 
               TRN_YM, 
               ONCALL, 
               TRAFFIC_FEE, 
               CHECK_FLAG, 
               CHECK_POIN, 
               START_DATE_TMP, 
               CREATION_COMP, 
               LAST_UPDATED_COMP, 
               DISABLED, 
               DEPUTY, 
               HARM_MEAL_EXPENSE, 
               FOLLOW_DEPT_NO, 
               CHIEF_TRANS, 
               ABROAD)
                (
                  SELECT 
                     HRA_OFFREC.EMP_NO, 
                     isnull(
                        (
                           SELECT max(HRA_OFFREC_UNI.SEQ) + 1 AS expr
                           FROM HRP.HRA_OFFREC_UNI
                           WHERE 
                              HRA_OFFREC_UNI.EMP_NO = @P_EMP_NO AND 
                              HRA_OFFREC_UNI.START_DATE = ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd') AND 
                              HRA_OFFREC_UNI.START_TIME = @P_START_TIME AND 
                              HRA_OFFREC_UNI.STATUS = @P_STATUS AND 
                              HRA_OFFREC_UNI.ITEM_TYPE = @P_ITEM_TYPE
                        ), 1), 
                     HRA_OFFREC.DEPT_NO, 
                     HRA_OFFREC.START_DATE, 
                     HRA_OFFREC.START_TIME, 
                     HRA_OFFREC.END_DATE, 
                     HRA_OFFREC.END_TIME, 
                     HRA_OFFREC.OTM_HRS, 
                     HRA_OFFREC.ORG_FEE, 
                     HRA_OFFREC.REG_FEE, 
                     HRA_OFFREC.OTM_REA, 
                     HRA_OFFREC.REMARK, 
                     HRA_OFFREC.STATUS, 
                     HRA_OFFREC.PERMIT_ID, 
                     HRA_OFFREC.PERMIT_DATE, 
                     HRA_OFFREC.CREATED_BY, 
                     HRA_OFFREC.CREATION_DATE, 
                     HRA_OFFREC.LAST_UPDATED_BY, 
                     HRA_OFFREC.LAST_UPDATE_DATE, 
                     HRA_OFFREC.ITEM_TYPE, 
                     HRA_OFFREC.TRN_YM, 
                     HRA_OFFREC.ONCALL, 
                     HRA_OFFREC.TRAFFIC_FEE, 
                     HRA_OFFREC.CHECK_FLAG, 
                     HRA_OFFREC.CHECK_POIN, 
                     HRA_OFFREC.START_DATE_TMP, 
                     HRA_OFFREC.CREATION_COMP, 
                     HRA_OFFREC.LAST_UPDATED_COMP, 
                     HRA_OFFREC.DISABLED, 
                     HRA_OFFREC.DEPUTY, 
                     HRA_OFFREC.HARM_MEAL_EXPENSE, 
                     HRA_OFFREC.FOLLOW_DEPT_NO, 
                     HRA_OFFREC.CHIEF_TRANS, 
                     HRA_OFFREC.ABROAD
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     HRA_OFFREC.EMP_NO = @P_EMP_NO AND 
                     HRA_OFFREC.START_DATE = ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd') AND 
                     HRA_OFFREC.START_TIME = @P_START_TIME AND 
                     HRA_OFFREC.STATUS = @P_STATUS AND 
                     HRA_OFFREC.ITEM_TYPE = @P_ITEM_TYPE
                )

            DELETE HRP.HRA_OFFREC
            WHERE 
               HRA_OFFREC.EMP_NO = @P_EMP_NO AND 
               HRA_OFFREC.START_DATE = ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd') AND 
               HRA_OFFREC.START_TIME = @P_START_TIME AND 
               HRA_OFFREC.STATUS = @P_STATUS AND 
               HRA_OFFREC.ITEM_TYPE = @P_ITEM_TYPE

            IF @@TRANCOUNT > 0
               COMMIT TRANSACTION 

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.offrec_uni_backup',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$OFFREC_UNI_BACKUP'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
