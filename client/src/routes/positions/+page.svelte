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
			{#each payments as payment}
				<li class="rounded bg-gray-800 p-4">
					<div><strong>Recipient:</strong> {payment.recipient}</div>
					<div><strong>Amount:</strong> {payment.amount} {payment.token_name}</div>
					<div><strong>Token:</strong> {payment.token_address}</div>
					<div>
						<strong>Last Paid:</strong>
						{new Date(payment.last_paid_timestamp * 1000).toLocaleString()}
					</div>
					<div><strong>Interval (min):</strong>{Math.floor(payment.interval / 60)}</div>
					<div><strong>Payments Left:</strong> {payment.payment_quantity_left}</div>
					<div><strong>Active:</strong> {payment.is_active ? 'Yes' : 'No'}</div>
				</li>
			{/each}
		</ul>
	{:else if loading && !error}
		<p class="mt-4 text-gray-400">No payments found.</p>
	{/if}
</PageContentContainer>
