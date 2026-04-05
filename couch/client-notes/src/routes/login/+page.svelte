<script>
	import { resolve } from '$app/paths';
	import Alert from '$lib/components/Alert.svelte';
	import { login } from '$lib/db';
	import { goto } from '$app/navigation';
	import { authState } from '$lib/state.svelte';

	let errorMessage = $state();

	async function onsubmit(e) {
		e.preventDefault();
		const form = new FormData(e.target);
		const name = form.get('name');
		const password = form.get('password');

		if (await login(name, password)) {
			authState.authenticated = true;
			goto(resolve('/'));
		} else {
			errorMessage = 'Неправильный логин или пароль';
		}
	}
</script>

<h1>Вход</h1>

{#if errorMessage}
	<Alert kind="error" message={errorMessage} />
{/if}
<form method="post" {onsubmit}>
	<fieldset>
		<label>Почта<input type="text" name="name" required /></label>
		<label>Пароль<input type="password" name="password" required /></label>
	</fieldset>
	<input type="submit" value="Войти" />
</form>

<style>
	h1 {
		margin-top: 3rem;
	}
</style>
