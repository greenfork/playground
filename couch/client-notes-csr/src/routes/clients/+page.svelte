<script>
	import { newClient } from '$lib/clients';
	import HeaderNav from '$lib/components/HeaderNav.svelte';
	import ClientForm from './ClientForm.svelte';

	const client = newClient;
</script>

<section>
	<HeaderNav>
		<ul>
			<li><a href="/">Назад к клиентам</a></li>
		</ul>
	</HeaderNav>

	<h1>Новый клиент</h1>

	<ClientForm {client} />
</section>
