const axios = require('axios');

async function testLogin() {
    try {
        const res = await axios.post('http://localhost:3000/api/admin/login', {
            email: 'admin@indielife.com',
            password: 'password123'
        });
        console.log("Success!", res.data);
    } catch (err) {
        console.error("Error logging in:", err.response ? err.response.data : err.message);
    }
}

testLogin();
