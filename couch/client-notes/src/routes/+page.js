import { listClients } from '$lib/clients';
import { db } from '$lib/db';

export async function load() {
	const clients = await listClients(db);
	return { clients };
}
