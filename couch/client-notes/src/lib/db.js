import PouchDB from 'pouchdb-browser';
import PouchDBFind from 'pouchdb-find';

PouchDB.plugin(PouchDBFind);

const host = import.meta.env.VITE_HOST;
const dbServerUrl = `${host}/db`;

const pouchdbOptions = {
	skip_setup: true,
	fetch: async function (url, opts) {
		const res = await PouchDB.fetch(url, opts);
		if (res.status === 401) {
			logout();
			remoteDB = null;
		}
		return res;
	}
};

function mapDbName(name) {
	if (name.startsWith('_')) return name;

	const encoder = new TextEncoder();
	const bytes = encoder.encode(name);

	const hex = Array.from(bytes)
		.map((b) => b.toString(16).padStart(2, '0'))
		.join('');

	return 'userdb-' + hex;
}

let remoteDB = null;
function initRemoteDatabaseForUser(username) {
	if (remoteDB) return;

	const dbname = mapDbName(username);
	const databaseUrl = `${dbServerUrl}/${dbname}`;
	remoteDB = new PouchDB(databaseUrl, pouchdbOptions);
}

function destroyRemoteDatabase() {
	remoteDB = null;
}

export { remoteDB as db };

/*
 * Authentication
 */

const noUser = { name: null, roles: [] };
const sessionUrl = `${dbServerUrl}/_session`;

let isAuthenticated = false;

export let currentUser = noUser;

export async function ensureAuthenticated() {
	if (isAuthenticated) {
		return true;
	}

	try {
		const res = await fetch(sessionUrl);
		const json = await res.json();

		/*
		 * Returns on unsuccessful login:
		 * {"ok":true,"userCtx":{"name":null,"roles":[]},
		 *  "info":{"authentication_handlers":["cookie","default"]}}
		 */

		if (json.userCtx.name) {
			isAuthenticated = true;
			currentUser = json.userCtx;
			initRemoteDatabaseForUser(json.userCtx.name);
		} else {
			throw new Error('ensureAuthenticated return name: null from CouchDB');
		}
	} catch (err) {
		console.warn('Auth check failed:', err);
		isAuthenticated = false;
		currentUser = noUser;
		destroyRemoteDatabase();
	}

	return isAuthenticated;
}

export async function login(name, password) {
	const res = await fetch(sessionUrl, {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: new URLSearchParams({ name, password })
	});

	if (res.ok) {
		const json = await res.json();
		isAuthenticated = true;
		currentUser.name = json.name;
		currentUser.roles = json.roles;
		initRemoteDatabaseForUser(json.name);
		return true;
	}
	return false;
}

export async function logout() {
	try {
		await fetch(sessionUrl, { method: 'DELETE' });
	} catch {} // eslint-disable-line no-empty
	isAuthenticated = false;
	currentUser = noUser;
	destroyRemoteDatabase();
}
