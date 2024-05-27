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
});

app.post('/upload/orders', upload.single('file'), (req, res) => {
    console.log("Uploading orders " + req.file.originalname);
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
    console.log("Sending notification " + JSON.stringify(req.body));
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
    console.log("Receiving notification");
    const params = {
        QueueUrl: QUEUE_URL,
        MaxNumberOfMessages: 1,
    };
    sqs.receiveMessage(params, (err, data) => {
        if (err) return res.status(500).send(err);

        let message = {};

        if (data.Messages) {
            const deleteParams = {
                QueueUrl: QUEUE_URL,
                ReceiptHandle: data.Messages[0].ReceiptHandle,
            };
            sqs.deleteMessage(deleteParams, (err, data) => {
                if (err) return res.status(500).send(err);
                message = JSON.parse(data.Messages[0].Body);
                return res.status(200).send(message);        
            });
        }
        return res.status(200).send(message);
    });
});

const port = 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
