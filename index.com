
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>远程象棋 - 与姥爷对弈</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: "Microsoft YaHei", "SimSun", sans-serif;
            background: linear-gradient(135deg, #f5f5dc 0%, #e8dcc0 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        
        h1 {
            color: #8b4513;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.1em;
        }
        
        .game-container {
            display: flex;
            gap: 30px;
            align-items: flex-start;
            flex-wrap: wrap;
            justify-content: center;
        }
        
        .board-wrapper {
            position: relative;
            background: #f0d9b5;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            border: 3px solid #8b4513;
        }
        
        .board {
            width: 450px;
            height: 500px;
            position: relative;
            background: #f0d9b5;
        }
        
        .board-lines {
            position: absolute;
            width: 100%;
            height: 100%;
        }
        
        /* 绘制棋盘线 */
        .horizontal-lines {
            position: absolute;
            width: 100%;
            height: 100%;
        }
        
        .horizontal-line {
            position: absolute;
            width: 100%;
            height: 1px;
            background: #333;
        }
        
        .vertical-lines {
            position: absolute;
            width: 100%;
            height: 100%;
        }
        
        .vertical-line {
            position: absolute;
            width: 1px;
            height: 100%;
            background: #333;
        }
        
        /* 九宫格斜线 */
        .palace-lines {
            position: absolute;
            width: 100%;
            height: 100%;
            pointer-events: none;
        }
        
        .palace-line {
            position: absolute;
            width: 141px;
            height: 1px;
            background: #333;
            transform-origin: left center;
        }
        
        .palace-line.top-left {
            top: 50px;
            left: 154px;
            transform: rotate(45deg);
        }
        
        .palace-line.top-right {
            top: 50px;
            right: 154px;
            transform: rotate(-45deg);
        }
        
        .palace-line.bottom-left {
            bottom: 50px;
            left: 154px;
            transform: rotate(-45deg);
        }
        
        .palace-line.bottom-right {
            bottom: 50px;
            right: 154px;
            transform: rotate(45deg);
        }
        
        /* 楚河汉界 */
        .river {
            position: absolute;
            top: 225px;
            left: 0;
            width: 100%;
            height: 50px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: #8b4513;
            font-weight: bold;
            letter-spacing: 20px;
        }
        
        /* 棋子 */
        .pieces-container {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        
        .piece {
            position: absolute;
            width: 44px;
            height: 44px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            user-select: none;
            z-index: 10;
        }
        
        .piece.red {
            background: radial-gradient(circle at 30% 30%, #ff6b6b, #cc0000);
            color: #ffeb3b;
            border: 2px solid #8b0000;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.5);
        }
        
        .piece.black {
            background: radial-gradient(circle at 30% 30%, #666, #000);
            color: #fff;
            border: 2px solid #333;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
        }
        
        .piece:hover {
            transform: scale(1.1);
            box-shadow: 0 0 15px rgba(255,215,0,0.8);
        }
        
        .piece.selected {
            box-shadow: 0 0 20px #ffd700, 0 0 40px #ffd700;
            animation: pulse 1s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1.1); }
            50% { transform: scale(1.2); }
        }
        
        .piece.last-move {
            border: 3px solid #00ff00;
        }
        
        /* 可移动位置标记 */
        .move-hint {
            position: absolute;
            width: 16px;
            height: 16px;
            background: rgba(0,255,0,0.6);
            border-radius: 50%;
            transform: translate(-50%, -50%);
            pointer-events: none;
            z-index: 5;
        }
        
        /* 控制面板 */
        .control-panel {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            width: 300px;
            border: 2px solid #8b4513;
        }
        
        .status-box {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #8b4513;
        }
        
        .status-title {
            font-weight: bold;
            color: #8b4513;
            margin-bottom: 8px;
        }
        
        .status-content {
            color: #333;
            line-height: 1.6;
        }
        
        .player-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 0.9em;
            font-weight: bold;
            margin-top: 5px;
        }
        
        .player-badge.red {
            background: #ffeb3b;
            color: #c62828;
        }
        
        .player-badge.black {
            background: #333;
            color: #fff;
        }
        
        .btn {
            width: 100%;
            padding: 12px;
            margin: 8px 0;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.3s;
            font-family: inherit;
        }
        
        .btn-primary {
            background: #8b4513;
            color: white;
        }
        
        .btn-primary:hover {
            background: #6b3410;
            transform: translateY(-2px);
        }
        
        .btn-secondary {
            background: #e0e0e0;
            color: #333;
        }
        
        .btn-secondary:hover {
            background: #d0d0d0;
        }
        
        .btn-danger {
            background: #c62828;
            color: white;
        }
        
        .btn-danger:hover {
            background: #a02020;
        }
        
        .moves-list {
            max-height: 200px;
            overflow-y: auto;
            background: #f9f9f9;
            padding: 10px;
            border-radius: 6px;
            margin-top: 15px;
            font-size: 0.9em;
        }
        
        .move-item {
            padding: 4px 0;
            border-bottom: 1px solid #eee;
            color: #555;
        }
        
        .connection-status {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 0.85em;
            margin-top: 10px;
        }
        
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #ccc;
        }
        
        .status-dot.connected {
            background: #4caf50;
            animation: blink 2s infinite;
        }
        
        .status-dot.syncing {
            background: #ff9800;
            animation: blink 0.5s infinite;
        }
        
        @keyframes blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        .toast {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: #333;
            color: white;
            padding: 12px 24px;
            border-radius: 25px;
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.3s;
            pointer-events: none;
        }
        
        .toast.show {
            opacity: 1;
        }
        
        @media (max-width: 800px) {
            .board {
                width: 360px;
                height: 400px;
            }
            .piece {
                width: 36px;
                height: 36px;
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏮 远程象棋 🏮</h1>
        <p class="subtitle">与姥爷隔空对弈，跨越万里的亲情</p>
    </div>
    
    <div class="game-container">
        <div class="board-wrapper">
            <div class="board" id="board">
                <div class="board-lines">
                    <!-- 横线 -->
                    <div class="horizontal-lines" id="hLines"></div>
                    <!-- 竖线 -->
                    <div class="vertical-lines" id="vLines"></div>
                    <!-- 九宫格 -->
                    <div class="palace-lines">
                        <div class="palace-line top-left"></div>
                        <div class="palace-line top-right"></div>
                        <div class="palace-line bottom-left"></div>
                        <div class="palace-line bottom-right"></div>
                    </div>
                </div>
                <div class="river">楚 河 汉 界</div>
                <div class="pieces-container" id="piecesContainer"></div>
            </div>
        </div>
        
        <div class="control-panel">
            <div class="status-box">
                <div class="status-title">🎮 游戏状态</div>
                <div class="status-content">
                    <div>当前回合: <span id="currentTurn">红方</span></div>
                    <div>你是: <span id="playerRole" class="player-badge">等待加入...</span></div>
                    <div class="connection-status">
                        <span class="status-dot" id="statusDot"></span>
                        <span id="statusText">连接中...</span>
                    </div>
                </div>
            </div>
            
            <button class="btn btn-secondary" onclick="copyGameLink()">📋 复制对局链接</button>
            <button class="btn btn-secondary" onclick="requestUndo()">↩️ 请求悔棋</button>
            <button class="btn btn-danger" onclick="resign()">🏳️ 认输</button>
            <button class="btn btn-primary" onclick="resetGame()">🔄 重新开始</button>
            
            <div class="moves-list" id="movesList">
                <div style="color:#999;text-align:center;">暂无走棋记录</div>
            </div>
        </div>
    </div>
    
    <div class="toast" id="toast"></div>

    <script>
        // ==================== 配置 ====================
        const GIST_ID = '932c2d47035c60f134c28cce0b08428e';
        const GIST_API = `https://api.github.com/gists/${GIST_ID}`;
        
        // ==================== 游戏状态 ====================
        let gameState = {
            board: [],
            turn: 'red',
            lastMove: null,
            moveCount: 0,
            timestamp: Date.now(),
            players: { red: null, black: null },
            status: 'waiting',
            moves: []
        };
        
        let myColor = null;
        let selectedPiece = null;
        let myPlayerId = localStorage.getItem('chess_player_id') || generateId();
        let syncInterval = null;
        let isSyncing = false;
        
        // 棋子中文名
        const pieceNames = {
            'R': '车', 'N': '马', 'B': '象', 'A': '士', 'K': '将', 'C': '炮', 'P': '兵',
            'r': '车', 'n': '马', 'b': '相', 'a': '仕', 'k': '帅', 'c': '炮', 'p': '卒'
        };
        
        // ==================== 初始化 ====================
        function init() {
            localStorage.setItem('chess_player_id', myPlayerId);
            drawBoard();
            loadGame();
            startSync();
            showToast('欢迎来到远程象棋！');
        }
        
        function generateId() {
            return 'player_' + Math.random().toString(36).substr(2, 9);
        }
        
        // ==================== 绘制棋盘 ====================
        function drawBoard() {
            const hLines = document.getElementById('hLines');
            const vLines = document.getElementById('vLines');
            
            // 绘制横线 (10条)
            for (let i = 0; i < 10; i++) {
                const line = document.createElement('div');
                line.className = 'horizontal-line';
                line.style.top = `${i * 50 + 25}px`;
                hLines.appendChild(line);
            }
            
            // 绘制竖线 (9条)
            for (let i = 0; i < 9; i++) {
                const line = document.createElement('div');
                line.className = 'vertical-line';
                line.style.left = `${i * 50 + 25}px`;
                // 中间断开 (楚河汉界)
                if (i === 0 || i === 8) {
                    line.style.height = '100%';
                } else {
                    line.style.height = '200px';
                    line.style.top = '25px';
                    
                    const line2 = document.createElement('div');
                    line2.className = 'vertical-line';
                    line2.style.left = `${i * 50 + 25}px`;
                    line2.style.height = '200px';
                    line2.style.top = '275px';
                    vLines.appendChild(line2);
                }
                vLines.appendChild(line);
            }
        }
        
        // ==================== 棋子操作 ====================
        function renderPieces() {
            const container = document.getElementById('piecesContainer');
            container.innerHTML = '';
            
            if (!gameState.board || gameState.board.length === 0) return;
            
            for (let row = 0; row < 10; row++) {
                for (let col = 0; col < 9; col++) {
                    const piece = gameState.board[row][col];
                    if (piece && piece !== '.') {
                        const el = document.createElement('div');
                        el.className = `piece ${piece === piece.toUpperCase() ? 'black' : 'red'}`;
                        el.textContent = pieceNames[piece];
                        el.style.left = `${col * 50 + 3}px`;
                        el.style.top = `${row * 50 + 3}px`;
                        
                        if (selectedPiece && selectedPiece.row === row && selectedPiece.col === col) {
                            el.classList.add('selected');
                        }
                        
                        if (gameState.lastMove) {
                            const [from, to] = [gameState.lastMove.from, gameState.lastMove.to];
                            if ((row === from.row && col === from.col) || 
                                (row === to.row && col === to.col)) {
                                el.classList.add('last-move');
                            }
                        }
                        
                        el.onclick = () => onPieceClick(row, col);
                        container.appendChild(el);
                    }
                }
            }
            
            // 显示可移动位置
            if (selectedPiece) {
                showMoveHints(selectedPiece.row, selectedPiece.col);
            }
        }
        
        function showMoveHints(row, col) {
            const container = document.getElementById('piecesContainer');
            const piece = gameState.board[row][col];
            if (!piece || piece === '.') return;
            
            const isRed = piece === piece.toLowerCase();
            if ((isRed && myColor !== 'red') || (!isRed && myColor !== 'black')) return;
            if ((isRed && gameState.turn !== 'red') || (!isRed && gameState.turn !== 'black')) return;
            
            for (let r = 0; r < 10; r++) {
                for (let c = 0; c < 9; c++) {
                    if (isValidMove(row, col, r, c)) {
                        const hint = document.createElement('div');
                        hint.className = 'move-hint';
                        hint.style.left = `${c * 50 + 25}px`;
                        hint.style.top = `${r * 50 + 25}px`;
                        hint.onclick = () => onHintClick(r, c);
                        container.appendChild(hint);
                    }
                }
            }
        }
        
        function onPieceClick(row, col) {
            const piece = gameState.board[row][col];
            if (!piece || piece === '.') return;
            
            const isRed = piece === piece.toLowerCase();
            
            // 检查是否轮到自己
            if (myColor === null) return;
            if ((isRed && myColor !== 'red') || (!isRed && myColor !== 'black')) {
                showToast('这是对方的棋子！');
                return;
            }
            if ((isRed && gameState.turn !== 'red') || (!isRed && gameState.turn !== 'black')) {
                showToast('还没轮到你！');
                return;
            }
            
            if (selectedPiece && selectedPiece.row === row && selectedPiece.col === col) {
                selectedPiece = null;
            } else {
                selectedPiece = { row, col, piece };
            }
            renderPieces();
        }
        
        function onHintClick(row, col) {
            if (!selectedPiece) return;
            makeMove(selectedPiece.row, selectedPiece.col, row, col);
            selectedPiece = null;
        }
        
        // ==================== 走棋逻辑 ====================
        function isValidMove(fromRow, fromCol, toRow, toCol) {
            if (toRow < 0 || toRow > 9 || toCol < 0 || toCol > 8) return false;
            if (fromRow === toRow && fromCol === toCol) return false;
            
            const piece = gameState.board[fromRow][fromCol];
            const target = gameState.board[toRow][toCol];
            
            if (target !== '.' && target !== '') {
                const isRedPiece = piece === piece.toLowerCase();
                const isRedTarget = target === target.toLowerCase();
                if (isRedPiece === isRedTarget) return false;
            }
            
            const type = piece.toUpperCase();
            const isRed = piece === piece.toLowerCase();
            
            switch(type) {
                case 'R': // 车
                    return validateRook(fromRow, fromCol, toRow, toCol);
                case 'N': // 马
                    return validateKnight(fromRow, fromCol, toRow, toCol);
                case 'B': // 象/相
                    return validateBishop(fromRow, fromCol, toRow, toCol, isRed);
                case 'A': // 士/仕
                    return validateAdvisor(fromRow, fromCol, toRow, toCol, isRed);
                case 'K': // 将/帅
                    return validateKing(fromRow, fromCol, toRow, toCol, isRed);
                case 'C': // 炮
                    return validateCannon(fromRow, fromCol, toRow, toCol);
                case 'P': // 兵/卒
                    return validatePawn(fromRow, fromCol, toRow, toCol, isRed);
                default:
                    return false;
            }
        }
        
        function countPiecesBetween(r1, c1, r2, c2) {
            let count = 0;
            if (r1 === r2) {
                const min = Math.min(c1, c2);
                const max = Math.max(c1, c2);
                for (let c = min + 1; c < max; c++) {
                    if (gameState.board[r1][c] !== '.' && gameState.board[r1][c] !== '') count++;
                }
            } else if (c1 === c2) {
                const min = Math.min(r1, r2);
                const max = Math.max(r1, r2);
                for (let r = min + 1; r < max; r++) {
                    if (gameState.board[r][c1] !== '.' && gameState.board[r][c1] !== '') count++;
                }
            }
            return count;
        }
        
        function validateRook(r1, c1, r2, c2) {
            if (r1 !== r2 && c1 !== c2) return false;
            return countPiecesBetween(r1, c1, r2, c2) === 0;
        }
        
        function validateKnight(r1, c1, r2, c2) {
            const dr = Math.abs(r2 - r1);
            const dc = Math.abs(c2 - c1);
            if (!((dr === 2 && dc === 1) || (dr === 1 && dc === 2))) return false;
            
            // 检查绊马腿
            if (dr === 2) {
                const blockR = r1 + (r2 > r1 ? 1 : -1);
                if (gameState.board[blockR][c1] !== '.' && gameState.board[blockR][c1] !== '') return false;
            } else {
                const blockC = c1 + (c2 > c1 ? 1 : -1);
                if (gameState.board[r1][blockC] !== '.' && gameState.board[r1][blockC] !== '') return false;
            }
            return true;
        }
        
        function validateBishop(r1, c1, r2, c2, isRed) {
            const dr = Math.abs(r2 - r1);
            const dc = Math.abs(c2 - c1);
            if (dr !== 2 || dc !== 2) return false;
            
            // 不能过河
            if (isRed && r2 < 5) return false;
            if (!isRed && r2 > 4) return false;
            
            // 检查象眼
            const eyeR = (r1 + r2) / 2;
            const eyeC = (c1 + c2) / 2;
            if (gameState.board[eyeR][eyeC] !== '.' && gameState.board[eyeR][eyeC] !== '') return false;
            
            return true;
        }
        
        function validateAdvisor(r1, c1, r2, c2, isRed) {
            const dr = Math.abs(r2 - r1);
            const dc = Math.abs(c2 - c1);
            if (dr !== 1 || dc !== 1) return false;
            
            // 限制在九宫格内
            if (c2 < 3 || c2 > 5) return false;
            if (isRed && r2 < 7) return false;
            if (!isRed && r2 > 2) return false;
            
            return true;
        }
        
        function validateKing(r1, c1, r2, c2, isRed) {
            const dr = Math.abs(r2 - r1);
            const dc = Math.abs(c2 - c1);
            
            // 将帅对面
            if (c1 === c2) {
                let hasPiece = false;
                const min = Math.min(r1, r2);
                const max = Math.max(r1, r2);
                for (let r = min + 1; r < max; r++) {
                    if (gameState.board[r][c1] !== '.' && gameState.board[r][c1] !== '') {
                        hasPiece = true;
                        break;
                    }
                }
                if (!hasPiece) {
                    const target = gameState.board[r2][c2];
                    if (target && (target.toUpperCase() === 'K')) return true;
                }
            }
            
            if (dr + dc !== 1) return false;
            
            // 限制在九宫格内
            if (c2 < 3 || c2 > 5) return false;
            if (isRed && r2 < 7) return false;
            if (!isRed && r2 > 2) return false;
            
            return true;
        }
        
        function validateCannon(r1, c1, r2, c2) {
            if (r1 !== r2 && c1 !== c2) return false;
            
            const count = countPiecesBetween(r1, c1, r2, c2);
            const target = gameState.board[r2][c2];
            
            if (target === '.' || target === '') {
                return count === 0;
            } else {
                return count === 1;
            }
        }
        
        function validatePawn(r1, c1, r2, c2, isRed) {
            const dr = r2 - r1;
            const dc = Math.abs(c2 - c1);
            
            if (isRed) {
                if (dr > 0) return false;
                if (r1 >= 5 && dc !== 0) return false;
                if (dr === -1 && dc === 0) return true;
                if (r1 < 5 && dr === 0 && dc === 1) return true;
            } else {
                if (dr < 0) return false;
                if (r1 <= 4 && dc !== 0) return false;
                if (dr === 1 && dc === 0) return true;
                if (r1 > 4 && dr === 0 && dc === 1) return true;
            }
            return false;
        }
        
        // ==================== 游戏操作 ====================
        async function makeMove(fromRow, fromCol, toRow, toCol) {
            const piece = gameState.board[fromRow][fromCol];
            const target = gameState.board[toRow][toCol];
            
            // 更新棋盘
            gameState.board[toRow][toCol] = piece;
            gameState.board[fromRow][fromCol] = '.';
            
            // 记录移动
            const moveNotation = `${pieceNames[piece]} ${String.fromCharCode(97 + fromCol)}${9-fromRow} → ${String.fromCharCode(97 + toCol)}${9-toRow}`;
            gameState.moves.push(moveNotation);
            
            gameState.lastMove = { from: { row: fromRow, col: fromCol }, to: { row: toRow, col: toCol } };
            gameState.turn = gameState.turn === 'red' ? 'black' : 'red';
            gameState.moveCount++;
            gameState.timestamp = Date.now();
            
            // 检查是否吃掉老将/帅
            if (target && target.toUpperCase() === 'K') {
                const winner = gameState.turn === 'red' ? '黑方' : '红方';
                showToast(`🎉 ${winner}获胜！`);
                gameState.status = 'finished';
            }
            
            renderPieces();
            updateUI();
            await saveGame();
        }
        
        function updateUI() {
            document.getElementById('currentTurn').textContent = gameState.turn === 'red' ? '红方' : '黑方';
            document.getElementById('currentTurn').style.color = gameState.turn === 'red' ? '#c62828' : '#333';
            
            const movesList = document.getElementById('movesList');
            if (gameState.moves.length === 0) {
                movesList.innerHTML = '<div style="color:#999;text-align:center;">暂无走棋记录</div>';
            } else {
                movesList.innerHTML = gameState.moves.map((m, i) => 
                    `<div class="move-item">${Math.floor(i/2)+1}. ${m}</div>`
                ).join('');
                movesList.scrollTop = movesList.scrollHeight;
            }
        }
        
        // ==================== 数据同步 ====================
        async function loadGame() {
            try {
                const response = await fetch(GIST_API);
                if (!response.ok) throw new Error('Failed to load');
                
                const gist = await response.json();
                const content = gist.files['chess-game.json'].content;
                const data = JSON.parse(content);
                
                // 检查是否需要更新本地状态
                if (data.timestamp > gameState.timestamp) {
                    gameState = data;
                    determinePlayerColor();
                    renderPieces();
                    updateUI();
                    showToast('同步成功！');
                }
                
                updateConnectionStatus(true);
            } catch (err) {
                console.error('Load error:', err);
                updateConnectionStatus(false);
                // 如果加载失败，初始化新游戏
                if (gameState.board.length === 0) {
                    initBoard();
                }
            }
        }
        
        async function saveGame() {
            if (isSyncing) return;
            isSyncing = true;
            updateConnectionStatus(true, true);
            
            try {
                const response = await fetch(GIST_API, {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/vnd.github.v3+json'
                    },
                    body: JSON.stringify({
                        files: {
                            'chess-game.json': {
                                content: JSON.stringify(gameState, null, 2)
                            }
                        }
                    })
                });
                
                if (!response.ok) throw new Error('Failed to save');
                
                updateConnectionStatus(true);
            } catch (err) {
                console.error('Save error:', err);
                showToast('保存失败，请检查网络');
                updateConnectionStatus(false);
            } finally {
                isSyncing = false;
            }
        }
        
        function startSync() {
            syncInterval = setInterval(loadGame, 3000); // 每3秒同步一次
        }
        
        function determinePlayerColor() {
            if (myColor) return;
            
            if (!gameState.players.red) {
                gameState.players.red = myPlayerId;
                myColor = 'red';
                showToast('你是红方！');
            } else if (!gameState.players.black && gameState.players.red !== myPlayerId) {
                gameState.players.black = myPlayerId;
                myColor = 'black';
                showToast('你是黑方！');
            } else if (gameState.players.red === myPlayerId) {
                myColor = 'red';
            } else if (gameState.players.black === myPlayerId) {
                myColor = 'black';
            }
            
            if (myColor) {
                const badge = document.getElementById('playerRole');
                badge.textContent = myColor === 'red' ? '红方' : '黑方';
                badge.className = `player-badge ${myColor}`;
            }
        }
        
        function updateConnectionStatus(connected, syncing = false) {
            const dot = document.getElementById('statusDot');
            const text = document.getElementById('statusText');
            
            if (syncing) {
                dot.className = 'status-dot syncing';
                text.textContent = '同步中...';
            } else if (connected) {
                dot.className = 'status-dot connected';
                text.textContent = '已连接';
            } else {
                dot.className = 'status-dot';
                text.textContent = '未连接';
            }
        }
        
        // ==================== 初始化棋盘 ====================
        function initBoard() {
            gameState.board = [
                ['R','N','B','A','K','A','B','N','R'],
                ['.','.','.','.','.','.','.','.','.'],
                ['.','C','.','.','.','.','.','C','.'],
                ['P','.','P','.','P','.','P','.','P'],
                ['.','.','.','.','.','.','.','.','.'],
                ['.','.','.','.','.','.','.','.','.'],
                ['p','.','p','.','p','.','p','.','p'],
                ['.','c','.','.','.','.','.','c','.'],
                ['.','.','.','.','.','.','.','.','.'],
                ['r','n','b','a','k','a','b','n','r']
            ];
            gameState.turn = 'red';
            gameState.lastMove = null;
            gameState.moveCount = 0;
            gameState.moves = [];
            gameState.status = 'playing';
            gameState.timestamp = Date.now();
            
            determinePlayerColor();
            renderPieces();
            updateUI();
        }
        
        // ==================== 按钮功能 ====================
        function copyGameLink() {
            const url = window.location.href;
            navigator.clipboard.writeText(url).then(() => {
                showToast('链接已复制，分享给姥爷吧！');
            });
        }
        
        function requestUndo() {
            showToast('悔棋请求已发送（功能开发中）');
        }
        
        function resign() {
            if (confirm('确定要认输吗？')) {
                const winner = myColor === 'red' ? '黑方' : '红方';
                showToast(`你认输了，${winner}获胜！`);
                gameState.status = 'finished';
                saveGame();
            }
        }
        
        async function resetGame() {
            if (!confirm('确定要重新开始吗？')) return;
            
            gameState.players = { red: null, black: null };
            myColor = null;
            initBoard();
            await saveGame();
            showToast('新游戏已开始！');
        }
        
        function showToast(msg) {
            const toast = document.getElementById('toast');
            toast.textContent = msg;
            toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), 3000);
        }
        
        // ==================== 启动 ====================
        window.onload = init;
    </script>
</body>
</html>'''

# 保存文件
with open('/mnt/kimi/output/index.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

print("✅ 文件已保存到 /mnt/kimi/output/index.html")
print(f"文件大小: {len(html_content)} 字符")
