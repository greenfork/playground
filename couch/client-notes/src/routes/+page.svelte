<script>
	import ClientCard from './ClientCard.svelte';
	import { resolve } from '$app/paths';

	let { data } = $props();
</script>

<h1>Мои клиенты</h1>

<p>
	<a href={resolve('/clients/new')}>Новый клиент</a>
</p>

<section id="clients">
	{#each data.clients as client (client._id)}
		<ClientCard {client} />
	{/each}
</section>

<style>
	section#clients {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(30ch, 1fr));
		gap: 0.5rem 1rem;
	}
	h1 {
		margin-top: 3rem;
	}
</style>
