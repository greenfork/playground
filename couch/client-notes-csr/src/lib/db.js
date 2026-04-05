import PouchDB from 'pouchdb-browser';
import PouchDBFind from 'pouchdb-find';

const host = import.meta.env.VITE_HOST;
const database = `${host}/db/client-notes`;

const pouchdbOptions = {
	skip_setup: true,
	fetch: async function (url, opts) {
		const rs = await PouchDB.fetch(url, opts);
		if (rs.status === 401) {
			window.location.pathname = '/login';
		}
		return rs;
	}
};

PouchDB.plugin(PouchDBFind);
const remoteDB = new PouchDB(database, pouchdbOptions);

export { remoteDB as db, remoteDB };
