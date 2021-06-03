
const request = require("supertest");
const express = require("express");
const index = require("../index");

const app = express();

app.use(express.urlencoded({ extended: false }));
app.use("/", index);
app.use("/api/url", index);


describe("POST /api/url", () => {
    test('Create a shortened Url', async() => {
        const urlDetails = {
            url: "https://irishtimes.com",
        };
        const result = await request(app)
        .post('/api/url')
        .send(urlDetails)
        .expect(201)

        expect(result.body.id.length == 10)
    });
});

describe("GET /:urlId", () => {
    test('Test and invalid id', async() => {
        const result = await request(app)
        .get('/123456789')
        .expect(404)
    });
});

describe("POST /:urlId", () => {
    test('Save a new URL and check', async() => {
        var urlCheck = "https://google.com"
        const urlDetails = {
            url: urlCheck,
        };
        const result = await request(app)
        .post('/api/url')
        .send(urlDetails)
        .expect(201)
        
        if(result.statusCode == 201) {
            const urlId = result.body.id;
            const resultFromId = await request(app)
            .get('/'+urlId)
            .expect(302)
        }
    });
});

