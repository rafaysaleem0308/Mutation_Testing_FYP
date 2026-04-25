const mongoose = require("mongoose");

const chatSchema = new mongoose.Schema(
    {
        participants: [
            {
                user: {
                    type: mongoose.Schema.Types.ObjectId,
                    required: true,
                    refPath: 'participants.modelType'
                },
                modelType: {
                    type: String,
                    required: true,
                    enum: ['User', 'ServiceProvider']
                }
            }
        ],
        lastMessage: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Message'
        },
        serviceId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Service'
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Chat", chatSchema);
