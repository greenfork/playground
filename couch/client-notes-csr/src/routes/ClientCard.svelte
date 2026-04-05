<script>
	let { client } = $props();
</script>

<article>
	<hgroup>
		<h2>{client.name}</h2>
		<p>{client.sessions}</p>
	</hgroup>
	<footer>
		<a href="/clients/{client._id}">Открыть</a>
		<span>{client.lastSession}</span>
	</footer>
</article>

<style>
	article {
		padding-bottom: 0;
	}

	footer {
		display: flex;
		justify-content: space-between;
		margin-bottom: 0;
	}
</style>
