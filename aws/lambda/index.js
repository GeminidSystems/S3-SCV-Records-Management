const sf = require('./sf.js');

exports.handler = async (event, context) => {
    try {
        let accessToken = await sf.getAccessToken();

        const res = await sf.callApexRest(event, accessToken);
        console.log('Res', JSON.stringify(res));
        return res;
    } catch(err) {
        console.log(err);
    }
};
