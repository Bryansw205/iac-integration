import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import busboy from "busboy";
import { v4 as uuidv4 } from "uuid";
import { Readable } from "stream";

const s3Client = new S3Client({});
const parseMultipartEvent = (event) => {
    return new Promise((resolve, reject) => {
        const contentType = event.headers['content-type'] || event.headers['Content-Type'];
        
        if (!contentType || !contentType.includes('multipart/form-data')) {
            return reject(new Error("El Content-Type debe ser multipart/form-data"));
        }

        const bb = busboy({ headers: { 'content-type': contentType } });
        let fileData = null;
        let fileInfo = null;

        bb.on('file', (name, file, info) => {
            const chunks = [];
            fileInfo = info;
            file.on('data', (data) => chunks.push(data));
            file.on('end', () => {
                fileData = Buffer.concat(chunks);
            });
        });

        bb.on('finish', () => {
            if (fileData) resolve({ fileData, fileInfo });
            else reject(new Error("No se encontró ningún archivo en la petición"));
        });

        bb.on('error', (err) => reject(err));
        const isBase64 = event.isBase64Encoded;
        const bodyBuffer = Buffer.from(event.body, isBase64 ? 'base64' : 'utf8');
        const readable = new Readable();
        readable.push(bodyBuffer);
        readable.push(null);
        readable.pipe(bb);
    });
};

export const handler = async (event) => {
    console.log("Iniciando upload...");

    try {
        const { fileData, fileInfo } = await parseMultipartEvent(event);
        const mimeType = fileInfo.mimeType || 'image/jpeg';
        const extension = mimeType.split('/')[1] || 'jpg';
        const fileName = `${uuidv4()}.${extension}`;
        const key = `${process.env.UPLOAD_PREFIX}${fileName}`;
        console.log(`Subiendo archivo: ${key} (${fileData.length} bytes)`);
        await s3Client.send(new PutObjectCommand({
            Bucket: process.env.S3_BUCKET,
            Key: key,
            Body: fileData,
            ContentType: mimeType
        }));

        return {
            statusCode: 200,
            body: JSON.stringify({ 
                message: "Imagen subida exitosamente",
                fileName: fileName 
            })
        };

    } catch (error) {
        console.error("Error en upload-lambda:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message || "Error interno del servidor" })
        };
    }
};