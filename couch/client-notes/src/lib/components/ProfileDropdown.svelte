<script>
	import { currentUser } from '$lib/db';

	let { logout } = $props();
</script>

<details class="dropdown">
	<summary>{currentUser.name}</summary>
	<ul dir="rtl">
		<li><a href="#logout" onclick={logout}>Выйти</a></li>
	</ul>
</details>

<style>
	summary {
		padding-left: 0.75rem !important;
	}
</style>
