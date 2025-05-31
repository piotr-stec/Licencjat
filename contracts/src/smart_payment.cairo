use starknet::ContractAddress;
use core::array::Array;

#[starknet::interface]
pub trait ISmartPayment<TContractState> {
    fn auto_pay(
        ref self: TContractState,
        amount: u256,
        receipient: ContractAddress,
        token_address: ContractAddress,
        interval: u64,
        payment_quantity: u64,
        prepaid_gas_fee: u256,
    ) -> bool;
    fn execute_payments(ref self: TContractState) -> bool;
    fn check_payments_for_execution(self: @TContractState) -> bool;
    fn get_auto_payments(
        self: @TContractState, user: ContractAddress,
    ) -> Array<super::data_models::AutoPayment>;
    fn deactivate_auto_payment(ref self: TContractState, user: ContractAddress, id: u64) -> bool;
}

#[starknet::contract]
pub mod SmartPayment {
    use starknet::storage::VecTrait;
    use openzeppelin::{token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait}};
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address,
        storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, Vec, MutableVecTrait},
    };
    use starknet::get_block_timestamp;
    use super::super::data_models::AutoPayment;
    use core::array::{Array, ArrayTrait};


    pub mod Errors {
        pub const TRANSFER_FAILED: felt252 = 'Payment: Transfer Failed';
    }

    #[storage]
    struct Storage {
        pub auto_payments: Vec<AutoPayment>,
        pub user_gas_fee: Map<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        PaymentScheduled: PaymentScheduled,
        PaymentExecuted: PaymentExecuted,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct PaymentScheduled {
        user: ContractAddress,
        receipient: ContractAddress,
        amount: u256,
        token_address: ContractAddress,
        interval: u64,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct PaymentExecuted {
        user: ContractAddress,
        receipient: ContractAddress,
        amount: u256,
        token_address: ContractAddress,
    }


    #[abi(embed_v0)]
    impl SmartPayment of super::ISmartPayment<ContractState> {
        fn check_payments_for_execution(self: @ContractState) -> bool {
            let current_timestamp = get_block_timestamp();
            let mut to_execute_any = false;
            let payments_len = self.auto_payments.len();
            let mut i = 0;
            while i < payments_len {
                let mut payment = self.auto_payments.at(i).read();
                // Check if payment is active and if enough time has passed since last payment
                if payment.is_active
                    && (current_timestamp - payment.last_paid_timestamp >= payment.interval) {
                    to_execute_any = true;
                }
                i += 1;
            };

            to_execute_any
        }
        fn execute_payments(ref self: ContractState) -> bool {
            let current_timestamp = get_block_timestamp();
            let this = get_contract_address();
            let mut executed_any = false;

            // Get all users with auto payments
            // Note: In a production environment, we would need a more efficient way to iterate
            // through users This is a simplified implementation for demonstration purposes

            // For each user's auto payments
            // Iterate through each payment and check if it's time to execute
            let payments_len = self.auto_payments.len();

            let mut i = 0;

            while i < payments_len {
                let mut payment = self.auto_payments.at(i).read();

                // Check if payment is active and if enough time has passed since last payment
                if payment.is_active
                    && (current_timestamp - payment.last_paid_timestamp >= payment.interval) {
                    // Execute the payment
                    let token = IERC20Dispatcher { contract_address: payment.token_address };

                    // Transfer from contract to recipient
                    let transfer_ok = token
                        .transfer_from(payment.owner, this, payment.amount.into());
                    assert(transfer_ok, Errors::TRANSFER_FAILED);

                    // Transfer from contract to recipient
                    let transfer_ok = token.transfer(payment.receipient, payment.amount.into());
                    assert(transfer_ok, Errors::TRANSFER_FAILED);

                    // Update the last paid timestamp
                    payment.last_paid_timestamp = current_timestamp;

                    // Update the payment in the vector
                    self.auto_payments.at(i).write(payment);

                    // Emit event
                    self
                        .emit(
                            PaymentExecuted {
                                user: payment.owner,
                                receipient: payment.receipient,
                                amount: payment.amount,
                                token_address: payment.token_address,
                            },
                        );

                    executed_any = true;
                }

                i += 1;
            };

            executed_any
        }

        fn auto_pay(
            ref self: ContractState,
            amount: u256,
            receipient: ContractAddress,
            token_address: ContractAddress,
            interval: u64,
            payment_quantity: u64,
            prepaid_gas_fee: u256,
        ) -> bool {
            let caller = get_caller_address();
            let this = get_contract_address();
            let token = IERC20Dispatcher { contract_address: token_address };

            // Transfer tokens from caller to contract (for future payments)
            token.transfer_from(caller, this, amount.into());

            token.transfer_from(caller, this, prepaid_gas_fee.into());

            // Find last id
            let mut last_id: u64 = 0;
            for i in 0..self.auto_payments.len() {
                let payment = self.auto_payments.at(i).read();
                if payment.owner == caller && payment.id > last_id {
                    last_id = payment.id;
                }
            };

            // Create a new auto payment
            let current_timestamp = get_block_timestamp();
            let mut auto_payment = AutoPayment {
                id: last_id + 1,
                owner: caller,
                receipient,
                amount,
                payment_quantity_left: payment_quantity,
                interval,
                last_paid_timestamp: current_timestamp,
                token_address,
                prepaid_gas_fee,
                is_active: true,
            };

            // Store the auto payment in the user's payments list
            self.auto_payments.append().write(auto_payment);

            // Emit event
            self
                .emit(
                    PaymentScheduled { user: caller, receipient, amount, token_address, interval },
                );

            true
        }

        fn get_auto_payments(self: @ContractState, user: ContractAddress) -> Array<AutoPayment> {
            let mut arr: Array<AutoPayment> = array![];
            for i in 0..self.auto_payments.len() {
                let payment = self.auto_payments.at(i).read();
                if payment.owner == user {
                    arr.append(payment);
                }
            };
            arr
        }


        fn deactivate_auto_payment(
            ref self: ContractState, user: ContractAddress, id: u64,
        ) -> bool {
            let mut result = false;
            for i in 0..self.auto_payments.len() {
                let mut payment = self.auto_payments.at(i).read();
                if payment.owner == user && payment.id == id && payment.is_active {
                    payment.is_active = false;
                    result = true;
                }
            };
            result
        }
    }
}
