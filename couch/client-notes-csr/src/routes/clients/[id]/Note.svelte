<script>
	import { isPresent, isoDateToDate } from '$lib/utilities';
	import NoteForm from './NoteForm.svelte';

	let { note } = $props();
	let date = $derived(
		isPresent(note.sessionAt) ? isoDateToDate(note.sessionAt).toLocaleDateString() : ''
	);
	let isEditMode = $state(false);
</script>

{#if isEditMode}
	<NoteForm {note} close={() => (isEditMode = false)} setNote={(newNote) => (note = newNote)} />
{:else}
	<article>
		<p>{note.body}</p>
		<footer>
			<a href="#edit-note" onclick={() => (isEditMode = true)}>Редактировать</a>
			<span>{date}</span>
		</footer>
	</article>
{/if}

<style>
	footer {
		display: flex;
		justify-content: space-between;
	}
</style>
