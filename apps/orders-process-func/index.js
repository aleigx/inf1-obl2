const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { SQSClient, GetQueueUrlCommand, SendMessageCommand } = require('@aws-sdk/client-sqs');

const REGION = "us-west-2";
const QUEUE_NAME = "notifications-inf1-ob2";

const s3Client = new S3Client({ region: REGION });
const sqsClient = new SQSClient({ region: REGION });

exports.handler = async (event) => {
    try {
        console.log(event);
        const bucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        const getObjectParams = {
            Bucket: bucket,
            Key: key
        };
        const getObjectCommand = new GetObjectCommand(getObjectParams);
        const data = await s3Client.send(getObjectCommand);
        
        const orders = JSON.parse(await streamToString(data.Body));
        const getQueueUrlParams = { QueueName: QUEUE_NAME };
        const getQueueUrlCommand = new GetQueueUrlCommand(getQueueUrlParams);
        const queueUrl = await sqsClient.send(getQueueUrlCommand);
        
        const sendMessageParams = {
            MessageBody: JSON.stringify(orders),
            QueueUrl: queueUrl.QueueUrl
        };
        const sendMessageCommand = new SendMessageCommand(sendMessageParams);
        await sqsClient.send(sendMessageCommand);
    } catch (err) {
        console.error(err);
        throw err;
    }
}

const streamToString = (stream) => new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('error', reject);
    stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
});
