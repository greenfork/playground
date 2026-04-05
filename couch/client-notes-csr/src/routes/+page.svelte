<script>
	import { isoDateToDate } from '$lib/utilities';
	import ClientCard from './ClientCard.svelte';

	/** @type {{ data: import('./$types').PageData }} */
	let { data } = $props();

	let clients = $derived.by(() => {
		return data.clients.map((client) => {
			return {
				...client,
				sessions: client.sessionCount == 0 ? 'Нет сессий' : `${client.sessionCount} сессий`,
				lastSession: client.lastSessionAt
					? isoDateToDate(client.lastSessionAt).toLocaleDateString()
					: ''
			};
		});
	});
</script>

<h1>Мои клиенты</h1>

<p><a href="/clients">Новый клиент</a></p>

<section class="clients-list">
	{#each clients as client (client._id)}
		<ClientCard {client} />
	{/each}
</section>

<style>
	@media (min-width: 768px) {
		.clients-list {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
			gap: 0.25rem 1rem;
		}
	}

	h1 {
		margin-top: 3rem;
	}
</style>
