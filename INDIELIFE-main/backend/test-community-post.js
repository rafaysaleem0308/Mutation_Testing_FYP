const axios = require('axios');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
require('dotenv').config();

const API_BASE = 'http://localhost:3000';
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_here';
const User = require('./models/user.model');

async function testCreateCommunityPost() {
  try {
    // Connect to MongoDB to get a real user
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/IndieLife');
    
    // Get first user from database
    const user = await User.findOne();
    if (!user) {
      console.error('❌ No users in database! Please create a user first.');
      process.exit(1);
    }
    
    const testUserId = user._id;
    const testUserEmail = user.email;
    
    console.log(`✅ Found user: ${testUserEmail} (ID: ${testUserId})`);
    
    // Create a test token
    const testToken = jwt.sign(
      { 
        userId: testUserId,
        email: testUserEmail,
        role: 'user'
      },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    console.log('\n🔍 Testing community post creation...');
    console.log('📝 Token:', testToken.substring(0, 30) + '...');
    console.log('📤 Sending POST request to /api/community/posts');

    const response = await axios.post(
      `${API_BASE}/api/community/posts`,
      {
        content: 'This is a test community post from automated test',
        category: 'Social'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testToken}`
        }
      }
    );

    console.log('✅ Success! Response:', JSON.stringify(response.data, null, 2));
    mongoose.connection.close();
  } catch (error) {
    if (error.response) {
      console.error('❌ API Error:');
      console.error('   Status:', error.response.status);
      console.error('   Data:', JSON.stringify(error.response.data, null, 2));
    } else if (error.code === 'ECONNREFUSED') {
      console.error('❌ Connection Error: Server is not running on port 3000');
    } else if (error.message) {
      console.error('❌ Error:', error.message);
      console.error('Details:', error);
    } else {
      console.error('❌ Unknown error:', error);
    }
    mongoose.connection.close();
    process.exit(1);
  }
}

testCreateCommunityPost();
