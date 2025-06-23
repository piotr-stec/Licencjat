# Blockchain-based Payment Management Application

This project is a blockchain-based payment management application using the Starknet network.

## Prerequisites

- Rust and Cargo installed
- Node.js and npm installed
- Scarb installed
- Alchemy Starknet API Token
- `.env` configuration files set up as shown below

## Project Setup and Run Instructions

### 1. Build Cairo contracts

```bash
scarb build
```

### 2. Set up Indexer

```bash
cd indexer
npm install
```

Create a `.env` file in the `indexer` folder with the following content:

```env
APIBARA_TOKEN=dna_2Pib3KEjn8VCURJJnnAy
PROVIDER_URL=https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/ffGrvRxnad_MXHATSkRmHUu8vUlghEok
```

Run the indexer:

```bash
npm run start
```

### 3. Return to project root

```bash
cd ..
```

### 4. Configure backend `.cargo/config.toml`

In `.cargo/config.toml` add:

```toml
[env]
WS_URL = "ws://localhost:3003"
PROVIDER_URL = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/M1xN5JzvCQoxejLv-feFyJp4xWLDT4J4"
SMART_PAY_CONTRACT_ADDRESS = "0x01b0959fb7b7f4780803609bcd5c24d6613059407ed95ad0fc3447fc6fd6c060"
PAYMASTER_ADDRESS = "0x64fa47c02430e5d69c0c5d340e23397bca308f7b9d85247565fc91f2c2ad2f2"
PAYMASTER_PRIVATE_KEY = "0x4b10399eb3eee3bddbe485790b2d81ab30be8019b634e44728b96e6ec383d47"
```

Run backend:

```bash
cargo run
```

### 5. Set up client environment

```bash
cd client
```

Create a `.env` file in the `client` folder with the following content:

```env
# SEPOLIA
PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS="0x01b0959fb7b7f4780803609bcd5c24d6613059407ed95ad0fc3447fc6fd6c060"
PUBLIC_RPC_URL="https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/M1xN5JzvCQoxejLv-feFyJp4xWLDT4J4"
```

### 6. Return to root and run frontend

```bash
cd ..
npm install
npm run dev
```
