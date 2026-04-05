import { getOrCreateDraftNote, listActivitiesForClient } from '$lib/clients';

export async function load({ params }) {
	const [activities, draftNote] = await Promise.all([
		listActivitiesForClient(params.id),
		getOrCreateDraftNote(params.id)
	]);
	return { activities, draftNote };
}
