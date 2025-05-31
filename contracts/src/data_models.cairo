use starknet::ContractAddress;

#[derive(PartialEq, Copy, Drop, Serde, starknet::Store)]
pub struct AutoPayment {
    pub id: u64,
    pub owner: ContractAddress,
    pub receipient: ContractAddress,
    pub amount: u256,
    pub payment_quantity_left: u64,
    pub interval: u64,
    pub last_paid_timestamp: u64,
    pub token_address: ContractAddress,
    pub prepaid_gas_fee: u256,
    pub is_active: bool,
}
