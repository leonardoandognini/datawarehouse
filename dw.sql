2.1 – Inserir os clientes da Staging_Analise na tabela de dimensão criada para clientes;

CREATE procedure insere_clientes
as
begin

    insert into Cliente
    (id_cliente, nome_cliente, rua_cliente)
    SELECT sa.id_cliente, sa.nome_cliente, sa.rua_cliente
    FROM Staging_Analise sa
    GROUP BY sa.id_cliente, sa.nome_cliente, sa.rua_cliente
end

select * from Cliente
    exec insere_clientes


         2.2 – Inserir as cidades da Staging_Analise na tabela de dimensão criada para cidades;


    CREATE procedure insere_cidades
    as
    begin

        insert into Cidade
        (id_cidade, nome_cidade, estado_cidade)
        SELECT distinct sa.id_cidade, sa.nome_cidade, sa.estado_cidade
        FROM Staging_Analise sa

    end





    2.3 – Inserir as agencias da Staging_Analise na tabela de dimensão criada para agencias;

        CREATE procedure insere_agencias
        as
        begin

            insert into Agencia
            (id_agencia,nome_agencia)
            SELECT distinct sa.id_agencia, sa.nome_agencia
            FROM Staging_Analise sa
        end





        2.4 -  Inserir as datas da Staging_Analise na tabela de dimensão criada para periodos;


            CREATE PROCEDURE insere_periodos
            AS
            BEGIN
                INSERT INTO periodo
                (data,
                 dia,
                 mes,
                 ano,
                 trimestre,
                 semestre,
                 quinzena,
                 semana)
                SELECT distinct(sa.data_emprestimo)     AS DATA,
                               Day(sa.data_emprestimo)                   AS DIA,
                               Month(sa.data_emprestimo)                 AS MES,
                               Year(sa.data_emprestimo)                  AS ANO,
                               ( Month(sa.data_emprestimo) - 1 ) / 3 + 1 AS TRIMESTRE,
                               ( Month(sa.data_emprestimo) - 1 ) / 6 + 1 AS SEMESTRE,
                               CASE
                                   WHEN Day(sa.data_emprestimo) <= 15 THEN '1'
                                   ELSE '2'
                                   END                                       AS QUINZENA,
                               Datepart(weekday, sa.data_emprestimo)     AS SEMANA
                FROM   staging_analise sa
            END



            2.5 – Inserir registros na tabela Analise_Emprestimos (Cubo de dados) a partir da Staging_Analise;

                CREATE procedure insere_analise_emprestimos
                as
                begin

                    insert into analise_emprestimos
                    (id_emprestimo, data_emprestimo, total_emprestimo, id_cliente, id_cidade, id_agencia)
                    SELECT distinct sa.id_emprestimo, sa.data_emprestimo, sa.total_emprestimo, sa.id_cliente, sa.id_cidade, sa.id_agencia
                    FROM Staging_Analise sa

                end











                Atividade 3: (2,0 pontos)
Crie as seguintes triggers:
                    3.1- Ao incluir algum cliente novo na Staging_Analise, inserir na dimensão cliente do DW;


                    CREATE TRIGGER trg_cliente_novo
                        ON staging_analise
                        FOR INSERT
                        AS
                    BEGIN
                        DECLARE @id_cliente INT

                        SELECT @id_cliente = (SELECT id_cliente
                                              FROM   inserted)

                        IF ( (SELECT Count(c.id_cliente)
                              FROM   cliente c
                              WHERE  c.id_cliente = @id_cliente) = 0 )
                            BEGIN
                                INSERT INTO cliente
                                (id_cliente,
                                 nome_cliente,
                                 rua_cliente)
                                VALUES      ((SELECT id_cliente
                                              FROM   inserted),
                                             (SELECT nome_cliente
                                              FROM   inserted),
                                             (SELECT rua_cliente
                                              FROM   inserted) )
                            END
                    END






                    3.2- Ao incluir algum emprestimo novo na Staging_Analise, inserir na tabela Analise_emprestimos do DW;


                    --revisar
                    CREATE TRIGGER trg_analise_emprestimo
                        ON staging_analise
                        FOR INSERT
                        AS
                    BEGIN
                        DECLARE @id_emprestimo INT

                        SELECT @id_emprestimo = (SELECT id_emprestimo
                                                 FROM   inserted)

                        IF ( (SELECT Count(an.id_emprestimo)
                              FROM   analise_emprestimos an
                              WHERE  an.id_emprestimo = @id_emprestimo) = 0 )
                            BEGIN
                                INSERT INTO analise_emprestimos
                                (id_emprestimo,
                                 data_emprestimo,
                                 total_emprestimo,
                                 id_cliente,
                                 id_cidade,
                                 id_agencia)
                                VALUES      ((SELECT id_emprestimo
                                              FROM   inserted),
                                             (SELECT data_emprestimo
                                              FROM   inserted),
                                             (SELECT total_emprestimo
                                              FROM   inserted),
                                             (SELECT id_cliente
                                              FROM   inserted),
                                             (SELECT id_cidade
                                              FROM   inserted),
                                             (SELECT id_agencia
                                              FROM   inserted)

                                            )
                            END
                    END




                    3.3- Ao alterar algum valor na Staging_Analise, atualizar o to na Analise_emprestimo (Cubo de Dados)

                    create trigger trg_alt_analise_titulos
                        on staging_analise
                        for update
                        as
                    begin
                        declare @id_emprestimo	INT
                        SELECT @id_emprestimo =
                               (select id_emprestimo from inserted)

                        IF (
                                (SELECT Count(an.id_emprestimo)
                                 FROM   analise_emprestimos an
                                 WHERE  an.id_emprestimo = @id_emprestimo)>0)
                            begin
                                update analise_emprestimos set
                                    total_emprestimo=(select total_emprestimo from inserted)
                                where
                                        id_emprestimo = @id_emprestimo
                            end
                    end





                    3.4- Ao excluir algum registro na Staging_Analise, excluir o registro na Analise_emprestimo (Cubo de Dados)

                    create trigger trg_del_analise_titulos
                        on staging_analise
                        for delete
                        as
                    begin
                        declare @id_emprestimo	INT

                        SELECT @id_emprestimo =  (select id_emprestimo from deleted)

                        IF (
                                (SELECT Count(an.id_emprestimo)
                                 FROM   analise_emprestimos an
                                 WHERE  an.id_emprestimo = @id_emprestimo)>0)
                            begin
                                delete from analise_emprestimos
                                where
                                        id_emprestimo = @id_emprestimo
                            end
                    end














                    Atividade 4: (2,5 pontos)
Criar as seguintes views:
                    4.1 – Emprestimo por Agencia no periodo solicitado (data inicial e final)

                    CREATE VIEW v_emp_agencia AS

                    SELECT sa.nome_agencia, ae.data_emprestimo, ae.total_emprestimo
                    FROM Analise_emprestimos ae
                             LEFT JOIN Staging_Analise sa ON ae.id_emprestimo = sa.id_emprestimo

                    create procedure sp_emp_agencia
                        @data_ini datetime,
                        @data_fim datetime
                    as
                    begin
                        select * from v_emp_agencia data_emprestimo where data_emprestimo between @data_ini AND @data_fim;
                    end



                    4.2 – Clientes devedores em ordem alfabética agrupados por cidade (solicitar data inicial e final)

                        CREATE VIEW v_cli_dev_cid AS
                        SELECT c.nome_cliente,
                               ci.nome_cidade,
                               ae.total_emprestimo,
                               ae.data_emprestimo
                        FROM   analise_emprestimos ae
                                   LEFT JOIN cliente c
                                             ON ae.id_cliente = c.id_cliente
                                   LEFT JOIN cidade ci
                                             ON ae.id_cidade = ci.id_cidade
                        GROUP  BY ci.nome_cidade,
                                  c.nome_cliente,
                                  ae.total_emprestimo,
                                  ae.data_emprestimo



                        create procedure sp_cli_dev_cid
                            @data_ini datetime,
                            @data_fim datetime
                        as
                        begin
                            select * from v_cli_dev_cid where data_emprestimo between @data_ini AND @data_fim;
                        end

                            exec sp_cli_dev_cid '1/11/2014', '26/11/2014';



                            4.3 – Clientes cuja divida seja maior que a média do valor emprestado aos demais clientes

                            create view v_div_val_media_emp
                            as
                            select  c.nome_cliente, ae.total_emprestimo from Cliente c
                                                                                 left join analise_emprestimos ae ON C.id_cliente = ae.id_cliente
                            where ae.total_emprestimo > (select AVG(ae.total_emprestimo) from analise_emprestimos ae)

                        select * from v_div_val_media_emp


                            4.4 – Emprestimos Realizados por Mes e Ano

                            create view v_emp_mes_ano
                            as
                            select month(ae.data_emprestimo) as 'Mês', year(ae.data_emprestimo) as 'Ano', count(ae.id_emprestimo) as 'Qtd Emprestimos'
                            from analise_emprestimos ae
                            group by month(ae.data_emprestimo), year(ae.data_emprestimo)

                        select * from v_emp_mes_ano


                            4.5 – Emprestimos Realizados por mês e por Agencia em ano a ser solicitado (solicitar ano)


                            create view v_emp_mes_agencia
                            as
                            select a.nome_agencia as Agências, count(ae.id_emprestimo) as 'Qtd Emprestimos', month(ae.data_emprestimo) as 'Mês', year(ae.data_emprestimo) as 'Ano'
from analise_emprestimos ae left join Agencia a ON A.id_agencia = ae.id_agencia
group by a.nome_agencia, month(ae.data_emprestimo), year(ae.data_emprestimo)

                        select * from v_emp_mes_agencia

                            create procedure sp_emp_mes_agencia
                            @ano int
                            as
                            begin
                                select * from v_emp_mes_agencia where Ano = @ano
                            end

                                exec sp_emp_mes_agencia 2015

