const { nanoid } = require('nanoid')

function createNewIdentifier() {
    return nanoid(10);
}

exports.createNewIdentifier = createNewIdentifier;