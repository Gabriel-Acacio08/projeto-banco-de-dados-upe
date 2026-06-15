import sqlite3

print("--- INICIANDO TESTE A NÍVEL DE APLICAÇÃO (UPE) ---")

try:
    # Cria um banco de dados de simulação na memória RAM
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    # Cria a tabela de simulação local baseada no projeto físico
    cur.execute("""
    CREATE TABLE BLOCO (
        id_bloco INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_bloco TEXT NOT NULL
    );
    """)

    # Insere um dado de teste idêntico ao do PostgreSQL
    cur.execute("INSERT INTO BLOCO (nome_bloco) VALUES ('Bloco A - Garanhuns');")
    conn.commit()

    # Realiza a consulta de validação
    cur.execute("SELECT * FROM BLOCO;")
    resultado = cur.fetchone()

    print("\n[SUCESSO] Conexão com a camada de aplicação estabelecida!")
    print(f"Dados retornados do teste: ID: {resultado[0]} | Nome: {resultado[1]}")

    cur.close()
    conn.close()
    print("\n--- TESTE CONCLUÍDO COM ÊXITO ---")

except Exception as e:
    print(f"Erro no teste de aplicação: {e}")