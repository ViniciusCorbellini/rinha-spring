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

CREATE OR REPLACE FUNCTION obter_extrato(p_account_id INT)
RETURNS TABLE (
    total NUMERIC,
    limite NUMERIC,
    data_extrato TIMESTAMP WITH TIME ZONE,
    ultimas_transacoes JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.balance,
        a.limite,
        now(),
        COALESCE(
            (SELECT
                json_agg(json_build_object(
                    'valor', t.amount,
                    'tipo', t.type,
                    'descricao', t.description,
                    'realizada_em', t.created_at
                ))
            FROM (
                SELECT amount, type, description, created_at
                FROM transactions
                WHERE account_id = a.id
                ORDER BY created_at DESC
                LIMIT 10
            ) t),
            '[]'::json
        )
    FROM
        accounts a
    WHERE
        a.id = p_account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION realizar_transacao(
    p_client_id INT,
    p_valor NUMERIC,
    p_tipo CHAR(1),
    p_descricao VARCHAR(10)
)
RETURNS TABLE (
    limite NUMERIC,
    novo_saldo NUMERIC
) AS $$
DECLARE
    v_limite_conta NUMERIC;
    v_saldo_atual NUMERIC;
    v_saldo_final NUMERIC;
BEGIN
    -- 1. Tenta buscar e bloquear a conta do cliente.
    -- O 'FOR UPDATE' é crucial para garantir que nenhuma outra transação
    -- possa modificar esta linha até que a nossa transação seja concluída (COMMIT ou ROLLBACK).
    SELECT
        a.limite,
        a.balance
    INTO
        v_limite_conta,
        v_saldo_atual
    FROM
        accounts a
    WHERE
        a.id = p_client_id
    FOR UPDATE;

    -- 2. Verifica se o cliente foi encontrado.
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente não encontrado com id: %', p_client_id;
    END IF;

    -- 3. Aplica a lógica de negócio (crédito ou débito).
    IF p_tipo = 'c' THEN
        v_saldo_final := v_saldo_atual + p_valor;
    ELSIF p_tipo = 'd' THEN
        v_saldo_final := v_saldo_atual - p_valor;
        -- 4. Valida se o limite foi excedido para transações de débito.
        IF v_saldo_final < -v_limite_conta THEN
            RAISE EXCEPTION 'Limite da conta excedido.';
        END IF;
    ELSE
        RAISE EXCEPTION 'Tipo de transação inválido: %', p_tipo;
    END IF;

    -- 5. Se todas as validações passaram, atualiza o saldo do cliente.
    UPDATE accounts
    SET balance = v_saldo_final
    WHERE id = p_client_id;

    -- 6. Insere o registro na tabela de transações.
    INSERT INTO transactions (account_id, amount, type, description)
    VALUES (p_client_id, p_valor, p_tipo, p_descricao);

    -- 7. Retorna o limite e o novo saldo, como a função original fazia.
    RETURN QUERY
    SELECT v_limite_conta, v_saldo_final;

END;
$$ LANGUAGE plpgsql;