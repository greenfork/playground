import { currentUser } from '$lib/auth';
import { listClients } from '$lib/clients';

export async function load() {
	const { clients } = await listClients(currentUser.name);
	return {
		clients: clients.rows.map((client) => client.doc)
	};
}
