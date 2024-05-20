const express = require('express');
const AWS = require('aws-sdk');
const multer = require('multer');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const upload = multer({ storage: multer.memoryStorage() });

const s3 = new AWS.S3();
const sqs = new AWS.SQS();

const BUCKET_FILE = process.argv[2];
const BUCKET_ORDERS = process.argv[3];
const SQS_QUEUE_URL = process.argv[4];

app.get('/health', (req, res) => {
    res.send('Healthy');
});

app.post('/upload/file', upload.single('file'), (req, res) => {
    const params = {
        Bucket: BUCKET_FILE,
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
        Bucket: BUCKET_ORDERS,
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
        QueueUrl: SQS_QUEUE_URL,
    };
    sqs.sendMessage(params, (err, data) => {
        if (err) return res.status(500).send(err);
        res.status(200).send(data);
    });
});

app.get('/notifications', (req, res) => {
    const params = {
        QueueUrl: SQS_QUEUE_URL,
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
