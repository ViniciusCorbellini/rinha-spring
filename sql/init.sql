CREATE TABLE IF NOT EXISTS accounts (
    id INT PRIMARY KEY,
    limite INT NOT NULL,
    balance INT NOT NULL,
    version INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS transactions (
    id BIGSERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(id),
    amount INT NOT NULL,
    type CHAR(1) NOT NULL CHECK (type IN ('c', 'd')),
    description VARCHAR(10) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_account_id_created_at
  ON transactions(account_id, created_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (SELECT * FROM accounts WHERE id BETWEEN 1 AND 5) THEN
    INSERT INTO accounts (id, limite, balance)
    VALUES
    (1, 100000, 0),
    (2, 80000, 0),
    (3, 1000000, 0),
    (4, 10000000, 0),
    (5, 500000, 0);
  END IF;
END;
$$;

-- Exemplo conceitual da função no Postgres
CREATE OR REPLACE FUNCTION realizar_transacao(
    p_account_id INT,
    p_valor INT,
    p_tipo CHAR(1),
    p_descricao VARCHAR(10)
)
RETURNS TABLE (novo_saldo INT, novo_limite INT) AS $$
DECLARE
    conta RECORD;
    v_novo_saldo INT;
BEGIN
    -- 1. Trava a linha e busca os dados
    SELECT balance, limite INTO conta FROM accounts WHERE id = p_account_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'CLIENTE_NAO_ENCONTRADO';
    END IF;

    -- 2. Lógica de negócio
    IF p_tipo = 'c' THEN
        v_novo_saldo := conta.balance + p_valor;
    ELSE
        v_novo_saldo := conta.balance - p_valor;
        IF v_novo_saldo < (conta.limite * -1) THEN
            RAISE EXCEPTION 'LIMITE_INDISPONIVEL';
        END IF;
    END IF;

    -- 3. Persiste os dados
    UPDATE accounts SET balance = v_novo_saldo WHERE id = p_account_id;
    INSERT INTO transactions (account_id, amount, type, description)
    VALUES (p_account_id, p_valor, p_tipo, p_descricao);

    -- 4. Retorna o resultado
    RETURN QUERY SELECT v_novo_saldo, conta.limite;
END;
$$ LANGUAGE plpgsql;