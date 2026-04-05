<script>
	import { isoDateToDate, isPresent } from '$lib/utilities';
	import PaymentForm from './PaymentForm.svelte';

	let { payment } = $props();

	let isEditMode = $state(false);
	let date = $derived(
		isPresent(payment.paidAt) ? isoDateToDate(payment.paidAt).toLocaleDateString() : ''
	);

	$inspect(payment);
</script>

{#if isEditMode}
	<PaymentForm
		{payment}
		close={() => (isEditMode = false)}
		setPayment={(newPayment) => (payment = newPayment)}
	/>
{:else}
	<article>
		<p class="payment-amount">{payment.amount} {payment.currency}</p>
		<footer>
			<a href="#edit-payment" onclick={() => (isEditMode = true)}>Редактировать</a>
			<span>{date}</span>
		</footer>
	</article>
{/if}

<style>
	footer {
		display: flex;
		justify-content: space-between;
	}

	.payment-amount {
		font-size: 1.2em;
	}
</style>
