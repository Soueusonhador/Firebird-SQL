-- Avaliação de nivelamento DBA FIREBIRD



-- Crie uma tabela para armazenar o cadastro das cidades: Código, Nome da Cidade e UF

CREATE TABLE Cidades (
    Codigo INT NOT NULL PRIMARY KEY,
    NomeCidade VARCHAR(255) NOT NULL,
    UF CHAR(2) NOT NULL
);


-- Criar uma tabela para cadastro de clientes com as seguintes informações:
-- Código, Nome, Data de Nascimento, Endereço, Número, Complemento, Bairro,
-- Cidade, CEP, Usuário de Cadastro, Data/Hora de Cadastro e Data/Hora da última alteração;

CREATE TABLE Clientes (
    Codigo INT NOT NULL PRIMARY KEY,
    Nome VARCHAR(255) NOT NULL,
    DataNascimento DATE,
    Endereco VARCHAR(255),
    Numero VARCHAR(10),
    Complemento VARCHAR(50),
    Bairro VARCHAR(100),
    Cidade VARCHAR(100),
    CEP VARCHAR(10),
    UsuarioCadastro VARCHAR(50),
    DataHoraCadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    DataHoraUltimaAlteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


--Nos campos de Código implementar via trigger no banco de dados uma rotina para buscar o mesmo automaticamente valores (auto-incremento).

-- criando a Sequencia que acumulará os códigos em sequencia

CREATE SEQUENCE SeqCodigoCliente;

-- criando a proc Before Insert para chamar a Seq
    SET TERM ^ ;

CREATE TRIGGER Cliente_BI FOR Clientes
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  NEW.Codigo = NEXT VALUE FOR SeqCodigoCliente;
END^

SET TERM ; ^


-- Demonstrar comandos de inserção, alteração e exclusão de dados para as tabelas criadas.

-- Tabela Clientes

INSERT INTO Clientes (Nome, DataNascimento, Endereco, Numero, Complemento, Bairro, Cidade, CEP, UsuarioCadastro)
VALUES ('Régnier Oliveira', '1995-01-18', 'Atilio Valentini', '1285', 'Apto 102', 'Santa Monica', 'Uberlandia', '38408214', 'regnier');

UPDATE Clientes SET Nome = 'Régnier Oliveira', Endereco = 'Atilio Valentini' WHERE Codigo = 1;


DELETE FROM Clientes WHERE Codigo = 1;

-- Tabela Cidades

INSERT INTO Cidades (Codigo, NomeCidade, UF)
VALUES (1, 'Rio de Janeiro', 'RJ');


UPDATE Cidades
SET NomeCidade = 'Uberlandia', UF = 'MG' WHERE Codigo = 1;


DELETE FROM Cidades WHERE Codigo = 1;



-- Fazer uma consulta que mostre as cidades e a quantidade de clientes cadastrados.
-- Nessa consulta precisamos de um filtro que retorne só a cidade que tenha entre X a Y pessoas cadastradas.

SELECT
    Cidade, COUNT(*) AS QuantidadeClientes FROM Clientes
GROUP BY
    Cidade
HAVING
    QuantidadeClientes BETWEEN X AND Y;


    -- Fazer uma consulta para retornar o Mês, quantidade de aniversariantes do mês e uma lista com código do cliente.

    SELECT
    EXTRACT(MONTH FROM DataNascimento) AS MesAniversario,
    COUNT(*) AS QuantidadeAniversariantes,
    LIST(Codigo) AS CodigosAniversariantes
FROM
    Clientes
GROUP BY
    EXTRACT(MONTH FROM DataNascimento)
ORDER BY
    MesAniversario;



--Montar uma procedure no banco de dados que retorne em um campo apenas as informações do cadastro de cliente de acordo
--Código do cliente;Nome do Cliente; Complemento; Nome da Cidade;
--Nome do Usuário de inclusão; Data de cadastro
--Nesse leiaute separador ponto e virgula (“;”) para identificar as
--colunas, caso não possua informação deixar um espaço (" "), essa
--validação pode ser feita apenas no campo Complemento.




SET TERM ^ ;

CREATE OR ALTER PROCEDURE RetornaCadastroCliente
RETURNS (
    Resultado VARCHAR(1000)
)
AS
DECLARE VARIABLE CodigoCliente INT;
DECLARE VARIABLE NomeCliente VARCHAR(255);
DECLARE VARIABLE Complemento VARCHAR(50);
DECLARE VARIABLE NomeCidade VARCHAR(100);
DECLARE VARIABLE NomeUsuarioCadastro VARCHAR(50);
DECLARE VARIABLE DataCadastro DATE;
BEGIN
    FOR SELECT
        Codigo,
        Nome,
        Complemento,
        Cidade,
        UsuarioCadastro,
        DataHoraCadastro
    FROM
        Clientes
    INTO
        :CodigoCliente,
        :NomeCliente,
        :Complemento,
        :NomeCidade,
        :NomeUsuarioCadastro,
        :DataCadastro
    DO
    BEGIN
        -- Validar se o campo Complemento é nulo ou vazio e substituir por um espaço
        IF (COALESCE(:Complemento, '') = '') THEN
            :Complemento = ' ';

        -- Construir o resultado no formato especificado
        :Resultado = :Resultado || :CodigoCliente || ';' ||
                     :NomeCliente || ';' ||
                     :Complemento || ';' ||
                     :NomeCidade || ';' ||
                     :NomeUsuarioCadastro || ';' ||
                     CAST(:DataCadastro AS VARCHAR(10)) || CHR(13) || CHR(10); -- Quebra de linha
        SUSPEND;
    END
END^

SET TERM ; ^





-- Cria uma tabela para registrar uma dívida do cliente implementar uma trigger ao inserir gravar numa segunda tabela 

--  criando as tabelas 

CREATE TABLE Divida (
    ID INT NOT NULL PRIMARY KEY,
    Cliente VARCHAR(100) NOT NULL,
    DataCadastro DATE NOT NULL,
    ValorTotal DECIMAL(10, 2) NOT NULL,
    DiaVencimento INT NOT NULL,
    MesInicioCobranca INT NOT NULL,
    AnoInicioCobranca INT NOT NULL,
    NumParcelas INT NOT NULL
);

CREATE TABLE Parcelamento (
    ID INT NOT NULL PRIMARY KEY,
    DividaID INT NOT NULL,
    NumParcela INT NOT NULL,
    DataVencimento DATE NOT NULL,
    ValorParcela DECIMAL(10, 2) NOT NULL,
    Status INT NOT NULL
);

-- trigger 

SET TERM ^ ;

CREATE OR ALTER TRIGGER Divida_BI FOR Divida
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.NumParcelas > 0) THEN
  BEGIN
    FOR I FROM 1 TO NEW.NumParcelas DO
    BEGIN
      INSERT INTO Parcelamento (DividaID, NumParcela, DataVencimento, ValorParcela, Status)
      VALUES (
          NEW.ID,
          I,
          DATEADD(MONTH, I - 1, CAST(NEW.AnoInicioCobranca || '-' || NEW.MesInicioCobranca || '-' || NEW.DiaVencimento AS DATE)),
          NEW.ValorTotal / NEW.NumParcelas,
          0
      );
    END
  END
END^

SET TERM ; ^
