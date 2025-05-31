use futures_util::stream::StreamExt;
use starknet_types_core::felt::Felt;
use tower_http::BoxError;
use url::Url;

use crate::{check_execution::check_execution, execute_payments::execute};
pub async fn fetch_events_loop(
    url: Url,
    provider_url: Url,
    smart_pay_contract_address: Felt,
    paymaster_address: Felt,
    paymaster_private_key: Felt,
    mut shutdown_rx: tokio::sync::broadcast::Receiver<()>,
) -> Result<(), BoxError> {
    loop {
        let (ws_stream, _) = match tokio_tungstenite::connect_async(url.as_str()).await {
            Ok(stream) => stream,
            Err(err) => {
                eprintln!("❌ WebSocket connection failed: {}. Retrying in 5s...", err);
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                continue;
            }
        };

        let (_, mut read) = ws_stream.split();

        loop {
            tokio::select! {
                Some(msg) = read.next() => {
                    match msg {
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Text(text)) => {
                            match serde_json::from_str::<serde_json::Value>(&text) {
                                Ok(json) => {
                                    if let Some(block_number) = json.get("block_number").and_then(|v| v.as_u64()) {
                                        println!("📡 Received block_number: {}", block_number);
                                        let possible_execution = check_execution(provider_url.clone(), smart_pay_contract_address).await?;
                                        println!("possible execution {:?}", possible_execution);
                                        match possible_execution {
                                            true => execute(provider_url.clone(), smart_pay_contract_address, paymaster_address, paymaster_private_key).await?,
                                            false => (),
                                        }
                                    } else {
                                        eprintln!("❌ JSON does not contain block_number: {}", text);
                                    }
                                },
                                Err(err) => {
                                    eprintln!("❌ Failed to parse WebSocket message: {} | Error: {}", text, err);
                                }
                            }
                        }
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Binary(_)) => {
                            eprintln!("⚠️ Received unexpected binary message.");
                        }
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Ping(ping)) => {
                            println!("📡 Received WebSocket Ping: {:?}", ping);
                        }
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Pong(pong)) => {
                            println!("📡 Received WebSocket Pong: {:?}", pong);
                        }
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Close(close_frame)) => {
                            println!("❌ WebSocket closed: {:?}. Reconnecting...", close_frame);
                            break;
                        }
                        Ok(tokio_tungstenite::tungstenite::protocol::Message::Frame(_)) => {
                            println!("⚠️ Received WebSocket Frame message (ignored).");
                        }
                        Err(err) => {
                            eprintln!("❌ WebSocket error: {}. Reconnecting...", err);
                            break;
                        }
                    }
                }
                _ = shutdown_rx.recv() => {
                    println!("🛑 Fetcher received shutdown signal. Exiting...");
                    return Ok(());
                }
            }
        }

        println!("🔄 Reconnecting WebSocket in 5s...");
        tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
    }
}
