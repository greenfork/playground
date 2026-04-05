<script>
	import HeaderNav from '$lib/components/HeaderNav.svelte';
	import ClientForm from '../../ClientForm.svelte';

	let { data } = $props();
</script>

<section>
	<HeaderNav>
		<ul>
			<li><a href="/clients/{data.client._id}">Назад</a></li>
		</ul>
	</HeaderNav>

	<h1>Клиент <b>{data.client.name}</b></h1>

	<ClientForm client={data.client} />
</section>
