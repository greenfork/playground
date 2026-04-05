import { resolve } from '$app/paths';
import { authState } from '$lib/state.svelte';
import { ensureAuthenticated } from '$lib/db';

const PUBLIC_ROUTES = ['/login'];

export async function init() {
	if (PUBLIC_ROUTES.includes(window.location.pathname)) return;

	authState.authenticated = await ensureAuthenticated();
	if (!authState.authenticated) {
		window.location.href = resolve('/login');
		throw new Error('unauthenticated');
	}
}

export async function handleError({ error, message }) {
	if (error?.status === 401) {
		window.location.href = resolve('/login');
	}
	return message;
}
