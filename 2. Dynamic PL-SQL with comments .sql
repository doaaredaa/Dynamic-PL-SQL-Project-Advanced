SET SERVEROUTPUT ON
DECLARE
               CURSOR SEQ_CURSOR IS

                SELECT CON.TABLE_NAME, CON.CONSTRAINT_TYPE, TAB.COLUMN_NAME,  TAB.DATA_TYPE
                FROM USER_CONSTRAINTS CON, USER_TAB_COLUMNS TAB,USER_CONS_COLUMNS COL
                WHERE CON.CONSTRAINT_NAME =  COL.CONSTRAINT_NAME 
                AND COL.COLUMN_NAME =  TAB.COLUMN_NAME
                AND  COL.TABLE_NAME=TAB.TABLE_NAME
                AND CON.CONSTRAINT_TYPE  ='P'
                AND TAB.DATA_TYPE ='NUMBER'
                AND CON.TABLE_NAME NOT IN (
                                        -- HERE I EXCLUDE ANY COMPOSITE PK FOUNDED.
                                        SELECT CON.TABLE_NAME
                                        FROM USER_CONSTRAINTS CON, USER_TAB_COLUMNS TAB,USER_CONS_COLUMNS COL
                                        WHERE CON.CONSTRAINT_NAME =  COL.CONSTRAINT_NAME 
                                        AND COL.COLUMN_NAME =  TAB.COLUMN_NAME
                                        AND  COL.TABLE_NAME=TAB.TABLE_NAME
                                        AND CON.CONSTRAINT_TYPE  ='P'
                                        GROUP BY CON.TABLE_NAME
                                        HAVING COUNT(CON.CONSTRAINT_NAME)  > 1 );
             ---------------------------------
              V_NO_OF_SEQs NUMBER;
              V_STARTING_SEQ_VALUE NUMBER;
 
-----------------------------------------------------------------------------------------
BEGIN
            FOR SEQ_RECORD IN SEQ_CURSOR LOOP
            
                --CALCULATE STARTING VALUE OF SEQUENCE.
                EXECUTE IMMEDIATE
                'SELECT NVL(MAX(' || SEQ_RECORD.COLUMN_NAME || '), 0) + 1 ' ||
                'FROM ' || SEQ_RECORD.TABLE_NAME
                INTO V_STARTING_SEQ_VALUE;

                --------------------------------------------------
                
                 --CHECK IF SEQUENCE IS EXSIST OR NOT.
                 SELECT COUNT(SEQUENCE_NAME)
                 INTO V_NO_OF_SEQs
                 FROM USER_SEQUENCES
                 WHERE UPPER(SEQUENCE_NAME) =  UPPER(SEQ_RECORD.TABLE_NAME ||  '_SEQ' );   
                    --Sequence names are case-sensitive
                --IF SEQUENCE ISEXSIST DROP IT      
                IF V_NO_OF_SEQs > 0 THEN

                    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || SEQ_RECORD.TABLE_NAME ||  '_SEQ';
                    
                END IF;
               -------------------------------------------------
               
                    -- CREATE SEQUENCE FOR EACH TABLE DYNAMICALLY
                    EXECUTE IMMEDIATE
                 '   CREATE SEQUENCE ' || SEQ_RECORD.TABLE_NAME ||  '_SEQ' ||
                 '   START WITH  ' || V_STARTING_SEQ_VALUE ||
                 '   INCREMENT BY 1';
            -----------------------------------------------------------------------------------------------         
                    -- CREATE OR REPLACE TRIGGER 
                    EXECUTE IMMEDIATE
                '   CREATE OR REPLACE TRIGGER  ' || SEQ_RECORD.TABLE_NAME ||  '_TRG' ||
                '   BEFORE INSERT ' ||
                '   ON ' || SEQ_RECORD.TABLE_NAME ||
                '   REFERENCING NEW AS New OLD AS Old ' ||
                '   FOR EACH ROW ' ||
                    ------------
                '    BEGIN  ' || 
                        '  IF :NEW.' || SEQ_RECORD.COLUMN_NAME || ' IS NULL THEN ' ||
                        --IF HERE FOR VALIDATION.
                        -- HERE I USED IF CONDITION TO AVOID ANY OVERWRITE IN PK,, IF I INSERTED DATA MANULY I WILL REMOVE THE DATA AND USE SEQ AND ITS WRONG , SHOULD KEEP USER DATA.
                             ' :NEW.' ||SEQ_RECORD.COLUMN_NAME || ' := ' || SEQ_RECORD.TABLE_NAME || '_SEQ.NEXTVAL; ' ||
                       '    END IF; ' ||

               '      END;' ;
                                     -- THIS PRINT IF SEQ &  TRG IS SUCCESSFULLY CREATED.
                                      DBMS_OUTPUT.PUT_LINE('Sequence ' || SEQ_RECORD.TABLE_NAME || '_SEQ and Trigger ' || SEQ_RECORD.TABLE_NAME || '_TRG created Successfully.'); 
                    END LOOP;     
                    

END;
/
