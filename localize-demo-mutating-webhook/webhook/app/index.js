const fs = require('fs')
const express = require('express')
const bodyParser = require('body-parser')
const https = require('https')
//
const mutate = require('./mutate')
//
const app = express()
app.use(bodyParser.json())
//
app.post('/mutate', (req, res, next) => {
    let admReq = req.body.request
    console.log(admReq.uid + ' - ' + admReq.resource.resource + ' - ' + admReq.name + ' - ' + admReq.namespace + ' - ' + admReq.operation)
    mutate.mutate(req.body, (err, resp) => {
        if (err) {
            res.status(500).send({})
        } else {
            res.type('application/json')
            res.status(200).send({
                kind: req.body.kind,
                apiVersion: req.body.apiVersion,
                request: req.body.request,
                response: resp
            })
        }
    })
})
//
https.createServer({
    key: fs.readFileSync('/etc/certs/tls.key'),
    cert: fs.readFileSync('/etc/certs/tls.crt')
}, app).listen(4443);
