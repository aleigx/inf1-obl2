const express = require('express');
const AWS = require('aws-sdk');
const multer = require('multer');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const upload = multer({ storage: multer.memoryStorage() });

const FILES_BUCKET = process.env.FILES_BUCKET;
const ORDERS_BUCKET = process.env.ORDERS_BUCKET;
const QUEUE_URL = process.env.QUEUE_URL;
const REGION = process.env.REGION;

AWS.config.update({ region: REGION });

const s3 = new AWS.S3();
const sqs = new AWS.SQS();

app.get('/health', (req, res) => {
    res.send('Healthy');
});

app.post('/upload/file', upload.single('file'), (req, res) => {
    try {
        console.log("Uploading file " + req.file.originalname);
        const params = {
            Bucket: FILES_BUCKET,
            Key: req.file.originalname,
            Body: req.file.buffer,
        };
        s3.upload(params, (err, data) => {
            if (err) return res.status(500).send(err);
            res.status(200).send(data);
        });    
    } catch (err) {
        return res.status(500).send(err);
    }
});

app.post('/upload/orders', upload.single('file'), (req, res) => {
    try {
        console.log("Uploading orders " + req.file.originalname);
        if (req.file.mimetype !== 'application/json') {
            return res.status(400).send('Invalid file type. Only JSON files are allowed.');
        }
        JSON.parse(req.file.buffer.toString());
        const params = {
            Bucket: ORDERS_BUCKET,
            Key: req.file.originalname,
            Body: req.file.buffer,
        };
        s3.upload(params, (err, data) => {
            if (err) return res.status(500).send(err);
            res.status(200).send(data);
        });
    } catch (err) {
        return res.status(500).send(err);
    }
});

app.post('/notifications', (req, res) => {
    try {
        console.log("Sending notification " + JSON.stringify(req.body));
        const params = {
            MessageBody: JSON.stringify(req.body),
            QueueUrl: QUEUE_URL,
        };
        sqs.sendMessage(params, (err, data) => {
            if (err) return res.status(500).send(err);
            res.status(200).send(data);
        });
    } catch (err) {
        return res.status(500).send(err);
    }
});

app.get('/notifications', (req, res) => {
    try {
        console.log("Receiving notification");
        const params = {
            QueueUrl: QUEUE_URL,
            MaxNumberOfMessages: 1,
        };
        sqs.receiveMessage(params, (err, data) => {
            console.log(data);
            if (err) return res.status(500).send(err);
            if (!data.Messages || !data.Messages[0]) return res.status(404).send('No messages in the queue');
            sqs.deleteMessage({
                QueueUrl: QUEUE_URL,
                ReceiptHandle: data.Messages[0].ReceiptHandle,
            }, (err, data) => {
                if (err) return res.status(500).send(err);
                res.status(200).send(JSON.parse(data.Messages[0].Body));
            });
        });
    } catch (err) {
        return res.status(500).send(err);
    }
});

const port = 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
