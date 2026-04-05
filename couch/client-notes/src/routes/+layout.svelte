<script>
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { logout as dbLogout } from '$lib/db';
	import { authState } from '$lib/state.svelte';
	import ProfileDropdown from '$lib/components/ProfileDropdown.svelte';

	let { children } = $props();

	async function logout(e) {
		e.preventDefault();
		await dbLogout();
		authState.authenticated = false;
		goto(resolve('/login'));
	}
</script>

<svelte:head></svelte:head>

<header>
	<nav class="container">
		<ul>
			<li><strong>Заметки</strong></li>
			{#if authState.authenticated}
				<li><a href={resolve('/')}>Все клиенты</a></li>
			{/if}
		</ul>
		<ul>
			{#if authState.authenticated}
				<ProfileDropdown {logout} />
			{:else}
				<li><a href={resolve('/login')} class="contrast">Войти</a></li>
			{/if}
		</ul>
	</nav>
</header>

<main class="container">{@render children()}</main>

<style>
	header {
		border-bottom: 1px solid var(--pico-primary-border);
	}
</style>
