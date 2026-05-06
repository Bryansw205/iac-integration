import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3Client = new S3Client({});

const getS3ObjectBuffer = async (bucket, key) => {
    const response = await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    const chunks = [];
    for await (const chunk of response.Body) {
        chunks.push(chunk);
    }
    return Buffer.concat(chunks);
};

export const handler = async (event) => {
    console.log(`Procesando lote de ${event.Records.length} mensajes SQS`);
    
    const batchItemFailures = [];

    for (const sqsRecord of event.Records) {
        try {

            const s3Event = JSON.parse(sqsRecord.body);
            
            if (s3Event.Event === 's3:TestEvent') continue;

            for (const s3Record of s3Event.Records) {
                const sourceBucket = s3Record.s3.bucket.name;
                const sourceKey = decodeURIComponent(s3Record.s3.object.key.replace(/\+/g, ' ')); 
                console.log(`Descargando imagen original: s3://${sourceBucket}/${sourceKey}`);
                const originalImageBuffer = await getS3ObjectBuffer(sourceBucket, sourceKey);
                console.log("Aplicando recorte circular...");
                const circleSvg = Buffer.from(
                    '<svg width="40" height="40"><circle cx="20" cy="20" r="20" /></svg>'
                );

                const processedImageBuffer = await sharp(originalImageBuffer)
                    .resize(40, 40, { fit: 'cover' })
                    .composite([{ 
                        input: circleSvg, 
                        blend: 'dest-in' 
                    }])
                    .png()
                    .toBuffer();

                const cleanFileName = sourceKey.replace(process.env.UPLOAD_PREFIX, '').split('.')[0];
                const destinationKey = `${process.env.PROCESSED_PREFIX}${cleanFileName}_circular.png`;

                console.log(`Subiendo imagen procesada: s3://${process.env.S3_BUCKET}/${destinationKey}`);

                await s3Client.send(new PutObjectCommand({
                    Bucket: process.env.S3_BUCKET,
                    Key: destinationKey,
                    Body: processedImageBuffer,
                    ContentType: 'image/png'
                }));
                
                console.log(`Procesamiento exitoso para: ${cleanFileName}`);
            }

        } catch (error) {
            console.error(`Error procesando el mensaje SQS con ID ${sqsRecord.messageId}:`, error);
    
            batchItemFailures.push({ itemIdentifier: sqsRecord.messageId });
        }
    }
    return { batchItemFailures };
};