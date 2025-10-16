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