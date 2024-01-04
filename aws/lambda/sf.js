const https = require('https');
const config = require("./config");

let accessToken = null;

const callApexRest = async(event, accessToken) => {
    // Extract the contact ID from the object key
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
    const keyParts = key.split('/');
    const fileName = keyParts[keyParts.length - 1];
    const fileNameParts = fileName.split('_');
    const contact_id = fileNameParts[0];

    const data = {
        'vendorCallKey': contact_id
    }
    console.log(data);

    return new Promise((resolve, reject) => {

        let url = new URL(config.restApiEndpoint);
        const request = {
            hostname: url.hostname,
            path: url.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `OAuth ${accessToken}`
            }
        };
        console.log('Req', request)
        console.log(`postUnhandledEvent url : ${url}`);
        let req = https.request(request, (res) => {
            handleResponse(res, resolve, reject);
        }).on('error', err => {
            console.log('postUnhandledEvent', err);
            reject(err);
        });
        req.write(JSON.stringify(data));
        req.end();
    });
}



const getAccessToken = async() => {
    console.log('Getting access token...');
    if (!accessToken) {
        const response = await auth();
        console.log(response);
        accessToken = response.access_token
        return accessToken;
    }
    console.log(accessToken);
    return accessToken;
}

const auth = async() => {
    return new Promise((resolve, reject) => {
        let url = new URL(config.sfAuthEndpoint);
        let body = new URLSearchParams({
            'username': config.username,
            'password': config.password,
            'grant_type': 'password',
            'client_id': config.consumerKey,
            'client_secret': config.privateKey
        }).toString();

        const request = {
            hostname: url.hostname,
            path: url.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(body)
            }
        }

        console.log(request);

        let req = https.request(request, (res) => {
            handleResponse(res, resolve, reject);
        }).on('error', err => {
            console.log('auth', err);
            reject({
                statusCode : 401,
                error : err
            });
        });

        req.write(body);
        req.end();
    });
}

const handleResponse = (res, resolver, rejecter) =>{
    res.setEncoding('utf8');
    console.log(`statusCode : ${res.statusCode}`);
    let str = '';
    res.on('data', (chunk) => {
        str += chunk;
    });
    res.on('end', () => {
        try {
            let obj = str !== '' ? JSON.parse(str) : '';
            if(res.statusCode >= 200 && res.statusCode <= 299) {
                resolver(obj);
            } else {
                obj.statusCode = res.statusCode;
                rejecter(obj);
            }
        } catch (error) {
            rejecter(error);
        }
    });
}

module.exports = {
    getAccessToken,
    callApexRest
}