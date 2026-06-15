-- ===========================================================================
-- 1. CRIAÇÃO DAS TABELAS (ESTRUTURA DDL)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS BLOCO (
    id_bloco SERIAL PRIMARY KEY,  
    nome_bloco VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS SALA (
    id_sala SERIAL PRIMARY KEY,  
    numero_sala INT NOT NULL,  
    Capacidade INT NOT NULL,  
    tipo_sala VARCHAR(50) NOT NULL,  
    id_bloco INT,
    FOREIGN KEY (id_bloco) REFERENCES BLOCO (id_bloco) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS USUARIO (
    id_usuario SERIAL PRIMARY KEY,  
    nome VARCHAR(100) NOT NULL,  
    CPF VARCHAR(11) UNIQUE NOT NULL,  
    email VARCHAR(100) NOT NULL,  
    tipo_usuario VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS PROFESSOR (
    id_usuario INT PRIMARY KEY,  
    Siape VARCHAR(20) UNIQUE NOT NULL,  
    FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ALUNO (
    id_usuario INT PRIMARY KEY,  
    Matricula VARCHAR(20) UNIQUE NOT NULL,  
    FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS RESERVA (
    id_reserva SERIAL PRIMARY KEY,  
    Data_reserva DATE NOT NULL,  
    Horario_inicio TIME NOT NULL,  
    Horario_fim TIME NOT NULL,  
    Status VARCHAR(20) NOT NULL,  
    id_usuario INT NOT NULL,  
    id_sala INT NOT NULL,  
    FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario) ON DELETE RESTRICT,
    FOREIGN KEY (id_sala) REFERENCES SALA (id_sala) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS OCORRENCIA (
    id_reserva INT,  
    id_ocorrencia INT,  
    Descricao VARCHAR(1000) NOT NULL,  
    Data_registro DATE NOT NULL,  
    PRIMARY KEY (id_reserva, id_ocorrencia),  
    FOREIGN KEY (id_reserva) REFERENCES RESERVA (id_reserva) ON DELETE CASCADE
);

-- ===========================================================================
-- 2. CRIAÇÃO DE VIEWS (CONSULTAS PRONTAS)
-- ===========================================================================

CREATE OR REPLACE VIEW v_relatorio_reservas AS
SELECT r.id_reserva, u.nome AS nome_solicitante, s.numero_sala, b.nome_bloco, r.Data_reserva, r.Horario_inicio, r.Horario_fim, r.Status
FROM RESERVA r
INNER JOIN USUARIO u ON r.id_usuario = u.id_usuario
INNER JOIN SALA s ON r.id_sala = s.id_sala
INNER JOIN BLOCO b ON s.id_bloco = b.id_bloco;

CREATE OR REPLACE VIEW v_detalhes_ocorrencias AS
SELECT o.id_reserva, s.numero_sala, o.Descricao, o.Data_registro
FROM OCORRENCIA o
INNER JOIN RESERVA r ON o.id_reserva = r.id_reserva
INNER JOIN SALA s ON r.id_sala = s.id_sala;

CREATE OR REPLACE VIEW v_perfil_alunos AS
SELECT u.id_usuario, u.nome, u.email, a.Matricula FROM USUARIO u
INNER JOIN ALUNO a ON u.id_usuario = a.id_usuario;

CREATE OR REPLACE VIEW v_perfil_professores AS
SELECT u.id_usuario, u.nome, u.email, p.Siape FROM USUARIO u
INNER JOIN PROFESSOR p ON u.id_usuario = p.id_usuario;

CREATE OR REPLACE VIEW v_salas_por_bloco AS
SELECT b.nome_bloco, s.numero_sala, s.Capacidade FROM BLOCO b
LEFT JOIN SALA s ON b.id_bloco = s.id_bloco;

-- ===========================================================================
-- 3. PROGRAMAÇÃO DE TRIGGERS (FUNÇÕES E GATILHOS AUTOMÁTICOS)
-- ===========================================================================

CREATE OR REPLACE FUNCTION fn_valida_horario_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Horario_fim <= NEW.Horario_inicio THEN
        RAISE EXCEPTION 'Erro: O horário de término não pode ser menor ou igual ao horário de início.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_valida_horario_reserva
BEFORE INSERT OR UPDATE ON RESERVA
FOR EACH ROW EXECUTE FUNCTION fn_valida_horario_reserva();

CREATE OR REPLACE FUNCTION fn_checa_conflito_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM RESERVA
        WHERE id_sala = NEW.id_sala AND Data_reserva = NEW.Data_reserva AND Status = 'Confirmada'
          AND ((NEW.Horario_inicio >= Horario_inicio AND NEW.Horario_inicio < Horario_fim) OR
               (NEW.Horario_fim > Horario_inicio AND NEW.Horario_fim <= Horario_fim) OR
               (NEW.Horario_inicio <= Horario_inicio AND NEW.Horario_fim >= Horario_fim))
    ) THEN
        RAISE EXCEPTION 'Conflito: Esta sala já está reservada para este dia e horário!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_checa_conflito_reserva
BEFORE INSERT ON RESERVA
FOR EACH ROW EXECUTE FUNCTION fn_checa_conflito_reserva();

-- ===========================================================================
-- 4. CRIAÇÃO DE STORED PROCEDURES (PROCEDIMENTOS ARMAZENADOS)
-- ===========================================================================

CREATE OR REPLACE PROCEDURE sp_cancelar_reserva(p_id_reserva INT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE RESERVA SET Status = 'Cancelada' WHERE id_reserva = p_id_reserva;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_inserir_sala(p_numero INT, p_cap INT, p_tipo VARCHAR, p_bloco INT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO SALA (numero_sala, Capacidade, tipo_sala, id_bloco) 
    VALUES (p_numero, p_cap, p_tipo, p_bloco);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_atualizar_email(p_id_usuario INT, p_novo_email VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE USUARIO SET email = p_novo_email WHERE id_usuario = p_id_usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_remover_ocorrencia(p_id_reserva INT, p_id_oc INT)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM OCORRENCIA WHERE id_reserva = p_id_reserva AND id_ocorrencia = p_id_oc;
END;
$$;

-- ===========================================================================
-- 5. POPULANDO O BANCO DE DADOS (SEEDERS / MASSA DE TESTES)
-- ===========================================================================

INSERT INTO BLOCO (nome_bloco) VALUES ('Bloco A'), ('Bloco B'), ('Bloco Pós-Graduação');

INSERT INTO SALA (numero_sala, Capacidade, tipo_sala, id_bloco) VALUES 
(101, 40, 'Comum', 1), (102, 35, 'Laboratório de Informática', 1), (201, 50, 'Auditório', 2);

INSERT INTO USUARIO (nome, CPF, email, tipo_usuario) VALUES 
('Carlos Melo', '11122233344', 'carlos.melo@upe.br', 'Professor'),
('Beatriz Silva', '55566677788', 'beatriz.silva@upe.br', 'Aluno'),
('Administrador Geral', '00000000000', 'admin@upe.br', 'Servidor');

INSERT INTO PROFESSOR (id_usuario, Siape) VALUES (1, 'SIAPE12345');
INSERT INTO ALUNO (id_usuario, Matricula) VALUES (2, 'MAT2026001');

INSERT INTO RESERVA (Data_reserva, Horario_inicio, Horario_fim, Status, id_usuario, id_sala) VALUES 
('2026-06-20', '08:00:00', '10:00:00', 'Confirmada', 1, 2),
('2026-06-21', '14:00:00', '16:00:00', 'Pendente', 2, 1);

INSERT INTO OCORRENCIA (id_reserva, id_ocorrencia, Descricao, Data_registro) VALUES 
(1, 1, 'Ar condicionado da sala de informática não está gelando.', '2026-06-20');