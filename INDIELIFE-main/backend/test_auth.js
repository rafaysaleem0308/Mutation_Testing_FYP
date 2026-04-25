const { generateAccessToken, buildUserPayload } = require("./routes/auth.routes");
const user = { _id: "123", email: "test@test.com", username: "test", firstName: "Test", lastName: "User" };
try {
    const payload = buildUserPayload(user);
    const token = generateAccessToken(payload);
    console.log("Success:", !!token);
} catch (err) {
    console.error("Error:", err.message);
}
