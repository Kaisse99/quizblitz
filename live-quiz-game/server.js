require('dotenv').config();

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

const quizService = require('./services/quizService');
const User = require('./models/User');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log("MongoDB Connected"))
    .catch(err => console.error(err));

app.get('/stats/:username', async (req, res) => {
    try {
        const user = await User.findOne({ username: req.params.username });
        if (!user) return res.status(404).json({ error: 'User not found' });
        res.json({
            username: user.username,
            totalScore: user.totalScore,
            gamesPlayed: user.gamesPlayed,
            averageScore: user.gamesPlayed > 0
                ? (user.totalScore / user.gamesPlayed).toFixed(2)
                : 0,
            memberSince: user.createdAt
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/leaderboard', async (req, res) => {
    try {
        const users = await User.find()
            .sort({ totalScore: -1 })
            .limit(10)
            .select('username totalScore gamesPlayed');
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

    socket.on('joinGame', async ({ username }) => {
        try {
            const previousRooms = Array.from(socket.rooms).filter(r => r !== socket.id);
            for (const room of previousRooms) {
                socket.leave(room);
            }

            if (!quizService.activeGame) {
                await quizService.createGame();
            }

            const result = await quizService.addPlayer(username, io, socket);

            if (result.error) {
                socket.emit('joinError', { message: result.error });
                return;
            }

            socket.emit('gameJoined', {
                gameId: quizService.activeGame?.gameId,
                waitingTime: 8,
                currentPlayers: quizService.activeGame?.players.length,
                maxPlayers: quizService.maxPlayers
            });

            console.log(`${username} joined. Players: ${quizService.activeGame?.players.length}/${quizService.maxPlayers}`);
        } catch (err) {
            console.error('joinGame error:', err);
            socket.emit('joinError', { message: 'Failed to join game.' });
        }
    });

    socket.on('startGame', () => {
        try {
            quizService.startGame(io);
        } catch (err) {
            console.error('startGame error:', err);
        }
    });

    socket.on('submitAnswer', async (data) => {
        try {
            await quizService.submitAnswer(io, socket, data);
        } catch (err) {
            console.error('submitAnswer error:', err);
        }
    });

    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

server.listen(3000, () => {
    console.log("Server running on http://localhost:3000");
});