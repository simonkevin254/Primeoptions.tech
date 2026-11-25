-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Global Enums
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'SUPERADMIN');
CREATE TYPE account_mode AS ENUM ('DEMO', 'REAL');
CREATE TYPE contract_type AS ENUM ('OVER_UNDER', 'EVEN_ODD', 'MATCH_DIFFER');
CREATE TYPE trade_status AS ENUM ('OPEN', 'WON', 'LOST', 'EXPIRED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED');

-- 1. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'USER',
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Accounts Balance Table
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mode account_mode NOT NULL,
    balance NUMERIC(15, 4) DEFAULT 0.0000,
    currency VARCHAR(10) DEFAULT 'USD',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_mode UNIQUE(user_id, mode)
);

-- 3. Trades Execution Record Table
CREATE TABLE trades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_mode account_mode NOT NULL,
    market_symbol VARCHAR(50) NOT NULL,
    contract_type contract_type NOT NULL,
    contract_parameter INT NOT NULL, 
    stake NUMERIC(15, 4) NOT NULL CHECK (stake > 0),
    payout_multiplier NUMERIC(5, 2) NOT NULL,
    entry_price NUMERIC(15, 6) NOT NULL,
    exit_price NUMERIC(15, 6),
    duration_seconds INT NOT NULL,
    status trade_status DEFAULT 'OPEN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- 4. Secure Payment Gateway Logs (Safaricom Daraja API Framework)
CREATE TABLE mpesa_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    merchant_request_id VARCHAR(100) UNIQUE NOT NULL,
    checkout_request_id VARCHAR(100) UNIQUE NOT NULL,
    amount NUMERIC(15, 4) NOT NULL,
    mpesa_receipt_number VARCHAR(100) UNIQUE,
    status payment_status DEFAULT 'PENDING',
    raw_callback_payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. System Audit Trail
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trades_user_status ON trades(user_id, status);
CREATE INDEX idx_mpesa_checkout ON mpesa_transactions(checkout_request_id);
