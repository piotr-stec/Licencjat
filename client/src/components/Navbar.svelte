<script lang="ts">
	import { goto } from '$app/navigation';
	import { isConnected, walletAddress } from '$lib/stores/wallet';
	import {
		copyWalletAddress,
		disconnectWallet,
		shortAddress,
		connectWallet
	} from '$lib/utils/wallet';
	import ToggleTheme from './ToggleTheme.svelte';
	import { wrapWithToast } from '$lib/utils/wrapWithToast';

	async function handleCopy() {
		await wrapWithToast(() => copyWalletAddress($walletAddress), {
			success: 'Copied address to clipboard!',
			error: 'Failed to copy address'
		});
	}

	async function handleDisconnect() {
		await wrapWithToast(() => disconnectWallet(), {
			success: 'Disconnected wallet',
			error: 'Failed to disconnect wallet'
		});
	}

	async function handleConnect() {
		const success = await wrapWithToast(() => connectWallet(), {
			success: 'Wallet connected successfully!',
			error: (err) => `Failed to connect wallet: ${(err as Error).message}`
		});

		if (success) {
			goto('/auto-payment');
		}
	}
</script>

<nav class="navbar">
	<a href="/" class="navbar-logo starknet-logo">SMARTPAY</a>

	<div class="navbar-menu">
		{#if $isConnected}
			<button on:click={() => goto('/auto-payment')} class="navbar-link">Auto Payment</button>
			<button on:click={() => goto('/positions')} class="navbar-link">Positions</button>

			<button
				class="blockchain-address"
				on:click={handleCopy}
				on:keypress={(e) => e.key === 'Enter' && handleCopy()}
				title="Click to copy"
				aria-label="Copy wallet address"
			>
				🔗 {shortAddress($walletAddress)}
			</button>

			<button on:click={handleDisconnect} class="navbar-disconnect">Disconnect</button>
		{:else}
			<button on:click={handleConnect} class="navbar-connect"> ⚡ Connect Wallet </button>
		{/if}
		<ToggleTheme />
	</div>
</nav>
