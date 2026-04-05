<script>
	import { slide } from 'svelte/transition';

	let { kind, message } = $props();
	const klass = $derived(`alert-${kind}`);
</script>

<article class={klass} transition:slide>
	<p>{message}</p>
</article>

<style>
	.alert-error {
		border: 1px solid var(--pico-form-element-invalid-border-color);
	}
	p {
		margin: 0;
		color: var(--pico-del-color);
	}
</style>
