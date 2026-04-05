<script>
	import { newClient } from '$lib/clients';
	import ClientForm from '../ClientForm.svelte';
	import { resolve } from '$app/paths';
</script>

<nav>
	<ul>
		<li><a href={resolve('/')}>Назад</a></li>
	</ul>
</nav>

<h1>Новый клиент</h1>

<ClientForm client={newClient} />
