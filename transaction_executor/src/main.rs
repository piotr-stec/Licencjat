use clap::Parser;
use starknet_types_core::felt::Felt;
use url::Url;

mod check_execution;
mod execute_payments;
mod fetcher;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// WebSocket URL
    #[arg(long, env = "WS_URL")]
    ws_url: Url,

    /// Starknet provider URL (RPC HTTP endpoint)
    #[arg(long, env = "PROVIDER_URL")]
    provider_url: Url,

    /// Smart payment contract address (hex string)
    #[arg(long, env = "SMART_PAY_CONTRACT_ADDRESS")]
    smart_pay_contract_address: Felt,

    /// Paymaster address (hex string)
    #[arg(long, env = "PAYMASTER_ADDRESS")]
    paymaster_address: Felt,

    /// Paymaster private key (hex string)
    #[arg(long, env = "PAYMASTER_PRIVATE_KEY")]
    paymaster_private_key: Felt,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let (_shutdown_tx, shutdown_rx) = tokio::sync::broadcast::channel(1);

    let fetcher_handle = tokio::spawn(async move {
        fetcher::fetch_events_loop(
            args.ws_url,
            args.provider_url,
            args.smart_pay_contract_address,
            args.paymaster_address,
            args.paymaster_private_key,
            shutdown_rx,
        )
        .await
        .unwrap();
    });

    fetcher_handle.await?;

    Ok(())
}
