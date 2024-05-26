const AWS = require('aws-sdk');
AWS.config.update({ region: 'us-west-2' });
const s3 = new AWS.S3();
const sqs = new AWS.SQS();

exports.handler = async (event) => {
    const bucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
    const params = {
        Bucket: bucket,
        Key: key
    };
    const data = await s3.getObject(params).promise();
    const orders = JSON.parse(data.Body.toString());
    const sqsParams = {
        MessageBody: JSON.stringify(orders),
        QueueUrl: process.env.SQS_URL
    };
    await sqs.sendMessage(sqsParams).promise();
}