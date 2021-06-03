const express = require('express')
const bodyParser = require('body-parser')

const app = express()
const port = 3000

const urlService = require('./lib/urlservice')

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

app.get('/health', (req, res) => {
    res.send("OK")
})

app.get('/', (req, res) => {
    res.send("URL Shorten App")
})


app.post('/api/url', (req, res) => {
  console.log('Got body:', req.body);
  if(req.body && req.body.url) {
    var id = urlService.storeNewUrl(req.body.url);
    res.status(201);
    res.json({ id: id })
  } else {
    res.status(400);
    res.send()
  }
})

app.get('/:urlId', (req, res) => {
    const userId = req.params.urlId
    const url = urlService.findUrlById(userId).then((urlInfo) => {
        if(typeof(urlInfo) != 'undefined' && urlInfo != null) 
            res.redirect(urlInfo)
         else {
            res.status(404)
            res.send()
        }
    });
})

app.listen(port, () => {
  console.log(`URL shortener App is available and listening at http://localhost:${port}`)
})

module.exports = app