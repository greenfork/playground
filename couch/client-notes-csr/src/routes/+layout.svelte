<script>
	import { onMount } from 'svelte';
	import * as auth from '$lib/auth.js';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';

	let { children } = $props();

	const PUBLIC_ROUTES = ['/login'];

	onMount(async () => {
		if (PUBLIC_ROUTES.includes(page.url.pathname)) return;

		const authenticated = await auth.ensureAuthenticated();
		if (!authenticated) {
			return goto('/login');
		}
	});
</script>

<svelte:head>
	<!-- <link rel="icon" href={favicon} /> -->
</svelte:head>

<header>
	<nav class="container">
		<ul>
			<li><a href="/">Все клиенты</a></li>
		</ul>
		<ul>
			<li><b>Заметки о клиентах</b></li>
		</ul>
	</nav>
</header>

<main class="container">{@render children()}</main>

<style>
	header {
		background-color: #014c75;
	}
	nav {
		padding: 1rem;
	}
</style>
