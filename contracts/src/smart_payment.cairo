use starknet::ContractAddress;

#[starknet::interface]
pub trait ISmartPayment<TContractState> {
    fn auto_pay(
        ref self: TContractState,
        amount: u256,
        receipient: ContractAddress,
        token_address: ContractAddress,
    ) -> bool;
}

#[starknet::contract]
pub mod SmartPayment {
    // use starknet::storage::StoragePointerWriteAccess;
    // use starknet::storage::StoragePathEntry;
    // use starknet::storage::StorageMapReadAccess;
    // use starknet::storage::StoragePointerReadAccess;
    use openzeppelin::{// access::ownable::OwnableComponent,
    token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait}};
    use starknet::{ContractAddress, get_caller_address, get_contract_address, storage::{Map}};

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {}


    #[abi(embed_v0)]
    impl SmartPayment of super::ISmartPayment<ContractState> {
        fn auto_pay(
            ref self: ContractState,
            amount: u256,
            receipient: ContractAddress,
            token_address: ContractAddress,
        ) -> bool {
            let caller = get_caller_address();
            let this = get_contract_address();
            let token = IERC20Dispatcher { contract_address: token_address };
            token.transfer_from(caller, this, amount.into());
            true
        }
    }
}
