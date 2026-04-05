<script>
	import { removeNote, updateNote } from '$lib/clients';

	let { note: originalNote, close, setNote } = $props();
	let note = $derived.by(() => {
		let _ = $state(originalNote);
		return _;
	});
	let hasChanges = $derived(JSON.stringify(originalNote) !== JSON.stringify(note));
	let hideDeleted = $state(false);

	async function onsubmit(e) {
		e.preventDefault();
		note = (await updateNote(note)).note;
		setNote(note);
		close();
	}

	function cancel(e) {
		if (hasChanges) {
			if (
				confirm('У вас есть несохранённые изменения. Уверены, что хотите отменить редактирование?')
			) {
				close();
			}
		} else {
			close();
		}
	}

	async function remove(e) {
		if (confirm('Уверены, что хотите удалить?')) {
			await removeNote(note);
			hideDeleted = true;
		}
	}
</script>

{#if !hideDeleted}
	<article>
		<form method="post" {onsubmit}>
			<label>Дата сессии<input type="date" name="sessionAt" bind:value={note.sessionAt} /> </label>
			<textarea name="body" rows="6" bind:value={note.body}></textarea>
			<input type="submit" value="Сохранить" disabled={!hasChanges} />
			<input type="button" value="Отмена" class="secondary" onclick={cancel} />
			<input type="button" value="Удалить" class="outline secondary" onclick={remove} />
		</form>
	</article>
{/if}

<style>
	form > *:last-child {
		margin-bottom: 0;
	}
</style>
