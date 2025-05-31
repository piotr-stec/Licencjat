<script lang="ts">
	import { onDestroy } from 'svelte';
	import PageContentContainer from '../../components/PageContentContainer.svelte';
	import InputField from '../../components/InputField.svelte';
	import ActionButton from '../../components/ActionButton.svelte';
	import { wrapWithToast } from '$lib/utils/wrapWithToast';
	import { fromLowHigh, fromLowHighHex, toLowHigh } from '$lib/utils/toLowHigh';
	import { fromWei, toWei } from '$lib/utils/toWei';
	import { fetchTokenDecimals, fetchTokenSymbol } from '$lib/utils/token';
	import { wallet } from '$lib/stores/wallet';
	import { get } from 'svelte/store';
	import { PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS } from '$env/static/public';
	import { showToast } from '$lib/stores/toast';
	import { provider } from '$lib/stores/provider';
	import { type Call } from 'starknet';

	let userAddress = '';
	let payments: any[] = [];
	let loading = false;
	let error: string | null = null;

	$: sortedPayments = [...payments].sort((a, b) => {
		if (a.is_active === b.is_active) return 0;
		return a.is_active ? -1 : 1;
	});

	async function hexToBool(hex: string) {
		return hex === '0x1';
	}

	async function proccessAutoPaymentArray(input: string[]) {
		const count = Number(BigInt(input[0]));
		const dataStart = 1;
		const POSITION_SIZE = 12;

		const payments = [];

		for (let i = 0; i < count; i++) {
			const baseIndex = dataStart + i * POSITION_SIZE;

			const token_address = input[baseIndex + 8];
			const decimals = await fetchTokenDecimals(token_address);

			let token_name = await fetchTokenSymbol(token_address);

			const id = Number(BigInt(input[baseIndex + 0]));
			const owner = input[baseIndex + 1];
			const recipient = input[baseIndex + 2];
			const amount = fromWei(fromLowHigh(input[baseIndex + 3], input[baseIndex + 4]), decimals);
			const payment_quantity_left = Number(BigInt(input[baseIndex + 5]));
			const interval = Number(BigInt(input[baseIndex + 6]));
			const last_paid_timestamp = Number(BigInt(input[baseIndex + 7]));
			const prepaid_gas_fee = fromLowHigh(input[baseIndex + 9], input[baseIndex + 10]);
			const is_active = await hexToBool(input[baseIndex + 11]);

			payments.push({
				id,
				owner,
				recipient,
				amount,
				payment_quantity_left,
				interval,
				last_paid_timestamp,
				token_address,
				prepaid_gas_fee,
				is_active,
				token_name
			});
		}
		return payments;
	}

	async function fetchAutoPayments() {
		error = null;
		loading = true;
		payments = [];

		try {
			const rpc = get(provider);

			const call: Call = {
				contractAddress: PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS,
				entrypoint: 'get_auto_payments',
				calldata: [userAddress]
			};

			let response = await rpc.callContract(call);
			console.log(response);
			payments = await proccessAutoPaymentArray(response);
			console.log(payments);
		} catch (e: any) {
			error = e.message ?? 'Unknown error';
		} finally {
			loading = false;
		}
	}

	async function deactivatePayment(paymentId: number, owner: string) {
		try {
			const connectedWallet = get(wallet);
			if (!connectedWallet) throw new Error('Please connect your wallet.');

			const call = {
				contract_address: PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS,
				entry_point: 'deactivate_auto_payment',
				calldata: [owner, paymentId.toString(16)]
			};
			await wrapWithToast(
				async () => {
					await connectedWallet.request({
						type: 'wallet_addInvokeTransaction',
						params: { calls: [call] }
					});
					showToast('Payment deactivated', 'success');
					showToast('Refreashing payments - please wait', 'info');
					loading = true;
					await new Promise((resolve) => setTimeout(resolve, 2000));
					await fetchAutoPayments();
				},
				{
					error: (e) =>
						`Failed to deactivate payment: ${e instanceof Error ? e.message : String(e)}`
				}
			);
		} catch (e: any) {
			showToast(e.message ?? 'Unknown error', 'error');
		}
	}
</script>

<PageContentContainer title="Auto Payments Viewer">
	<InputField
		type="text"
		placeholder="Enter your address"
		customClass="mt-4"
		bind:value={userAddress}
	/>

	<ActionButton
		onClick={fetchAutoPayments}
		customClass="mt-4"
		disabled={loading || !userAddress.trim()}
	>
		{loading ? 'Loading...' : 'Fetch Payments'}
	</ActionButton>

	{#if error}
		<p class="mt-2 text-red-600">{error}</p>
	{/if}

	{#if payments.length > 0}
		<ul class="mt-4 space-y-2">
			{#each sortedPayments as payment}
				<li class="rounded bg-gray-800 p-4 {payment.is_active ? 'payment-active' : 'payment-inactive'}">
					<div><strong>Recipient:</strong> {payment.recipient}</div>
					<div><strong>Token:</strong> {payment.token_address}</div>

					<div><strong>Amount:</strong> {payment.amount} {payment.token_name}</div>
					<div>
						<strong>Last Paid:</strong>
						{new Date(payment.last_paid_timestamp * 1000).toLocaleString()}
					</div>
					{#if payment.is_active}
						<div>
							<strong>Next Payment:</strong>
							{new Date((payment.last_paid_timestamp + payment.interval) * 1000).toLocaleString()}
						</div>
					{/if}
					<div><strong>Interval (min):</strong> {Math.floor(payment.interval / 60)}</div>
					<div><strong>Payments Left:</strong> {payment.payment_quantity_left}</div>
					<div><strong>Active:</strong> {payment.is_active ? 'Yes' : 'No'}</div>

					<button
						class="deactivate-button"
						on:click={() => deactivatePayment(payment.id, payment.owner)}
						disabled={!payment.is_active}
						title="Deactivate this payment"
					>
						Deactivate
					</button>
				</li>
			{/each}
		</ul>
	{:else if !loading && !error}
		<p class="mt-4 text-gray-400">No payments found.</p>
	{/if}
</PageContentContainer>

<style>
	.payment-inactive {
		border-left: 4px solid #dc2626; /* czerwony */
		padding-left: 0.75rem;
	}
	.payment-active {
		border-left: 4px solid #22c55e; /* tailwind green-500 */
		padding-left: 0.75rem;
	}

	.deactivate-button {
		background-color: #dc2626;
		color: white;
		border: none;
		padding: 0.5rem 0.75rem;
		border-radius: 4px;
		cursor: pointer;
		font-weight: 600;
		margin-top: 0.5rem;
		transition: background-color 0.2s ease;
	}
	.deactivate-button:hover {
		background-color: #b91c1c;
	}
	.deactivate-button:disabled {
		background-color: #7f1d1d;
		cursor: not-allowed;
	}
</style>
