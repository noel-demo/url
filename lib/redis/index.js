const redis = require("redis");
const { promisify } = require("util");

const client = redis.createClient({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASSWORD
});

const addToRedis = async (key, value) => {
    client.set(key, value);
};

function isKeyPresent(key) {
    client.get(key, function(err, data) {
        if(data === null || err)
            return false;
        return true;
    });
};

const getAsync = promisify(client.get).bind(client);

module.exports = {
    addToRedis,
    getAsync,
    isKeyPresent
};