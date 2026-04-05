<script>
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { addClient } from '$lib/clients';
	import * as couch from '$lib/couch';
	import { db } from '$lib/db';

	let { client: clientProp } = $props();
	let client = $derived.by(() => {
		let _ = $state(clientProp);
		return _;
	});

	const submitName = $derived(couch.isNew(client) ? 'Сохранить' : 'Добавить');
	const onsubmit = $derived.by(() => {
		if (couch.isNew(client)) {
			return async (e) => {
				e.preventDefault();
				client = await addClient(db, client);
				goto(resolve('/clients/[id]', { id: client._id }));
			};
		}
	});
</script>

<form action="POST" {onsubmit}>
	<fieldset>
		<label>Имя<input type="text" name="name" bind:value={client.name} required /></label>
		<label>Начало работы<input type="date" name="startedAt" bind:value={client.startedAt} /></label>
		<label
			>Количество сессий<input
				type="number"
				name="sessionCount"
				bind:value={client.sessionCount}
			/></label
		>
		<label>О клиенте<textarea name="bio" rows="6" bind:value={client.bio}></textarea></label>
	</fieldset>
	<input type="submit" value={submitName} />
</form>
