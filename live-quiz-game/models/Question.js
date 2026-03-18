const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
    question: { type: String, required: true },
    options: { type: [String], required: true },
    correctAnswerIndex: { type: Number, required: true },
    category: String,
    difficulty: String
});

module.exports = mongoose.model('Question', questionSchema);