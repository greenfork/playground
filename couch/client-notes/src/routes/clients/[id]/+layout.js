import { db } from '$lib/db';
import * as couch from '$lib/couch';

export async function load({ params }) {
	const client = await couch.get(db, params.id);
	return { client };
}
