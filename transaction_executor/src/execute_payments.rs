use starknet::{
    accounts::{Account, ExecutionEncoding, SingleOwnerAccount},
    core::{
        types::{Call, Felt},
        utils::get_selector_from_name,
    },
    providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider, Url},
    signers::{LocalWallet, SigningKey},
};
use tower_http::BoxError;

pub async fn execute(
    url: Url,
    contract_address: Felt,
    paymaster_address: Felt,
    paymaster_private_key: Felt,
) -> Result<(), BoxError> {
    let provider = JsonRpcClient::new(HttpTransport::new(url));

    let paymaster_account = SingleOwnerAccount::new(
        provider.clone(),
        LocalWallet::from(SigningKey::from_secret_scalar(paymaster_private_key)),
        paymaster_address,
        provider.chain_id().await?,
        ExecutionEncoding::New,
    );

    let selector = get_selector_from_name("execute_payments")?;

    let call = Call {
        to: contract_address,
        selector,
        calldata: [].to_vec(),
    };

    let invoke_result = paymaster_account.execute_v3(vec![call]).send().await;

    println!("Invoke result {:?}", invoke_result);

    Ok(())
}
