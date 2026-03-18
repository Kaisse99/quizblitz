const { v4: uuidv4 } = require('uuid');
const Question = require('../models/Question');
const GameSession = require('../models/GameSession');
const Answer = require('../models/Answer');
const User = require('../models/User');

let activeGame = null;
let currentQuestionIndex = 0;
let questions = [];
let timer = null;
let waitingTimer = null;
let waitingCountdownTimer = null;
let nextQuestionTimer = null;
let submittedThisRound = new Set();

const QUESTION_TIME = 10;
const WAITING_TIME = 8;
const MAX_PLAYERS = 8;

function roomcast(io, event, data) {
    if (!activeGame) return;
    io.to(activeGame.gameId).emit(event, data);
}

function scheduleNextQuestion(io, delay) {
    if (nextQuestionTimer !== null) return;
    nextQuestionTimer = setTimeout(() => {
        nextQuestionTimer = null;
        currentQuestionIndex++;
        sendQuestion(io);
    }, delay);
}

async function createGame() {
    if (nextQuestionTimer) { clearTimeout(nextQuestionTimer); nextQuestionTimer = null; }
    if (timer) { clearInterval(timer); timer = null; }
    if (waitingTimer) { clearTimeout(waitingTimer); waitingTimer = null; }
    if (waitingCountdownTimer) { clearInterval(waitingCountdownTimer); waitingCountdownTimer = null; }

    submittedThisRound.clear();

    const gameId = uuidv4();
    activeGame = new GameSession({
        gameId,
        players: [],
        startedAt: new Date(),
        status: 'waiting'
    });
    await activeGame.save();
    questions = await Question.aggregate([{ $sample: { size: 5 } }]);
    currentQuestionIndex = 0;
    return activeGame;
}

function startLobbyCountdown(io) {
    if (waitingTimer) clearTimeout(waitingTimer);
    if (waitingCountdownTimer) clearInterval(waitingCountdownTimer);

    let countdown = WAITING_TIME;
    roomcast(io, 'lobbyCountdown', { seconds: countdown });

    waitingCountdownTimer = setInterval(() => {
        countdown--;
        roomcast(io, 'lobbyCountdown', { seconds: countdown });
        if (countdown <= 0) {
            clearInterval(waitingCountdownTimer);
            waitingCountdownTimer = null;
        }
    }, 1000);

    waitingTimer = setTimeout(() => {
        if (activeGame && activeGame.status === 'waiting' && activeGame.players.length > 0) {
            startGame(io);
        }
    }, WAITING_TIME * 1000);
}

async function addPlayer(username, io, socket) {
    if (activeGame && activeGame.status === 'active') {
        return { error: 'Game already in progress. Please wait for the next game.' };
    }

    if (activeGame && activeGame.players.length >= MAX_PLAYERS) {
        return { error: `This game is full. Maximum ${MAX_PLAYERS} players allowed.` };
    }

    let user = await User.findOne({ username });
    if (!user) {
        user = new User({ username });
        await user.save();
    }

    const alreadyIn = activeGame.players.find(p => p.username === username);

    if (alreadyIn) {
        return { error: 'This username is already taken in the current game. Please choose a different name.' };
    }

    activeGame.players.push({ userId: user._id, username: user.username, score: 0 });
    await activeGame.save();

    socket.join(activeGame.gameId);

    const playerCount = activeGame.players.length;
    const isFull = playerCount >= MAX_PLAYERS;

    roomcast(io, 'playerListUpdated', {
        players: activeGame.players.map(p => ({ username: p.username, score: p.score })),
        count: playerCount,
        maxPlayers: MAX_PLAYERS,
        isFull
    });

    if (isFull) {
        if (waitingTimer) { clearTimeout(waitingTimer); waitingTimer = null; }
        if (waitingCountdownTimer) { clearInterval(waitingCountdownTimer); waitingCountdownTimer = null; }
        roomcast(io, 'lobbyCountdown', { seconds: 0 });
        setTimeout(() => startGame(io), 500);
    } else {
        startLobbyCountdown(io);
    }

    return { user };
}

function startGame(io) {
    if (!activeGame || activeGame.status === 'active') return;
    if (waitingTimer) { clearTimeout(waitingTimer); waitingTimer = null; }
    if (waitingCountdownTimer) { clearInterval(waitingCountdownTimer); waitingCountdownTimer = null; }
    submittedThisRound.clear();
    activeGame.status = 'active';
    activeGame.save();
    sendQuestion(io);
}

function sendQuestion(io) {
    if (currentQuestionIndex >= questions.length) {
        endGame(io);
        return;
    }

    submittedThisRound.clear();

    roomcast(io, 'answeredCount', {
        answeredCount: 0,
        totalCount: activeGame.players.length
    });

    const q = questions[currentQuestionIndex];
    roomcast(io, 'question', {
        questionId: q._id,
        question: q.question,
        options: q.options,
        questionNumber: currentQuestionIndex + 1,
        totalQuestions: questions.length
    });

    startTimer(io);
}

function startTimer(io) {
    if (timer) clearInterval(timer);

    let timeLeft = QUESTION_TIME;
    roomcast(io, 'timer', { timeLeft });

    timer = setInterval(() => {
        timeLeft--;
        roomcast(io, 'timer', { timeLeft });
        if (timeLeft <= 0) {
            clearInterval(timer);
            timer = null;
            scheduleNextQuestion(io, 800);
        }
    }, 1000);
}

async function submitAnswer(io, socket, data) {
    const { gameId, questionId, selectedIndex, username } = data;

    if (!activeGame || activeGame.status !== 'active') return;
    if (activeGame.gameId !== gameId) return;
    if (submittedThisRound.has(username)) return;

    submittedThisRound.add(username);

    const question = questions.find(q => q._id.toString() === questionId);
    if (!question) return;

    const isCorrect = selectedIndex === question.correctAnswerIndex;
    const player = activeGame.players.find(p => p.username === username);

    if (isCorrect && player) player.score += 1;

    await Answer.create({
        gameId,
        userId: player?.userId,
        questionId,
        selectedAnswer: selectedIndex,
        isCorrect
    });

    await activeGame.save();

    roomcast(io, 'answeredCount', {
        answeredCount: submittedThisRound.size,
        totalCount: activeGame.players.length
    });

    socket.emit('answerResult', {
        questionId,
        correctIndex: question.correctAnswerIndex,
        isCorrect
    });

    if (submittedThisRound.size >= activeGame.players.length) {
        clearInterval(timer);
        timer = null;
        scheduleNextQuestion(io, 3000);
    }
}

async function endGame(io) {
    if (!activeGame) return;
    if (nextQuestionTimer) { clearTimeout(nextQuestionTimer); nextQuestionTimer = null; }

    activeGame.status = 'completed';
    activeGame.endedAt = new Date();
    await activeGame.save();

    for (const player of activeGame.players) {
        await User.findByIdAndUpdate(player.userId, {
            $inc: { totalScore: player.score, gamesPlayed: 1 }
        });
    }

    roomcast(io, 'gameEnded', {
        leaderboard: activeGame.players
            .sort((a, b) => b.score - a.score)
            .map(p => ({ username: p.username, score: p.score }))
    });

    activeGame = null;
    currentQuestionIndex = 0;
    submittedThisRound.clear();
}

module.exports = {
    createGame,
    addPlayer,
    startGame,
    submitAnswer,
    maxPlayers: MAX_PLAYERS,
    get activeGame() { return activeGame; }
};