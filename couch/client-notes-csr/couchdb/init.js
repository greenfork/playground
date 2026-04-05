import PouchDB from 'pouchdb';
import PouchDBFind from 'pouchdb-find';

PouchDB.plugin(PouchDBFind);

async function initDatabase(url, username, password) {
	const db = new PouchDB(url, { auth: { username, password } });
	await createIndexForListActivitiesForClient(db);
}

async function createIndexForListActivitiesForClient(db) {
	const ddoc = {
		_id: '_design/activities-for-client',
		views: {
			'activities-for-client': {
				map: function (doc) {
					if (doc.type === 'note' && doc.status === 'final') {
						let sessionAt;
						if (doc.sessionAt) {
							sessionAt = doc.sessionAt;
						} else {
							sessionAt = doc.createdAt.slice(0, 10);
						}
						emit([doc.clientId, sessionAt, doc.createdAt]);
					} else if (doc.type === 'payment') {
						emit([doc.clientId, doc.paidAt, doc.createdAt]);
					}
				}.toString()
			}
		}
	};

	try {
		await db.put(ddoc);
	} catch (err) {
		if (err.name !== 'conflict') {
			throw err;
		}
	}
}

const url = 'http://client-notes.local:5900/db/client-notes';
const username = 'admin';
const password = 'admin';
await initDatabase(url, username, password);
