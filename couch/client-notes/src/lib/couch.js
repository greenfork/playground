export function isNew(doc) {
	return !doc._rev;
}

export async function query(db, ddoc, opts) {
	const res = await db.query(ddoc, { ...opts, include_docs: true });
	return res.rows.map((r) => r.doc);
}

export async function put(db, doc) {
	const res = await db.put(doc);
	return { ...doc, _rev: res.rev };
}

export async function get(db, doc) {
	if (typeof doc === 'string') {
		return db.get(doc);
	}
	throw new Error('unreachable');
}
