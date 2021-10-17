create table ADMIN.CLIENTES
(
  nombre           VARCHAR2(50),
  apellido         VARCHAR2(50),
  edad             INTEGER,
  fecha_nacimiento DATE,
  id               INTEGER not null
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create unique index ADMIN.PK_CLIENTES on ADMIN.CLIENTES (ID)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );

create table ADMIN.TABLE_HOPE_LIVE
(
  x   NUMBER,
  nqx NUMBER,
  lx  NUMBER,
  d   NUMBER,
  nlx NUMBER,
  tx  NUMBER,
  ex  NUMBER
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );

create or replace package admin.PCK_INTERCORP_CLIENTES is

  -- Author  : MAURICIO ANGULO
  -- Created : 16/10/2021 10:36:28
  -- Purpose : 

  procedure PRC_CONSULTAR_CLIENTES(o_cursor  out sys_refcursor,
                                   o_retorno out integer,
                                   o_mensaje out varchar2,
                                   o_sqlerrm out varchar2);
  procedure PRC_INSERTAR_CLIENTES(i_nombre           in varchar2,
                                  i_apellido         in varchar2,
                                  i_edad             in integer,
                                  i_fecha_nacimiento in date,
                                  o_retorno          out varchar2,
                                  o_mensaje          out varchar2,
                                  o_sqlerrm          out varchar2);



procedure PRC_KPICLIENTES_DESVIACION_PROMEDIO(o_desviacion out NUMBER,
                                                o_promedio   out NUMBER,
                                                o_retorno    out varchar2,
                                                o_mensaje    out varchar2,
                                                o_sqlerrm    out varchar2);

end PCK_INTERCORP_CLIENTES;

create or replace noneditionable function admin.FNC_FECHA_PROBABLE_MUERTE(i_fecha_nacimiento IN VARCHAR2) return
  varchar2 is
meses_1 number := 0;
meses_2 NUMBER := 0;

anios number:=0;

tx_1 number:=0;
tx_2 number:=0;
lx_1 number:=0;
lx_2 number:=0;
x_1 number:=0;
x_2 number:=0;
d_1 number:=0;
d_2 number:=0;

begin
  meses_1 := FLOOR(MONTHS_BETWEEN(sysdate, to_date(i_fecha_nacimiento, 'DD/MM/RRRR')) / 12);
  meses_2 := MONTHS_BETWEEN(sysdate, to_date(i_fecha_nacimiento, 'DD/MM/RRRR'));
  anios:=meses_1 + ((meses_2 - (meses_1*12)) /12);

  select tx, lx, x, d into tx_1, lx_1, x_1, d_1 from
         (select * from TABLE_HOPE_LIVE where x<anios order by x desc) where rownum = 1;


  select tx, lx, x, d into tx_2, lx_2, x_2, d_2 from
         (select * from TABLE_HOPE_LIVE where x>anios order by x asc) where rownum = 1;

  d_1:=d_1 *  ((anios - x_1) / x_1);
  tx_1:=tx_1 - (lx_1 * ((anios-x_1)) / x_1);
  lx_1:=lx_1 - d_1;
RETURN to_char(sysdate + floor(round((tx_1 / lx_1) * 365)), 'dd/mm/yyyy');
end FNC_FECHA_PROBABLE_MUERTE;


create or replace package body admin.PCK_INTERCORP_CLIENTES is
  procedure PRC_CONSULTAR_CLIENTES(o_cursor  out sys_refcursor,
                                   o_retorno out integer,
                                   o_mensaje out varchar2,
                                   o_sqlerrm out varchar2) is
  begin
    o_mensaje := 'Consulta Efectuada Satisfactoriamente';
    o_retorno := 0;
    o_sqlerrm := 'Sin Errores';
  
    open o_cursor for
      select id,
             nombre,
             apellido,
             edad,
             to_date(fecha_nacimiento, 'DD/MM/RRRR') fecha_nacimiento,
             fnc_fecha_probable_muerte(to_char(fecha_nacimiento,
                                               'DD-MM-RRRR')) fecha_probable_muerte
        from clientes
       order by apellido asc, nombre asc;
  exception
    when others then
      o_mensaje := 'Se producto un error en la consulta';
      o_retorno := 1;
      o_sqlerrm := SQLCODE || ': ' || SQLERRM;
  end PRC_CONSULTAR_CLIENTES;



  procedure PRC_INSERTAR_CLIENTES(i_nombre           in varchar2,
                                  i_apellido         in varchar2,
                                  i_edad             in integer,
                                  i_fecha_nacimiento in date,
                                  o_retorno          out varchar2,
                                  o_mensaje          out varchar2,
                                  o_sqlerrm          out varchar2) is
    id integer := 0;
  begin
    o_mensaje := 'Inserción realizada satisfactoriamente';
    o_retorno := 0;
    o_sqlerrm := 'Sin errores';
  
    select nvl(max(id), 0) + 1 into id from clientes;
  
    insert into clientes
    values
      (i_nombre, i_apellido, i_edad, i_fecha_nacimiento, id);
  exception
    when others then
      rollback;
      o_mensaje := 'Se han producido errores al insertar registro';
      o_retorno := 1;
      o_sqlerrm := SQLCODE || ': ' || SQLERRM;
  end PRC_INSERTAR_CLIENTES;



  procedure PRC_KPICLIENTES_DESVIACION_PROMEDIO(o_desviacion out NUMBER,
                                                o_promedio   out NUMBER,
                                                o_retorno    out varchar2,
                                                o_mensaje    out varchar2,
                                                o_sqlerrm    out varchar2) IS
    cursor cursor_clientes is
      select edad from clientes where edad is not null;
    total_clientes integer := 0;
    resultado      number := 0;
  begin
    o_mensaje := 'El cálculo se ha obtenido correctamente';
    o_retorno := 0;
    o_sqlerrm := 'Sin Errores';
    begin
      select COUNT(1)
        into total_clientes
        from clientes
       where edad is not null;
      select AVG(edad) into o_promedio from clientes;
      for cliente in cursor_clientes loop
        resultado := resultado + power((o_promedio - cliente.edad), 2);
      end loop;
      resultado    := sqrt(resultado / o_promedio);
      o_desviacion := resultado;
    end;
  exception
    when others then
      resultado := 0;
      o_retorno := 1;
      o_mensaje := 'Ha ocurrido un error en el cálculo solicitado';
      o_sqlerrm := SQLCODE || ': ' || SQLERRM;
  end;
end PCK_INTERCORP_CLIENTES;


insert into TABLE_HOPE_LIVE values (0, 118.1, 100000, 11814, 94093.0, 4745726.0, 47.5);
insert into TABLE_HOPE_LIVE values (1, 99.8, 88186, 8801, 335142.0, 4651633.0, 52.7);
insert into TABLE_HOPE_LIVE values (5, 45.2, 79385, 3591, 387947.5, 4316491.0, 54.4);
insert into TABLE_HOPE_LIVE values (10, 45.5, 75794, 3449, 740695.0, 3928543.5, 51.8);
insert into TABLE_HOPE_LIVE values (20, 62.2, 72345, 4498, 700960.0, 3187848.5, 44.1);
insert into TABLE_HOPE_LIVE values (30, 82.2, 67846, 5577, 650585.0, 2486888.5, 36.7);
insert into TABLE_HOPE_LIVE values (40, 101.9, 62270, 6344, 590980.0, 1836303.5, 29.5);
insert into TABLE_HOPE_LIVE values (50, 154.0, 55926, 8612, 516200.0, 1245323.5, 22.3);
insert into TABLE_HOPE_LIVE values (60, 303.2, 47314, 14347, 401405.0, 729123.5, 15.4);
insert into TABLE_HOPE_LIVE values (70, 291.4, 32967, 9605, 140822.5, 327718.5, 9.9);
insert into TABLE_HOPE_LIVE values (75, 1000.0, 23362, 23362, 186896.0, 186896.0, 8.0);
commit;

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('SERGIO', 'ANGULO MARTINEZ', 50, to_date('11-03-1971', 'dd-mm-yyyy'), 3);

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('ALEJANDRO', 'ANGULO MARTINEZ', 50, to_date('16-11-1970', 'dd-mm-yyyy'), 4);

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('FARIDE', 'CONTRERAS CASIS', 41, to_date('16-06-1980', 'dd-mm-yyyy'), 5);

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('PAULO', 'ANGULO SIBAJA', 20, to_date('01-03-2001', 'dd-mm-yyyy'), 6);

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('MAURICIO', 'ANGULO MARTINEZ', 53, to_date('13-12-1967', 'dd-mm-yyyy'), 1);

insert into CLIENTES (NOMBRE, APELLIDO, EDAD, FECHA_NACIMIENTO, ID)
values ('FARIDE', 'DUARTE CONTRERAS', 15, to_date('04-07-2006', 'dd-mm-yyyy'), 2);
commit;
