var idCreator = require('./id/index.js')
var redisClient = require('./redis/index.js')

function generateNewId() {
    const newId = idCreator.createNewIdentifier()
    return newId;
}

function findNewId() {
    const newId = generateNewId()
    const keyPresent = redisClient.isKeyPresent(newId)
    if(keyPresent)
        return findNewId
    return newId
}

function storeNewUrl(url) {
    const newUrlId = findNewId();
    redisClient.addToRedis(newUrlId, url);
    return newUrlId;
}

function findUrlById(urlId) {
    return redisClient.getAsync(urlId);
}

function getUrl(urlId) {
    const url = redisClient.getAsync(urlId);
    return url;
}

module.exports = {
    findUrlById,
    storeNewUrl
};