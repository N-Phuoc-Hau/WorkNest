module.exports = {
    generateRandomUser,
    generateRandomJobSearch,
    logResponse,
    setAuthToken
};

function generateRandomUser(requestParams, context, ee, next) {
    context.vars.randomEmail = `user${Math.floor(Math.random() * 10000)}@test.com`;
    context.vars.randomPassword = `Test${Math.floor(Math.random() * 10000)}`;
    return next();
}

function generateRandomJobSearch(requestParams, context, ee, next) {
    const keywords = ['developer', 'designer', 'manager', 'engineer', 'analyst', 'tester'];
    const locations = ['Hanoi', 'Ho Chi Minh', 'Da Nang', 'Can Tho', 'Hue'];
    
    context.vars.searchKeyword = keywords[Math.floor(Math.random() * keywords.length)];
    context.vars.searchLocation = locations[Math.floor(Math.random() * locations.length)];
    
    return next();
}

function logResponse(requestParams, response, context, ee, next) {
    console.log(`Response status: ${response.statusCode}`);
    console.log(`Response time: ${response.timings.phases.total}ms`);
    
    if (response.statusCode >= 400) {
        console.error(`Error response: ${response.body}`);
    }
    
    return next();
}

function setAuthToken(requestParams, response, context, ee, next) {
    if (response.body) {
        try {
            const data = JSON.parse(response.body);
            if (data.token) {
                context.vars.authToken = data.token;
                console.log('Auth token set successfully');
            }
        } catch (e) {
            console.error('Failed to parse auth response:', e);
        }
    }
    return next();
}
