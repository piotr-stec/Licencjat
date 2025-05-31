<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import PageContentContainer from '../../components/PageContentContainer.svelte';
	import InputField from '../../components/InputField.svelte';
	import ActionButton from '../../components/ActionButton.svelte';
	import { wrapWithToast } from '$lib/utils/wrapWithToast';
	import { toLowHigh } from '$lib/utils/toLowHigh';
	import { toWei } from '$lib/utils/toWei';
	import { fetchTokenDecimals } from '$lib/utils/token';
	import { wallet } from '$lib/stores/wallet';
	import { get } from 'svelte/store';
	import { PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS } from '$env/static/public';
	import { showToast } from '$lib/stores/toast';

	let recipient = '';
	let amount = '';
	let timeValue = '';
	let timeUnit = 'minutes';
	let tokenAddress: string = '0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';
	let processing = false;
	let isLoading = false;
	let executions: string;

	let timeoutId: ReturnType<typeof setTimeout> | null = null;

	async function autoSaveHandler() {
		processing = true;

		console.log('Auto-saving...');
		console.log('Recipient:', recipient);
		console.log('Amount:', amount);
		processing = false;
	}

	onDestroy(() => {
		if (timeoutId) {
			clearTimeout(timeoutId);
		}
	});

	async function autoPayHandler() {
		isLoading = true;

		const timeNumber = parseInt(timeValue);
		if (isNaN(timeNumber) || timeNumber <= 0) {
			showToast('Invalid time value', 'error');
			isLoading = false;
			return;
		}

		let intervals = 0;
		if (timeUnit === 'minutes') {
			intervals = timeNumber * 60;
		} else if (timeUnit === 'hours') {
			intervals = timeNumber * 60 * 60;
		} else if (timeUnit === 'days') {
			intervals = timeNumber * 24 * 60 * 60;
		}

		await wrapWithToast(
			async () => {
				const decimals = await fetchTokenDecimals(tokenAddress);
				const amountWei = toWei(amount, decimals);
				const [amountLow, amountHigh] = toLowHigh(amountWei);
				const amountToApprove = amountWei * BigInt(executions);
				const [amountApproveLow, amountApproveHigh] = toLowHigh(amountToApprove);

				const calls = [
					{
						contract_address: tokenAddress,
						entry_point: 'increase_allowance',
						calldata: [PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS, amountApproveLow, amountApproveHigh]
					},
					{
						contract_address: PUBLIC_SMART_PAYMENT_CONTRACT_ADDRESS,
						entry_point: 'schedule_auto_pay',
						calldata: [
							amountLow,
							amountHigh,
							recipient,
							tokenAddress,
							intervals.toString(),
							executions,
							'0x0',
							'0x0'
						]
					}
				];

				const connectedWallet = get(wallet);
				if (!connectedWallet) throw new Error('Please connect your wallet.');

				await connectedWallet.request({
					type: 'wallet_addInvokeTransaction',
					params: { calls }
				});

				amount = '';
				recipient = '';
				timeValue = '';
				executions = '';
			},
			{
				success: 'Payment scheduled',
				error: (e) => `Payment schedule failed: ${e instanceof Error ? e.message : String(e)}`
			}
		);

		isLoading = false;
	}
</script>

<PageContentContainer title="Auto Payment">
	<InputField bind:value={tokenAddress} placeholder="Enter Token Address" />

	<InputField type="text" placeholder="Recipient" customClass="mt-4" bind:value={recipient} />

	<InputField type="text" placeholder="Amount" customClass="mt-4" bind:value={amount} />

	<div class="mt-4 flex gap-2">
		<InputField type="number" placeholder="Time value" customClass="mt-4" bind:value={timeValue} />
		<select
			bind:value={timeUnit}
			class="mt-4 rounded border p-2"
			style="background-color: #0a0a0a; color: white;"
		>
			<option value="minutes">Minutes</option>
			<option value="hours">Hours</option>
			<option value="days">Days</option>
		</select>
	</div>

	<InputField
		type="number"
		placeholder="Number of executions"
		customClass="mt-4"
		bind:value={executions}
	/>

	<ActionButton onClick={autoPayHandler} customClass="mt-4">Schedule Auto Payment</ActionButton>

	{#if processing}
		<p class="mt-2 text-sm text-gray-500">Processing AutoPayment...</p>
	{/if}
</PageContentContainer>
