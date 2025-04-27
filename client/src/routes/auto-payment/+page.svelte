<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import PageContentContainer from '../../components/PageContentContainer.svelte';
	import InputField from '../../components/InputField.svelte';
	import ActionButton from '../../components/ActionButton.svelte';

	let recipient = '';
	let amount = '';
	let timeValue = '';
	let timeUnit = 'minutes';
	let processing = false;
	let timeoutId: ReturnType<typeof setTimeout> | null = null;

	async function autoSaveHandler() {
		processing = true;

		console.log('Auto-saving...');
		console.log('Recipient:', recipient);
		console.log('Amount:', amount);

		// tutaj normalnie wykonałbyś transakcję lub akcję

		processing = false;
	}

	function scheduleAutoPayment() {
		if (timeoutId) {
			clearTimeout(timeoutId);
		}

		const timeNumber = parseInt(timeValue);

		if (isNaN(timeNumber) || timeNumber <= 0) {
			console.error('Invalid time value');
			return;
		}

		let milliseconds = 0;
		if (timeUnit === 'minutes') {
			milliseconds = timeNumber * 60 * 1000;
		} else if (timeUnit === 'hours') {
			milliseconds = timeNumber * 60 * 60 * 1000;
		} else if (timeUnit === 'days') {
			milliseconds = timeNumber * 24 * 60 * 60 * 1000;
		}

		timeoutId = setTimeout(() => {
			if (recipient && amount) {
				autoSaveHandler();
			}
		}, milliseconds);
	}

	onDestroy(() => {
		if (timeoutId) {
			clearTimeout(timeoutId);
		}
	});
</script>

<PageContentContainer title="Auto Payment">
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

	<ActionButton onClick={scheduleAutoPayment} customClass="mt-4">
		Schedule Auto Payment
	</ActionButton>

	{#if processing}
		<p class="mt-2 text-sm text-gray-500">Processing AutoPayment...</p>
	{/if}
</PageContentContainer>
