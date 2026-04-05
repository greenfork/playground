function dbNameToUsername(prefixedHexName) {
	return Buffer.from(prefixedHexName.replace('userdb-', ''), 'hex').toString('utf8');
}

const dbname = process.argv[2];

if (dbname === undefined) {
	console.error('Provide dbname as argument from couch_peruser database');
	process.exit(1);
}

console.log(dbNameToUsername(dbname));
