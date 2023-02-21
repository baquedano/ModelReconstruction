import { config } from 'dotenv';
import express, { Application, Request } from 'express';
import multer from 'multer';
import { v4 as uuid } from 'uuid';
import fs from 'fs';
import path from 'path';
import { exec } from 'child_process'


config();
const PORT = process.env.PORT || 3000;

const app: Application = express();

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const id = req.params.uuidv4;
        const folderPath = path.join(__dirname, `./temp/images/${id}`);
        fs.mkdirSync(folderPath, { recursive: true });
        return cb(null, folderPath);
    },
    filename: (req, file, cb) => {
        const suffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        return cb(null, file.fieldname + '-' + suffix + file.originalname);
    },
});
const upload = multer({storage: storage});

app.get('/health', (req, res) => {
    res.send('Server is up and running!');
});

app.get('/', (req, res) => {
    res.send('Server is up and running!');
});

app.post('/uploadImages', (req: Request<{uuidv4:string}>, res, next) => {

    const id = uuid();

    req.params.uuidv4 = id

    console.log("[uploadImages] ----- downloading images----- ")
    const uploadHandler = upload.array("photos");
    uploadHandler(req, res, (err) => {
        
        const modelDestFolder = path.join(__dirname, `./temp/models/${id}.usdz`);
        const imgSourceFolder = path.join(__dirname, `./temp/images/${id}`);
        console.log("[uploadImages][uploadHandler] ----- images downloaded ----- ")
        console.log("[uploadImages][uploadHandler] ----- starting photogrammetry ----- ", modelDestFolder, imgSourceFolder)
        exec(`"./HelloPhotogrammetry/Products/usr/local/bin/HelloPhotogrammetry" "${imgSourceFolder}" "${modelDestFolder}" -d raw -o sequential -f normal`, (err, stdout, stderr) => {
            if (err) {  
              console.error(err);  
              return;  
            }
            console.log('[uploadImages][uploadHandler] ----- photogrammetry finished successfully. -----', {err, stdout, stderr, exists: fs.existsSync(modelDestFolder)})
            res.sendFile(path.join(__dirname, `/temp/models/${id}.usdz`));
            
            // do cleanup
            fs.rm(imgSourceFolder, { recursive: true}, () => {});
            // fs.rmdir(modelDestFolder, { recursive: true}, () => {});
        })
    });
});

app.listen(PORT, () => {
    console.log(`Server is listening on port ${PORT}`);
});