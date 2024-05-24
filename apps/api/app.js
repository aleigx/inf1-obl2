const express = require('express');
const AWS = require('aws-sdk');
const multer = require('multer');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const upload = multer({ storage: multer.memoryStorage() });

const s3 = new AWS.S3();
const sqs = new AWS.SQS();

const FILES_BUCKET = process.env.FILES_BUCKET;
const ORDERS_BUCKET = process.env.ORDERS_BUCKET;
const QUEUE_URL = process.env.QUEUE_URL;

app.get('/health', (req, res) => {
    res.send('Healthy');
});

app.post('/upload/file', upload.single('file'), (req, res) => {
    const params = {
        Bucket: FILES_BUCKET,
        Key: req.file.originalname,
        Body: req.file.buffer,
    };
    s3.upload(params, (err, data) => {
        if (err) return res.status(500).send(err);
        res.status(200).send(data);
    });
});

app.post('/upload/orders', upload.single('file'), (req, res) => {
    if (req.file.mimetype !== 'application/json') {
        return res.status(400).send('Invalid file type. Only JSON files are allowed.');
    }

    try {
        JSON.parse(req.file.buffer.toString());
    } catch (err) {
        return res.status(400).send('Invalid JSON file.');
    }

    const params = {
        Bucket: ORDERS_BUCKET,
        Key: req.file.originalname,
        Body: req.file.buffer,
    };
    s3.upload(params, (err, data) => {
        if (err) return res.status(500).send(err);
        res.status(200).send(data);
    });
});

app.post('/notifications', (req, res) => {
    const params = {
        MessageBody: JSON.stringify(req.body),
        QueueUrl: QUEUE_URL,
    };
    sqs.sendMessage(params, (err, data) => {
        if (err) return res.status(500).send(err);
        res.status(200).send(data);
    });
});

app.get('/notifications', (req, res) => {
    const params = {
        QueueUrl: QUEUE_URL,
        MaxNumberOfMessages: 1,
    };
    sqs.receiveMessage(params, (err, data) => {
        if (err) return res.status(500).send(err);
        res.status(200).send(data.Messages ? data.Messages[0] : {});
    });
});

const port = 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
