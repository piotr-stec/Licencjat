use starknet::{
    core::{
        types::{BlockId, BlockTag, Felt, FunctionCall},
        utils::get_selector_from_name,
    },
    providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider, Url},
};
use tower_http::BoxError;

pub async fn check_execution(url: Url, contract_address: Felt) -> Result<bool, BoxError> {
    let provider = JsonRpcClient::new(HttpTransport::new(url));

    let response = provider
        .call(
            FunctionCall {
                calldata: vec![],
                contract_address,
                entry_point_selector: get_selector_from_name("check_payments_for_execution")
                    .unwrap(),
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await?;

    Ok(response[0] == Felt::ONE)
}
