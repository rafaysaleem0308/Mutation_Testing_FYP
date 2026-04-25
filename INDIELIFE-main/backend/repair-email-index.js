const mongoose = require('mongoose');
const User = require('./models/user.model');
const ServiceProvider = require('./models/service-provider.model');

mongoose.connect('mongodb://localhost:27017/IndieLife').then(async () => {
  try {
    console.log('🔄 Rebuilding indexes for User collection...');
    await User.collection.dropIndexes();
    await User.syncIndexes();
    console.log('✅ User collection indexes rebuilt');
    
    console.log('🔄 Rebuilding indexes for ServiceProvider collection...');
    await ServiceProvider.collection.dropIndexes();
    await ServiceProvider.syncIndexes();
    console.log('✅ ServiceProvider collection indexes rebuilt');
    
    // Verify no orphaned email entries exist
    const users = await User.find({}).select('email');
    console.log('📊 Email addresses in User collection:', users.map(u => u.email));
    
    const sps = await ServiceProvider.find({}).select('email');
    console.log('📊 Email addresses in ServiceProvider collection:', sps.map(sp => sp.email));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}).catch(err => {
  console.error('❌ Connection error:', err.message);
  process.exit(1);
});
