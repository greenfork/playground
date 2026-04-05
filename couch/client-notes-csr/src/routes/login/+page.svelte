<script>
	import { goto } from '$app/navigation';
	import * as auth from '$lib/auth';
	import { onMount } from 'svelte';

	onMount(async () => {
		if (await auth.ensureAuthenticated()) {
			goto('/');
		}
	});

	/**
	 * @param {SubmitEvent} e
	 */
	async function onsubmit(e) {
		e.preventDefault();
		const form = new FormData(/** @type {HTMLFormElement} */ (e.target));
		const name = /** @type String */ (form.get('name'));
		const password = /** @type String */ (form.get('password'));

		if (await auth.login(name, password)) {
			goto('/');
		} else {
			alert('Invalid credentials');
		}
	}
</script>

<h1>Войдите</h1>
<form method="POST" action="/_session" {onsubmit}>
	<fieldset>
		<label for="name">
			Имя
			<input type="text" name="name" /></label
		>
		<label for="password">
			Пароль
			<input type="password" name="password" /></label
		>
	</fieldset>
	<input type="submit" value="Submit" />
</form>
