import bootstrap from 'couchdb-bootstrap';

const url = 'http://admin:admin@localhost:5984';
const directory = 'couchdb/';
const options = {
	mapDbName(name) {
		if (name.startsWith('_')) return name;
		return 'userdb-' + Buffer.from(name).toString('hex');
	}
};

bootstrap(url, directory, options, function (error, response) {
	if (error) {
		process.exitCode = 1;
		return console.error(error);
	}

	console.log(JSON.stringify(response, null, '  '));
});
