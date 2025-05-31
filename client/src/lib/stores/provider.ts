import { readable } from 'svelte/store';
import { RpcProvider } from 'starknet';
import { PUBLIC_RPC_URL } from '$env/static/public';

/**
 * A singleton Starknet RPC provider.
 * Emits the same provider over the lifetime of the app.
 */
export const provider = readable(
	new RpcProvider({ nodeUrl: PUBLIC_RPC_URL, specVersion: '0.8.1' }),
	() => {}
);