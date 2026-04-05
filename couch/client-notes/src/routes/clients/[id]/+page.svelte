<script>
	import { resolve } from '$app/paths';

	let { data } = $props();
	let client = $derived.by(() => {
		const _ = $state(data.client);
		return _;
	});
</script>

<nav>
	<ul>
		<li><a href={resolve('/')}>Назад</a></li>
	</ul>
	<ul>
		<li><a href={resolve('/clients/[id]/edit', { id: client._id })}>Редактировать</a></li>
	</ul>
</nav>

<section>
	<header>
		<hgroup>
			<h1>{client.name}</h1>
			<p>{client.sessionCount} сессий</p>
		</hgroup>
	</header>
	{#if client.bio}
		<p>{client.bio}</p>
	{/if}
	<footer>
		<div>Первая сессия</div>
		<div>Последняя сессия</div>
		<div>02.03.2025</div>
		<div>01.02.2026</div>
	</footer>
</section>

<style>
	footer {
		display: grid;
		grid-template-columns: max-content max-content;
		font-size: smaller;

		--border-style: 1px solid var(--pico-primary-border);

		& > div:nth-child(1) {
			border-bottom: var(--border-style);
			border-right: var(--border-style);
			text-align: right;
		}
		& > div:nth-child(2) {
			border-bottom: var(--border-style);
		}
		& > div:nth-child(3) {
			border-right: var(--border-style);
			text-align: right;
		}

		& > * {
			padding: 0.3rem;
		}
	}
</style>
