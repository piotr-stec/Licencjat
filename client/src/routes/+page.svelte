<script lang="ts">
	import PageContentContainer from '../components/PageContentContainer.svelte';
	import ActionButton from '../components/ActionButton.svelte';
	import { connectWallet } from '$lib/utils/wallet';
	import { wrapWithToast } from '$lib/utils/wrapWithToast';
	import { goto } from '$app/navigation';

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

<div class="blockchain-grid min-h-screen">
	<PageContentContainer title="Welcome to SmartPay">
		<div class="mx-auto flex max-w-6xl flex-col items-center gap-8">
			<!-- Hero Section -->
			<div class="mb-8 text-center">
				<h2 class="cyber-text mb-4 text-3xl lg:text-4xl">STARKNET AUTO PAYMENT PROTOCOL</h2>
				<p class="mb-6 text-xl text-gray-300">
					Automate your blockchain payments with military-grade precision
				</p>
				<div class="starknet-logo mb-8 text-4xl lg:text-5xl">⬢ STARKNET ⬢</div>
			</div>

			<!-- Features Grid -->
			<div class="mb-12 grid w-full grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
				<div class="card blockchain-card text-center">
					<div class="mb-4 text-4xl">⚙️</div>
					<h3 class="cyber-text mb-3 text-lg">AUTOMATED SCHEDULING</h3>
					<p class="text-sm text-gray-300">
						Set up recurring payments that execute automatically on Starknet. No manual intervention
						required.
					</p>
				</div>

				<div class="card blockchain-card text-center">
					<div class="mb-4 text-4xl">🔒</div>
					<h3 class="cyber-text mb-3 text-lg">SECURE & TRUSTLESS</h3>
					<p class="text-sm text-gray-300">
						Built on Cairo smart contracts. Your funds remain secure with mathematical precision and
						zero trust requirements.
					</p>
				</div>

				<div class="card blockchain-card text-center">
					<div class="mb-4 text-4xl">⚡</div>
					<h3 class="cyber-text mb-3 text-lg">LIGHTNING FAST</h3>
					<p class="text-sm text-gray-300">
						Leverage Starknet's L2 technology for instant transactions with minimal fees. Execute
						payments in milliseconds.
					</p>
				</div>
			</div>

			<!-- How It Works Section -->
			<div class="mb-12 w-full">
				<h3 class="cyber-text mb-8 text-center text-2xl">⚡ HOW IT WORKS ⚡</h3>
				<div class="grid grid-cols-1 gap-8 md:grid-cols-3">
					<div class="text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-green-400 to-blue-500 text-2xl font-bold"
						>
							1
						</div>
						<h4 class="cyber-text mb-2 text-lg">CONNECT WALLET</h4>
						<p class="text-sm text-gray-400">
							Connect your Starknet wallet to access the payment protocol
						</p>
					</div>
					<div class="text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-blue-500 to-purple-500 text-2xl font-bold"
						>
							2
						</div>
						<h4 class="cyber-text mb-2 text-lg">SCHEDULE PAYMENT</h4>
						<p class="text-sm text-gray-400">
							Set recipient, amount, interval and number of executions
						</p>
					</div>
					<div class="text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 text-2xl font-bold"
						>
							3
						</div>
						<h4 class="cyber-text mb-2 text-lg">AUTO EXECUTE</h4>
						<p class="text-sm text-gray-400">
							Smart contracts automatically execute your payments on schedule
						</p>
					</div>
				</div>
			</div>

			<!-- Use Cases Section -->
			<div class="mb-12 w-full">
				<h3 class="cyber-text mb-8 text-center text-2xl">🎯 USE CASES 🎯</h3>
				<div class="grid grid-cols-1 gap-6 md:grid-cols-2">
					<div class="card">
						<h4 class="cyber-text mb-3 text-lg">💼 SALARY PAYMENTS</h4>
						<p class="text-sm text-gray-300">
							Automate employee salaries, contractor payments, or freelancer compensation with
							precise scheduling.
						</p>
					</div>
					<div class="card">
						<h4 class="cyber-text mb-3 text-lg">🏠 SUBSCRIPTION SERVICES</h4>
						<p class="text-sm text-gray-300">
							Perfect for SaaS subscriptions, rent payments, or any recurring billing requirements.
						</p>
					</div>
					<div class="card">
						<h4 class="cyber-text mb-3 text-lg">💰 DCA INVESTMENTS</h4>
						<p class="text-sm text-gray-300">
							Implement dollar-cost averaging strategies for crypto investments with automated
							precision.
						</p>
					</div>
					<div class="card">
						<h4 class="cyber-text mb-3 text-lg">🤝 ESCROW RELEASES</h4>
						<p class="text-sm text-gray-300">
							Time-locked payments for milestones, vesting schedules, or conditional releases.
						</p>
					</div>
				</div>
			</div>

			<!-- Call to Action -->
			<div class="text-center">
				<div class="mb-6">
					<ActionButton onClick={handleConnect} customClass="button-2xl">
						⚡ CONNECT WALLET & START ⚡
					</ActionButton>
				</div>
				<p class="text-sm text-gray-400">
					Powered by Starknet L2 • Cairo Smart Contracts • Zero-Knowledge Proofs
				</p>
			</div>
		</div>
	</PageContentContainer>
</div>
