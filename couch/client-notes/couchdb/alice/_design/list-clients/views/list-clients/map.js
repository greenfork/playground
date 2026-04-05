function (doc) {
	if (doc.type === 'client') {
		if (doc.lastSessionAt) {
			const lastSessionAt = new Date(doc.lastSessionAt).toJSON();
			emit(lastSessionAt);
		} else {
			emit(doc.createdAt);
		}
	}
}
