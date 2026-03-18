const mongoose = require('mongoose');

const gameSessionSchema = new mongoose.Schema({
    gameId: { type: String, required: true },
    players: [
        {
            userId: mongoose.Schema.Types.ObjectId,
            username: String,
            score: { type: Number, default: 0 }
        }
    ],
    startedAt: Date,
    endedAt: Date,
    status: { type: String, enum: ['waiting', 'active', 'completed'], default: 'waiting' }
});

module.exports = mongoose.model('GameSession', gameSessionSchema);