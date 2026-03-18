require('dotenv').config();
const mongoose = require('mongoose');
const Question = require('./models/Question');

const questions = [
    { question: "What is the capital of France?", options: ["Berlin", "Madrid", "Paris", "Rome"], correctAnswerIndex: 2, category: "Geography", difficulty: "easy" },
    { question: "Which planet is known as the Red Planet?", options: ["Earth", "Mars", "Jupiter", "Saturn"], correctAnswerIndex: 1, category: "Science", difficulty: "easy" },
    { question: "What is 5 + 7?", options: ["10", "11", "12", "13"], correctAnswerIndex: 2, category: "Math", difficulty: "easy" },
    { question: "What is 56 / 4?", options: ["12", "13", "14", "15"], correctAnswerIndex: 2, category: "Math", difficulty: "medium" },
    { question: "What is the capital of Canada?", options: ["Toronto", "Ottawa", "Vancouver", "Montreal"], correctAnswerIndex: 1, category: "Geography", difficulty: "easy" },
    { question: "What is the largest mammal?", options: ["Elephant", "Blue Whale", "Giraffe", "Shark"], correctAnswerIndex: 1, category: "Science", difficulty: "easy" },
    { question: "How many sides does a hexagon have?", options: ["5", "6", "7", "8"], correctAnswerIndex: 1, category: "Math", difficulty: "easy" },
    { question: "What language is used for iOS development?", options: ["Java", "Kotlin", "Swift", "Python"], correctAnswerIndex: 2, category: "Technology", difficulty: "easy" },
    { question: "What is the capital of Japan?", options: ["Beijing", "Seoul", "Bangkok", "Tokyo"], correctAnswerIndex: 3, category: "Geography", difficulty: "easy" },
    { question: "How many planets are in the solar system?", options: ["7", "8", "9", "10"], correctAnswerIndex: 1, category: "Science", difficulty: "easy" }
];

async function seed() {
    await mongoose.connect(process.env.MONGODB_URI);
    await Question.deleteMany({});
    await Question.insertMany(questions);
    console.log(`Seeded ${questions.length} questions successfully`);
    await mongoose.disconnect();
}

seed().catch(console.error);