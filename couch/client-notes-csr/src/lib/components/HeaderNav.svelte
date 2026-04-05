<script>
	let { children } = $props();
</script>

<nav>
	{@render children()}
</nav>

<style>
	nav :global(a) {
		text-decoration: underline;
	}
</style>
