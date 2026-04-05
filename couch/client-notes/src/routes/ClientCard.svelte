<script>
	import { resolve } from '$app/paths';

	let { client } = $props();
	let lastSessionTime = $derived(
		client.lastSessionAt
			? new Date(client.lastSessionAt).toLocaleDateString()
			: new Date(client.createdAt).toLocaleDateString()
	);
	const sessionCountHuman = $derived(
		client.sessionCount ? `${client.sessionCount} сессии` : 'Нет сессий'
	);
</script>

<article>
	<!-- <img class="paperside" src="/images/paperside-plain.svg" alt="paperside" /> -->
	<h2>{client.name}</h2>
	<span>{lastSessionTime}</span>
	<a title="Открыть" class="notebook-corner" href={resolve('/clients/[id]', { id: client._id })}>
		<div class="corner"></div>
		<!-- <span class="notebook-corner-counter">953</span> -->
	</a>
</article>

<style>
	article {
		position: relative;
		overflow: hidden;
		--corner-size: 3.2rem;
		min-height: calc(var(--corner-size) * 3);
	}
	article > a.notebook-corner > .corner {
		position: absolute;
		right: 0;
		bottom: 0;
		width: calc(var(--corner-size) * 2);
		height: 0;
		border-top: var(--corner-size) solid transparent;
		border-bottom: var(--corner-size) solid transparent;
		border-left: var(--corner-size) solid var(--pico-color);
		rotate: 45deg;
		translate: var(--corner-size) var(--corner-size);
	}
	.mynote {
		position: relative;
		overflow: hidden;
		--corner-size: 3rem;
		min-height: calc(var(--corner-size) * 3);
		--paper-side-size: 25px;
		padding-left: calc(var(--paper-side-size) + 20px);
		background:
			repeat-y 0% 0% / var(--paper-side-size) url('/images/paperside.webp'),
			var(--pico-card-background-color);
	}
</style>
