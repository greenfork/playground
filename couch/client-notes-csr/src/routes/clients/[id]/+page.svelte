<script>
	import { isDraftNoteEmpty } from '$lib/clients.js';
	import HeaderNav from '$lib/components/HeaderNav.svelte';
	import { dateToIsoDate, isPresent } from '$lib/utilities.js';
	import Note from './Note.svelte';
	import DraftNoteForm from './DraftNoteForm.svelte';
	import PaymentForm from './PaymentForm.svelte';
	import Payment from './Payment.svelte';

	let { data } = $props();
	let activities = $derived(data.activities);
	let draftNote = $derived.by(() => {
		let _ = $state(data.draftNote);
		return _;
	});
	let showDraftNote = $derived(!isDraftNoteEmpty(draftNote));
	let showPaymentForm = $state(false);

	let client = $derived.by(() => {
		let _ = $state(data.client);
		return _;
	});

	let startedAt = $derived(
		isPresent(client.startedAt) ? new Date(client.startedAt).toLocaleDateString() : 'Не заполнено'
	);

	function prependActivity(activity) {
		activities = [activity, ...activities];
	}

	const emptyPayment = { paidAt: dateToIsoDate(new Date()), amount: 0, currency: 'RUB' };
</script>

<section>
	<HeaderNav>
		<ul>
			<li><a href="/">Назад к клиентам</a></li>
		</ul>
		<ul>
			<li><a href="/clients/{client._id}/edit">Редактировать</a></li>
		</ul>
	</HeaderNav>

	<h1>{client.name}</h1>
	<ul>
		<li><b>Начало работы:</b> {startedAt}</li>
		<li><b>Количество сессий:</b> {client.sessionCount}</li>
	</ul>

	{#if isPresent(client.bio)}
		<details>
			<summary>Личная информация</summary>
			{client.bio}
		</details>
	{/if}
</section>

<section>
	<h2>Заметки</h2>
	<div>
		<button type="button" onclick={() => (showDraftNote = true)} disabled={showDraftNote}
			>Новая заметка</button
		>
		<button type="button" onclick={() => (showPaymentForm = true)} disabled={showPaymentForm}
			>Новая оплата</button
		>
	</div>

	<section>
		{#if showPaymentForm}
			<PaymentForm
				payment={emptyPayment}
				close={() => (showPaymentForm = false)}
				addNewPayment={prependActivity}
				clientId={client._id}
			/>
		{/if}
		{#if showDraftNote}
			<DraftNoteForm
				note={draftNote}
				close={() => (showDraftNote = false)}
				addNewNote={prependActivity}
				setSessionCount={(n) => (client.sessionCount = n)}
				setDraftNote={(note) => (draftNote = note)}
			/>
		{/if}
		{#each activities as activity (activity._id)}
			{#if activity.type === 'note'}
				<Note note={activity} />
			{:else if activity.type === 'payment'}
				<Payment payment={activity} />
			{/if}
		{/each}
	</section>
</section>
