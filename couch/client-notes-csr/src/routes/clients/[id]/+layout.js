import { getClientById } from '$lib/clients';

export async function load({ params, depends }) {
	depends('app:client');
	const client = await getClientById(params.id);
	return { client };
}
