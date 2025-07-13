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

<div class="blockchain-grid min-h-screen">
	<PageContentContainer title="Auto Payments Viewer">
		<div class="form-container mx-auto max-w-4xl">
			<div class="cyber-text mb-6 text-center text-xl">🔍 PAYMENT POSITIONS SCANNER 🔍</div>
			<InputField
				type="text"
				placeholder="Enter wallet address to scan"
				customClass="mt-4"
				bind:value={userAddress}
			/>

			<div class="mt-6">
				<ActionButton
					onClick={fetchAutoPayments}
					customClass="mt-4 w-full"
					disabled={loading || !userAddress.trim()}
				>
					{#if loading}
						<div class="processing-indicator">
							<div class="processing-spinner"></div>
							<span>SCANNING BLOCKCHAIN</span>
						</div>
					{:else}
						🔍 SCAN PAYMENTS 🔍
					{/if}
				</ActionButton>
			</div>

			{#if error}
				<div class="alert alert-error mt-4">
					⚠️ ERROR: {error}
				</div>
			{/if}

			{#if payments.length > 0}
				<div class="mt-8 space-y-4">
					<div class="cyber-text mb-4 text-lg">
						⚡ ACTIVE POSITIONS: {sortedPayments.filter((p) => p.is_active).length} | INACTIVE: {sortedPayments.filter(
							(p) => !p.is_active
						).length}
					</div>
					{#each sortedPayments as payment}
						<div
							class="card blockchain-card {payment.is_active
								? 'payment-active'
								: 'payment-inactive'}"
						>
							<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
								<div class="space-y-4">
									<div>
										<div class="cyber-text mb-2 text-sm">🎯 RECIPIENT</div>
										<div class="blockchain-address w-full text-xs break-all">
											{payment.recipient}
										</div>
									</div>
									<div>
										<div class="cyber-text mb-2 text-sm">🪙 TOKEN</div>
										<div class="blockchain-address w-full text-xs break-all">
											{payment.token_address}
										</div>
									</div>
								</div>
								<div class="space-y-4">
									<div>
										<div class="cyber-text mb-2 text-sm">💰 AMOUNT</div>
										<div class="text-xl font-bold break-words text-white">
											{payment.amount}
											{payment.token_name}
										</div>
									</div>
									<div>
										<div class="cyber-text mb-2 text-sm">⏱️ SCHEDULE</div>
										<div class="text-sm text-gray-300">
											Every {Math.floor(payment.interval / 60)} minutes
										</div>
										<div class="text-sm text-gray-300">
											{payment.payment_quantity_left} payments left
										</div>
									</div>
								</div>
							</div>

							<div class="mt-6 border-t border-gray-600 pt-4">
								<div class="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
									<div class="text-center sm:text-left">
										<div class="text-xs text-gray-400">Last Paid:</div>
										<div class="text-sm break-words">
											{new Date(payment.last_paid_timestamp * 1000).toLocaleString()}
										</div>
									</div>
									{#if payment.is_active}
										<div class="text-center sm:text-left">
											<div class="text-xs text-gray-400">Next Payment:</div>
											<div class="text-sm break-words">
												{new Date(
													(payment.last_paid_timestamp + payment.interval) * 1000
												).toLocaleString()}
											</div>
										</div>
									{/if}
									<div class="flex items-center justify-center gap-2 sm:justify-start">
										<div
											class="h-3 w-3 rounded-full {payment.is_active
												? 'bg-green-400'
												: 'bg-red-400'}"
										></div>
										<span
											class="text-sm font-bold {payment.is_active
												? 'text-green-400'
												: 'text-red-400'}"
										>
											{payment.is_active ? 'ACTIVE' : 'INACTIVE'}
										</span>
									</div>
								</div>

								{#if payment.is_active}
									<button
										class="navbar-disconnect mt-4 w-full"
										on:click={() => deactivatePayment(payment.id, payment.owner)}
										title="Deactivate this payment"
									>
										⛔ DEACTIVATE PAYMENT
									</button>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{:else if !loading && !error}
				<div class="card mt-8 text-center">
					<div class="cyber-text mb-4 text-lg">🕵️ NO POSITIONS DETECTED</div>
					<p class="text-gray-400">No automated payments found for this address.</p>
				</div>
			{/if}
		</div>
	</PageContentContainer>
</div>

<style>
	.payment-inactive {
		border-left: 4px solid var(--color-error);
		box-shadow:
			0 8px 32px rgba(0, 0, 0, 0.6),
			0 0 var(--glow-size) rgba(255, 68, 68, 0.3);
	}
	.payment-active {
		border-left: 4px solid var(--color-success);
		box-shadow:
			0 8px 32px rgba(0, 0, 0, 0.6),
			0 0 var(--glow-size) rgba(0, 255, 136, 0.3);
	}
</style>
