<script>
	import { goto } from '$app/navigation';
	import { addClient, updateClient } from '$lib/clients';
	import { isBlank } from '$lib/utilities';

	let { client: clientProp } = $props();
	let client = $derived.by(() => {
		let _ = $state(clientProp);
		return _;
	});
	let isNewClient = $derived(isBlank(client._id));

	async function onsubmit(e) {
		e.preventDefault();
		const hasChanges = JSON.stringify(clientProp) !== JSON.stringify(client);
		if (isNewClient) {
			if (hasChanges) {
				client = (await addClient(client)).client;
				goto(`/clients/${client._id}`);
			} else {
				console.warn('New client submitted with no form changes');
			}
		} else {
			if (hasChanges) {
				await updateClient(client);
			}
			goto(`/clients/${client._id}`, { invalidate: ['app:client'] });
		}
	}
</script>

<form method="POST" {onsubmit}>
	<fieldset>
		<label
			>Имя<input type="text" name="name" bind:value={client.name} maxlength="255" required /></label
		>
		<label
			>Количество сессий<input
				type="number"
				name="sessionCount"
				bind:value={client.sessionCount}
				min="0"
				max="1000000"
				required
			/></label
		>
		<label>Первая сессия<input type="date" name="startedAt" bind:value={client.startedAt} /></label>
		<label
			>О клиенте<textarea name="bio" bind:value={client.bio} rows="6" maxlength="1024"
			></textarea></label
		>
	</fieldset>
	<button type="submit">{isNewClient ? 'Добавить' : 'Сохранить'}</button>
</form>
