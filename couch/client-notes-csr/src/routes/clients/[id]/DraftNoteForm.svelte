<script>
	import { clearDraftNote, finalizeDraftNote, isDraftNoteEmpty, updateNote } from '$lib/clients';
	import { debounce, isoDateToDate, timeAgoInWords } from '$lib/utilities';
	import { SvelteDate } from 'svelte/reactivity';

	let { note: originalNote, close, addNewNote, setSessionCount, setDraftNote } = $props();
	let note = $derived.by(() => {
		let _ = $state(originalNote);
		return _;
	});
	let now = new SvelteDate();
	let savedAt = new SvelteDate();
	let savedAgo = $derived(timeAgoInWords(now, savedAt));

	$effect(() => {
		const interval = setInterval(() => {
			now.setTime(Date.now());
		}, 1000);

		return () => {
			clearInterval(interval);
		};
	});

	async function onsubmit(e) {
		e.preventDefault();
		const { finalNote, newDraftNote, client } = await finalizeDraftNote(note);
		addNewNote(finalNote);
		setSessionCount(client.sessionCount);
		setDraftNote(newDraftNote);
		close();
	}

	const saveDraft = debounce(
		async () => {
			note = (await updateNote(note)).note;
			savedAt.setTime(Date.now());
		},
		500,
		false
	);

	async function closeDraft() {
		if (isDraftNoteEmpty(note)) {
			close();
		} else {
			if (confirm('Удалить черновик заметки?')) {
				const newDraftNote = (await clearDraftNote(note)).draftNote;
				setDraftNote(newDraftNote);
				close();
			}
		}
	}
</script>

<article>
	<p>📝 Черновик • {savedAgo}</p>
	<form method="post" {onsubmit}>
		<label
			>Дата сессии<input
				type="date"
				name="sessionAt"
				bind:value={note.sessionAt}
				onchange={saveDraft}
			/>
			<small>Влечёт изменение счётчика сессий</small>
		</label>
		<textarea name="body" rows="6" bind:value={note.body} oninput={saveDraft}></textarea>
		<input type="submit" value="Сохранить" disabled={isDraftNoteEmpty(note)} />
		<input type="button" value="Отмена" class="secondary button" onclick={closeDraft} />
	</form>
</article>

<style>
	form > *:last-child {
		margin-bottom: 0;
	}
</style>
