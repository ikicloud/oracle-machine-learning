

create user POCOML identified by "4Dm1n4Dm1n123!"; 

grant connect, resource to POCOML; 

alter user POCOML quota unlimited on DATA; 


BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE POCOML.SALES_RAW PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE POCOML.SALES_RAW (
  id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product   VARCHAR2(50) NOT NULL,
  year_val  NUMBER(4)    NOT NULL,
  month_val NUMBER(2)    NOT NULL,
  units     NUMBER(10,2) NOT NULL
);
