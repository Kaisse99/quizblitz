const mongoose = require('mongoose');

const answerSchema = new mongoose.Schema({
    gameId: String,
    userId: mongoose.Schema.Types.ObjectId,
    questionId: mongoose.Schema.Types.ObjectId,
    selectedAnswer: Number,
    isCorrect: Boolean,
    answeredAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Answer', answerSchema);