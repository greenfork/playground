import {
	object,
	string,
	number,
	defaulted,
	trimmed,
	mask,
	nonempty,
	optional,
	literal
} from 'superstruct';
import { ulid } from 'ulid';
import * as couch from '$lib/couch';

const ClientBase = {
	_id: defaulted(string(), () => `client:${ulid()}`),
	type: defaulted(literal('client'), () => 'client'),
	name: nonempty(trimmed(string())),
	startedAt: string(),
	lastSessionAt: optional(string()),
	sessionCount: defaulted(number(), () => 0),
	bio: optional(trimmed(string())),
	createdAt: defaulted(string(), () => new Date().toJSON())
};

export const NewClient = object(ClientBase);
export const Client = object({ ...ClientBase, _rev: string() });

export async function listClients(db) {
	const clients = await couch.query(db, 'list-clients', { descending: true });
	return clients;
}

export async function addClient(db, params) {
	const permittedParams = mask(params, NewClient);
	const client = await couch.put(db, permittedParams);
	return client;
}

export const newClient = { sessionCount: 0, startedAt: new Date().toJSON().slice(0, 10) };
