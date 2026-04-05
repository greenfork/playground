<script>
	import { addPayment, removePayment, updatePayment } from '$lib/clients';
	import { dateToIsoDate } from '$lib/utilities';

	let { close, payment: originalPayment, addNewPayment, setPayment, clientId } = $props();

	let payment = $derived.by(() => {
		let _ = $state(originalPayment);
		return _;
	});
	let hasChanges = $derived(JSON.stringify(originalPayment) !== JSON.stringify(payment));
	let hideDeleted = $state(false);
	const currencies = ['RUB', 'USD', 'EUR', 'AZN'];

	async function onsubmit(e) {
		e.preventDefault();
		if (payment._id) {
			const newPayment = (await updatePayment(payment)).payment;
			setPayment(newPayment);
			close();
		} else {
			const newPayment = (await addPayment(clientId, payment)).payment;
			addNewPayment(newPayment);
			close();
		}
	}

	async function remove(e) {
		if (confirm('Уверены, что хотите удалить?')) {
			await removePayment(payment);
			hideDeleted = true;
		}
	}
</script>

{#if !hideDeleted}
	<article>
		<form method="POST" {onsubmit}>
			<label
				>Дата оплаты<input type="date" name="paidAt" bind:value={payment.paidAt} required /></label
			>
			<fieldset class="grid">
				<input type="number" name="amount" bind:value={payment.amount} required />
				<select name="currency" bind:value={payment.currency} required>
					{#each currencies as currency}
						<option value={currency}>{currency}</option>
					{/each}
				</select>
			</fieldset>
			<input type="submit" value={payment._id ? 'Сохранить' : 'Добавить'} disabled={!hasChanges} />
			<input type="button" value="Отмена" class="secondary" onclick={close} />
			<input type="button" value="Удалить" class="outline secondary" onclick={remove} />
		</form>
	</article>
{/if}
