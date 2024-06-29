const AWS = require('aws-sdk');
const s3 = new AWS.S3({
  endpoint: 'http://localhost:4566', 
  s3ForcePathStyle: true, 
});

exports.handler = async (event) => {
  const record = event.Records[0];
  const srcBucket = record.s3.bucket.name;
  const srcKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
  const dstBucket = process.env.DESTINATION_BUCKET;

  try {
    const copyParams = {
      Bucket: dstBucket,
      CopySource: `/${srcBucket}/${srcKey}`,
      Key: srcKey
    };
    await s3.copyObject(copyParams).promise();
    console.log(`Successfully copied ${srcKey} from ${srcBucket} to ${dstBucket}`);
    return {
      statusCode: 200,
      body: JSON.stringify('File copied successfully'),
    };
  } catch (err) {
    console.error(`Error copying ${srcKey} from ${srcBucket} to ${dstBucket}: ${err}`);
    return {
      statusCode: 500,
      body: JSON.stringify('Error copying file'),
    };
  }
};