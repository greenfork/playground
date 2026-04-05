import { db } from './db';
import { ulid } from 'ulid';
import { dateToIsoDate, isBlank, isPresent, presence } from './utilities';

/**
 * @typedef {Object} Client
 * @property {string} _id
 * @property {string} _rev
 * @property {string} name
 * @property {number} sessionCount
 * @property {string} [startedAt]
 * @property {string} [lastActivityAt]
 * @property {string} bio
 * @property {string} createdAt
 */

/**
 * @typedef {Object} CreateClient
 * @property {string} name
 * @property {number} sessionCount
 * @property {string} [startedAt]
 * @property {string} bio
 */

/**
 * @param {CreateClient} params
 * @returns {Promise<{ok: boolean, client: Client}>}
 */
export async function addClient(params) {
	const clientParams = {
		...params,
		_id: `client:${ulid()}`,
		type: 'client',
		sessionCount: parseInt(presence(params.sessionCount) ?? '0'),
		startedAt: params.startedAt,
		createdAt: new Date().toISOString()
	};

	const resp = await db.put(clientParams);
	const client = { ...clientParams, _rev: resp.rev };
	return { ok: true, client };
}

export const newClient = { sessionCount: 0, startedAt: dateToIsoDate(new Date()), bio: '' };

/**
 *
 * @param {Client} client
 * @returns {Promise<{ok: boolean, client: Client}>}
 */
export async function updateClient(client) {
	const resp = await db.put(client);
	const newClient = { ...client, _rev: resp.rev };
	return { ok: true, client: newClient };
}

/**
 *
 * @returns
 */
export async function listClients() {
	const clients = await db.allDocs({
		include_docs: true,
		startkey: `client:`,
		endkey: `client:\ufff0`
	});
	return { ok: true, clients };
}

/**
 *
 * @param {string} id
 * @returns {Promise<Client>}
 */
export async function getClientById(id) {
	return db.get(id);
}

/**
 * @typedef {Object} Note
 * @property {string} _id
 * @property {string} _rev
 * @property {string} clientId
 * @property {string} type
 * @property {string} status
 * @property {string} body
 * @property {string|null} sessionAt
 * @property {string} createdAt
 */

/**
 *
 * @param {Note} note
 * @returns {boolean}
 */
export function isDraftNoteEmpty(note) {
	return isBlank(note.body) && isBlank(note.sessionAt);
}

/**
 *
 * @param {Note} note
 * @returns {boolean}
 */
export function isDraftNote(note) {
	return note._id.startsWith('draft-note:');
}

/**
 *
 * @param {string} clientId
 * @returns {Promise<Note>}
 */
export async function getOrCreateDraftNote(clientId) {
	const id = `draft-note:${clientId}`;
	let note;
	try {
		note = await db.get(id);
	} catch {
		const noteParams = {
			clientId,
			type: 'note',
			status: 'draft',
			_id: id
		};
		const resp = await db.put(noteParams);
		note = { ...noteParams, _rev: resp.rev };
	}
	return note;
}

/**
 *
 * @param {Note} draftNote
 * @returns
 */
export async function finalizeDraftNote(draftNote) {
	const client = await db.get(draftNote.clientId);
	const finalNoteParams = {
		_id: `note:${ulid()}`,
		clientId: draftNote.clientId,
		type: 'note',
		status: 'final',
		sessionAt: presence(draftNote.sessionAt),
		body: draftNote.body,
		createdAt: new Date().toISOString()
	};
	const draftNoteParams = { ...draftNote, body: '', sessionAt: null };
	if (isPresent(draftNote.sessionAt)) {
		client.sessionCount += 1;
		await db.put(client);
	}
	const [draftResp, finalResp] = await db.bulkDocs([draftNoteParams, finalNoteParams]);
	const newDraftNote = { ...draftNoteParams, _rev: draftResp.rev };
	const finalNote = { ...finalNoteParams, _rev: finalResp.rev };
	return { ok: true, newDraftNote, finalNote, client };
}

/**
 *
 * @param {Note} draftNote
 * @returns
 */
export async function clearDraftNote(draftNote) {
	const newDraftNote = { ...draftNote, body: '', sessionAt: null };
	const resp = await db.put(newDraftNote);
	return { ok: true, draftNote: { ...newDraftNote, _rev: resp.rev } };
}

/**
 *
 * @param {string} id
 * @returns {Promise<Note>}
 */
export async function getNote(id) {
	return db.get(id);
}

/**
 * @typedef {Object} NoteResponse
 * @property {boolean} ok
 * @property {Note} note
 */

/**
 *
 * @param {Note} note
 * @returns {Promise<NoteResponse>}
 */
export async function updateNote(note) {
	const resp = await db.put(note);
	return { ok: true, note: { ...note, _rev: resp.rev } };
}

/**
 *
 * @param {Note} note
 * @returns
 */
export async function removeNote(note) {
	await db.remove(note);
	return { ok: true };
}

/**
 *
 * @param {string} clientId
 * @returns {Promise<Array<any>>}
 */
export async function listActivitiesForClient(clientId) {
	const resp = await db.query('activities-for-client', {
		endkey: [clientId],
		startkey: [clientId, {}],
		descending: true,
		include_docs: true
	});

	return resp.rows.map((r) => r.doc);
}

/**
 * @typedef {Object} CreatePayment
 * @property {string} paidAt
 * @property {number} amount
 * @property {string} currency
 */
/**
 * @typedef {Object} Payment
 * @property {string} _id
 * @property {string} _rev
 * @property {string} paidAt
 * @property {number} amount
 * @property {string} currency
 * @property {string} clientId
 * @property {string} createdAt
 */

/**
 *
 * @param {string} clientId
 * @param {CreatePayment} params
 * @returns {Promise<{ok: boolean, payment: Payment}>}
 */
export async function addPayment(clientId, params) {
	const payment = {
		...params,
		clientId,
		_id: `payment:${ulid()}`,
		type: 'payment',
		createdAt: new Date().toISOString()
	};
	const resp = await db.put(payment);
	return { ok: true, payment: { ...payment, _rev: resp.rev } };
}

/**
 *
 * @param {Payment} payment
 * @returns {Promise<{ok: boolean, payment: Payment}>}
 */
export async function updatePayment(payment) {
	const resp = await db.put(payment);
	return { ok: true, payment: { ...payment, _rev: resp.rev } };
}

/**
 *
 * @param {Payment} payment
 * @returns
 */
export async function removePayment(payment) {
	await db.remove(payment);
	return { ok: true };
}
