// script just to test how server behaves when 9 players try to join while quiz capped at max 8 players

const { io } = require("socket.io-client");

const SERVER = "http://localhost:3000";
const PLAYER_COUNT = 9;

async function sleep(ms) {
    return new Promise(r => setTimeout(r, ms));
}

async function createPlayer(name, index) {
    const socket = io(SERVER, { forceNew: true });

    socket.on("connect", () => {
        console.log(`[${name}] connected`);
        socket.emit("joinGame", { username: name });
    });

    socket.on("joinError", (data) => {
        console.log(`[${name}] JOIN ERROR: ${data.message}`);
        socket.disconnect();
    });

    socket.on("gameJoined", (data) => {
        console.log(`[${name}] joined game ${data.gameId}`);
    });

    socket.on("playerListUpdated", (data) => {
        console.log(`[${name}] lobby: ${data.count} players`);
    });

    socket.on("question", (data) => {
        console.log(`[${name}] got question: ${data.question}`);
        const answerDelay = 1000 + Math.random() * 3000;
        setTimeout(() => {
            const randomAnswer = Math.floor(Math.random() * data.options.length);
            socket.emit("submitAnswer", {
                gameId: socket._gameId,
                questionId: data.questionId,
                selectedIndex: randomAnswer,
                username: name
            });
            console.log(`[${name}] answered index ${randomAnswer}`);
        }, answerDelay);
    });

    socket.on("gameJoined", (data) => {
        socket._gameId = data.gameId;
    });

    socket.on("answerResult", (data) => {
        console.log(`[${name}] result: ${data.isCorrect ? "CORRECT" : "WRONG"} (correct was ${data.correctIndex})`);
    });

    socket.on("gameEnded", (data) => {
        console.log(`[${name}] GAME ENDED`);
        console.log("Leaderboard:", data.leaderboard.map(p => `${p.username}: ${p.score}`).join(", "));
        socket.disconnect();
    });

    socket.on("lobbyCountdown", (data) => {
        if (data.seconds === 5) {
            console.log(`[${name}] game starting in ${data.seconds}s`);
        }
    });
}

async function runTest() {
    console.log(`Starting load test with ${PLAYER_COUNT} players...`);
    for (let i = 0; i < PLAYER_COUNT; i++) {
        await createPlayer(`Player${i + 1}`, i);
        await sleep(300);
    }
}

runTest();