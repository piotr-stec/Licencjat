<script lang="ts">
	import '../app.css';
	import Navbar from '../components/Navbar.svelte';
	import Toast from '../components/Toast.svelte';
	import PageContentContainer from '../components/PageContentContainer.svelte';

	import { connect } from 'starknetkit';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { isConnected, wallet, walletAddress } from '$lib/stores/wallet';
	import { wrapWithToast } from '$lib/utils/wrapWithToast';

	let isInitializing = false;
	const protectedPaths = ['/auto-payment'];

	onMount(async () => {
		const pathname = $page.url.pathname;

		await wrapWithToast(
			async () => {
				const { wallet: connectedWallet, connectorData } = await connect({ modalMode: 'neverAsk' });
				if (connectedWallet && connectorData?.account) {
					wallet.set(connectedWallet);
					walletAddress.set(connectorData.account);
					isConnected.set(true);

					if (pathname === '/') {
						goto('/auto-payment');
					}
				} else if (protectedPaths.includes(pathname)) {
					goto('/');
					throw new Error('Please connect your wallet first');
				}
			},
			{
				error: (err) => `Wallet error: ${(err as Error).message}`,
				showSuccess: false
			}
		);

		isInitializing = false;
	});
</script>

<main class="flex min-h-screen flex-col">
	<!-- Floating particles background -->
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>
	<div class="floating-particles"></div>

	<header class="fixed top-0 right-0 left-0 z-50">
		<Navbar />
	</header>

	{#if isInitializing}
		<div class="blockchain-grid flex flex-1 flex-col items-center justify-center gap-4">
			<div class="pulse-ring">
				<div class="processing-spinner h-12 w-12 border-4"></div>
			</div>
			<div class="cyber-text text-lg">INITIALIZING BLOCKCHAIN CONNECTION</div>
			<p class="loading-dots text-sm text-gray-400">Connecting to Starknet</p>
		</div>
	{:else}
		<div class="flex flex-1 flex-col pt-20">
			<PageContentContainer>
				<slot />
			</PageContentContainer>
		</div>
	{/if}

	<Toast />
</main>
