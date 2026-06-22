const String webClientHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bit The Player - Network Auction</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800;900&display=swap" rel="stylesheet">
    <style>
        :root {
            --background: #0A0E1A;
            --surface: #151D30;
            --surface-light: #1E293B;
            --primary: #10B981;
            --primary-glow: rgba(16, 185, 129, 0.3);
            --secondary: #6366F1;
            --secondary-glow: rgba(99, 102, 241, 0.3);
            --accent: #06B6D4;
            --text-primary: #F8FAFC;
            --text-secondary: #94A3B8;
            --text-muted: #64748B;
            --gold: #F59E0B;
            --error: #EF4444;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', -apple-system, sans-serif;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background-color: var(--background);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow-x: hidden;
            background-image: radial-gradient(circle at 50% 10%, #1E1B4B 0%, #0A0E1A 70%);
        }

        .container {
            width: 100%;
            max-width: 480px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            padding: 24px;
            position: relative;
        }

        /* Glassmorphism Card Style */
        .glass-card {
            background: rgba(30, 41, 59, 0.3);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
        }

        /* Screens */
        .screen {
            display: none;
            flex-direction: column;
            flex-grow: 1;
            animation: fadeIn 0.4s ease-out forwards;
        }

        .screen.active {
            display: flex;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Logo / Header */
        .logo-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 40px 0 30px;
        }

        .logo-icon {
            font-size: 60px;
            margin-bottom: 12px;
            filter: drop-shadow(0 0 15px var(--primary));
            animation: pulseIcon 3s infinite ease-in-out;
        }

        @keyframes pulseIcon {
            0%, 100% { transform: scale(1); filter: drop-shadow(0 0 10px var(--primary)); }
            50% { transform: scale(1.08); filter: drop-shadow(0 0 25px var(--primary)); }
        }

        h1 {
            font-size: 30px;
            font-weight: 900;
            letter-spacing: 2px;
            background: linear-gradient(to right, var(--primary), var(--accent));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 4px;
        }

        .subtitle {
            color: var(--text-muted);
            font-size: 13px;
        }

        /* Inputs & Buttons */
        .label {
            color: var(--primary);
            font-weight: 800;
            font-size: 11px;
            letter-spacing: 1.5px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }

        input {
            width: 100%;
            background: var(--surface-light);
            border: 1px solid rgba(148, 163, 184, 0.2);
            color: var(--text-primary);
            padding: 16px 20px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 600;
            outline: none;
            transition: border-color 0.2s, box-shadow 0.2s;
            margin-bottom: 20px;
        }

        input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px var(--primary-glow);
        }

        .btn {
            width: 100%;
            background: linear-gradient(135deg, var(--primary), var(--accent));
            border: none;
            color: white;
            padding: 16px 24px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 800;
            cursor: pointer;
            box-shadow: 0 4px 12px var(--primary-glow);
            transition: transform 0.1s active, filter 0.2s;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
        }

        .btn:active {
            transform: scale(0.98);
        }

        .btn-secondary {
            background: linear-gradient(135deg, var(--secondary), #EC4899);
            box-shadow: 0 4px 12px rgba(99, 102, 241, 0.2);
        }

        .btn:disabled {
            background: var(--text-muted);
            box-shadow: none;
            cursor: not-allowed;
            opacity: 0.5;
        }

        /* Lobby Player Item */
        .player-item {
            display: flex;
            align-items: center;
            background: rgba(30, 41, 59, 0.25);
            border: 1px solid rgba(148, 163, 184, 0.08);
            border-radius: 12px;
            padding: 14px 16px;
            margin-bottom: 10px;
        }

        .player-avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: var(--secondary);
            display: flex;
            justify-content: center;
            align-items: center;
            font-weight: 800;
            font-size: 14px;
            margin-right: 12px;
            color: white;
        }

        .player-name {
            font-weight: 600;
            font-size: 15px;
            flex-grow: 1;
        }

        .badge {
            background: var(--secondary);
            font-size: 9px;
            font-weight: 800;
            padding: 4px 8px;
            border-radius: 6px;
            letter-spacing: 0.5px;
        }

        /* Game Header */
        .game-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }

        .wallet-box {
            display: flex;
            flex-direction: column;
        }

        .wallet-label {
            color: var(--text-muted);
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 0.5px;
        }

        .wallet-value {
            color: var(--gold);
            font-size: 24px;
            font-weight: 900;
        }

        .lead-badge {
            padding: 8px 12px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 6px;
            border: 1.5px solid transparent;
        }

        .lead-badge.winning {
            background: rgba(16, 185, 129, 0.15);
            color: var(--primary);
            border-color: var(--primary);
        }

        .lead-badge.outbid {
            background: rgba(239, 68, 68, 0.15);
            color: var(--error);
            border-color: var(--error);
        }

        /* Footballer Card */
        .footballer-card {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 220px;
            position: relative;
            text-align: center;
            border: 1px solid rgba(148, 163, 184, 0.12);
            transition: border-color 0.3s;
        }

        .footballer-card.critical {
            border-color: rgba(239, 68, 68, 0.4);
        }

        .timer-badge {
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            color: var(--primary);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 900;
            font-family: monospace;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .timer-badge.critical {
            background: rgba(239, 68, 68, 0.1);
            border-color: rgba(239, 68, 68, 0.3);
            color: var(--error);
            animation: pulseTimer 1s infinite alternate;
        }

        @keyframes pulseTimer {
            from { transform: scale(1); }
            to { transform: scale(1.05); }
        }

        .footballer-icon {
            font-size: 50px;
            color: var(--text-muted);
            opacity: 0.3;
            margin-bottom: 12px;
        }

        .footballer-name {
            font-size: 26px;
            font-weight: 900;
            color: var(--text-primary);
            text-shadow: 0 2px 4px rgba(0,0,0,0.5);
        }

        /* Bid Panel */
        .bid-panel {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: rgba(21, 29, 48, 0.6);
            padding: 14px 20px;
            border-radius: 12px;
            margin-bottom: 16px;
        }

        .bid-info {
            display: flex;
            flex-direction: column;
        }

        .bid-val {
            color: var(--primary);
            font-size: 24px;
            font-weight: 900;
            text-shadow: 0 0 10px rgba(16, 185, 129, 0.3);
        }

        .bidder-name {
            font-size: 11px;
            font-weight: 800;
            color: var(--text-muted);
        }

        /* Quick Bids Grid */
        .quick-bids-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            margin-bottom: 14px;
        }

        .quick-bid-btn {
            background: var(--surface-light);
            border: 1px solid rgba(148, 163, 184, 0.1);
            color: var(--primary);
            font-weight: 800;
            padding: 12px 6px;
            border-radius: 10px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.2s;
        }

        .quick-bid-btn:disabled {
            color: var(--text-muted);
            opacity: 0.3;
            cursor: not-allowed;
        }

        .custom-bid-row {
            display: flex;
            gap: 12px;
        }

        .custom-bid-row input {
            margin-bottom: 0;
            flex-grow: 1;
        }

        .custom-bid-row .btn {
            width: auto;
            padding-left: 28px;
            padding-right: 28px;
        }

        /* Alert/Error Banner */
        .alert-banner {
            background: rgba(239, 68, 68, 0.15);
            border: 1px solid var(--error);
            color: var(--error);
            border-radius: 10px;
            padding: 10px 14px;
            font-size: 12px;
            font-weight: 700;
            text-align: center;
            margin-top: 10px;
            display: none;
            animation: shake 0.3s;
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-4px); }
            75% { transform: translateX(4px); }
        }

        /* Round Over Panel */
        .result-panel {
            background: rgba(99, 102, 241, 0.05);
            border: 1px solid rgba(99, 102, 241, 0.25);
            border-radius: 12px;
            padding: 18px;
            text-align: center;
            margin-top: 20px;
        }

        .result-panel.winner-me {
            background: rgba(16, 185, 129, 0.08);
            border-color: rgba(16, 185, 129, 0.3);
        }

        .result-title {
            font-weight: 800;
            font-size: 13px;
            letter-spacing: 1.5px;
            margin-bottom: 6px;
        }

        .result-desc {
            font-weight: 700;
            font-size: 15px;
        }

        /* Leaderboard table */
        .leaderboard-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
            margin-top: 20px;
            flex-grow: 1;
        }

        .board-item {
            padding: 16px;
            display: flex;
            flex-direction: column;
            background: rgba(30, 41, 59, 0.3);
            border-radius: 12px;
            border: 1px solid rgba(148, 163, 184, 0.08);
        }

        .board-item.self {
            border-color: rgba(16, 185, 129, 0.3);
            background: rgba(16, 185, 129, 0.04);
        }

        .board-row {
            display: flex;
            align-items: center;
        }

        .board-rank {
            font-weight: 900;
            font-size: 18px;
            width: 32px;
            display: flex;
            align-items: center;
        }

        .rank-gold { color: var(--gold); }
        .rank-silver { color: #C0C0C0; }
        .rank-bronze { color: #CD7F32; }

        .board-name {
            font-weight: 700;
            font-size: 15px;
            flex-grow: 1;
        }

        .board-score {
            text-align: right;
        }

        .board-count {
            color: var(--accent);
            font-weight: 800;
            font-size: 14px;
        }

        .board-wallet {
            color: var(--text-muted);
            font-size: 11px;
            font-weight: 600;
        }

        .board-tags {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: 10px;
        }

        .tag {
            background: rgba(99, 102, 241, 0.12);
            border: 1px solid rgba(99, 102, 241, 0.2);
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 10px;
            font-weight: 700;
            color: white;
        }

        /* Floating footer helper */
        .waiting-footer {
            margin-top: auto;
            text-align: center;
            padding: 16px;
            color: var(--text-muted);
            font-size: 13px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .spinner {
            width: 14px;
            height: 14px;
            border: 2px solid var(--text-muted);
            border-top-color: var(--primary);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* How to Play Modal Styles */
        .info-icon-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: var(--secondary);
            width: 38px;
            height: 38px;
            border-radius: 50%;
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
            z-index: 1000;
        }
        .info-icon-btn:hover {
            background: var(--primary);
            color: white;
            box-shadow: 0 0 15px var(--primary);
            border-color: var(--primary);
        }
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.85);
            backdrop-filter: blur(10px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        }
        .modal-content {
            max-width: 450px;
            width: 90%;
            padding: 24px;
            position: relative;
            animation: fadeIn 0.3s ease;
            text-align: left;
        }
        .close-btn {
            position: absolute;
            top: 16px;
            right: 16px;
            font-size: 24px;
            color: var(--text-muted);
            cursor: pointer;
            transition: color 0.2s;
        }
        .close-btn:hover {
            color: var(--error);
        }
        .help-section h3 {
            margin: 0 0 6px 0;
            font-size: 14px;
            color: var(--secondary);
            font-weight: 800;
        }
        .help-section p {
            margin: 0;
            font-size: 13px;
            color: var(--text-muted);
            line-height: 1.5;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }
    </style>
</head>
<body>
    <button id="leaderboard-btn" class="info-icon-btn" style="right: 70px;" onclick="toggleLeaderboardModal(true)">🏆</button>
    <button id="info-btn" class="info-icon-btn" onclick="toggleHelpModal(true)">ⓘ</button>

    <!-- Leaderboard Modal Overlay -->
    <div id="leaderboard-modal" class="modal-overlay" onclick="closeLeaderboardModal(event)">
        <div class="modal-content glass-card" style="max-width: 460px; max-height: 85vh; display: flex; flex-direction: column;">
            <span class="close-btn" onclick="toggleLeaderboardModal(false)">&times;</span>
            <h2 style="color: var(--primary); margin-top: 0; font-weight: 900; letter-spacing: 0.5px; margin-bottom: 16px;">🏆 STANDINGS</h2>
            <div id="leaderboard-modal-list" style="overflow-y: auto; flex-grow: 1; padding-right: 4px;">
                <!-- Dynamically filled -->
            </div>
        </div>
    </div>

    <!-- Help Modal Overlay -->
    <div id="help-modal" class="modal-overlay" onclick="closeHelpModal(event)">
        <div class="modal-content glass-card">
            <span class="close-btn" onclick="toggleHelpModal(false)">&times;</span>
            <h2 style="color: var(--primary); margin-top: 0; font-weight: 900; letter-spacing: 0.5px;">HOW TO PLAY</h2>
            <div class="help-section">
                <h3>🔨 The Auction</h3>
                <p>Bid on footballers using the quick increment buttons (+$5M, +$10M, etc.) or a custom bid. Bids must exceed the current highest offer and fit your budget.</p>
            </div>
            <div class="help-section" style="margin-top: 16px;">
                <h3>🛡️ Sniping Protection</h3>
                <p>If any bid is placed in the last <strong>5 seconds</strong> of a round, the timer is extended by <strong>3 seconds</strong> to give others a chance to react.</p>
            </div>
            <div class="help-section" style="margin-top: 16px;">
                <h3>🔄 Position Alternation</h3>
                <p>Footballer positions alternate round-by-round (<strong>Striker, Winger, Center Mid, Center Back, Full Back</strong>). Build a balanced roster!</p>
            </div>
            <div class="help-section" style="margin-top: 16px;">
                <h3>🏆 Winning Condition</h3>
                <p>Your team's standing is determined by the total <strong>Real Value</strong> of your won footballers, not by your bid amount. Real values are hidden during bidding and revealed at the end.</p>
            </div>
        </div>
    </div>

    <div class="container">
        
        <!-- SCREEN 1: JOIN/LOGIN -->
        <div id="screen-join" class="screen active">
            <div class="logo-container">
                <div class="logo-icon">⚽</div>
                <h1>BIT THE PLAYER</h1>
                <div class="subtitle">Local Network Footballer Auction</div>
            </div>

            <div class="glass-card">
                <div class="label">YOUR NICKNAME</div>
                <input type="text" id="nickname-input" placeholder="Enter Nickname..." maxlength="15">
                <button class="btn" id="join-btn">JOIN GAME</button>
            </div>
        </div>

        <!-- SCREEN 2: LOBBY -->
        <div id="screen-lobby" class="screen">
            <div class="glass-card" style="text-align: center;">
                <div class="label">CONNECTED TO SERVER</div>
                <div style="font-size: 16px; font-weight: 800; color: var(--primary); letter-spacing: 0.5px; margin-top: 4px;" id="server-status">WAITING IN LOBBY</div>
            </div>

            <div class="label" style="margin-left: 4px;">PLAYERS IN LOBBY</div>
            <div id="lobby-players-list" style="margin-bottom: 20px;">
                <!-- Dynamically filled -->
            </div>

            <div class="waiting-footer">
                <div class="spinner"></div>
                <span>Waiting for Host to start match...</span>
            </div>
        </div>

        <!-- SCREEN 3: GAME / BIDDING -->
        <div id="screen-game" class="screen">
            <div class="game-header">
                <div class="wallet-box">
                    <span class="wallet-label">YOUR BUDGET</span>
                    <span class="wallet-value" id="game-budget">$100M</span>
                </div>
                <div class="lead-badge" id="lead-status">
                    <span>WAITING</span>
                </div>
            </div>

            <!-- Footballer display card -->
            <div class="glass-card footballer-card" id="footballer-card">
                <div class="timer-badge" id="timer-badge">
                    ⏱️ <span id="timer-text">0:15</span>
                </div>
                <div class="footballer-icon">🏃‍♂️</div>
                <div class="footballer-name" id="footballer-name">Lionel Messi</div>
                <div class="footballer-pos" id="footballer-position" style="font-size: 13px; font-weight: bold; color: var(--primary); margin-top: 4px; text-transform: uppercase; letter-spacing: 1px;">Striker</div>
            </div>

            <!-- Bids panel -->
            <div class="bid-panel">
                <div class="bid-info">
                    <span class="bidder-name" id="highest-bidder-label">No offers yet</span>
                </div>
                <div class="bid-val" id="highest-bid-val">$0M</div>
            </div>

            <!-- Inputs / Action area -->
            <div id="active-bid-controls">
                <div class="quick-bids-grid">
                    <button class="quick-bid-btn" id="qb-1">+1M</button>
                    <button class="quick-bid-btn" id="qb-5">+5M</button>
                    <button class="quick-bid-btn" id="qb-10">+10M</button>
                    <button class="quick-bid-btn" id="qb-20">+20M</button>
                </div>
                <div class="custom-bid-row">
                    <input type="number" id="custom-bid-input" placeholder="Custom Bid">
                    <button class="btn" id="custom-bid-btn">BID</button>
                </div>
                <div class="alert-banner" id="bid-error-banner">Bid Rejected</div>
            </div>

            <!-- Round Result pane (embedded, replaces active controls when bidding closes) -->
            <div id="round-result-panel" class="result-panel" style="display: none;">
                <div class="result-title" id="round-result-title">ROUND OVER</div>
                <div class="result-desc" id="round-result-desc">Nobody won.</div>
                <div class="waiting-footer" style="margin-top: 14px;">
                    <div class="spinner"></div>
                    <span>Waiting for Host to start next round...</span>
                </div>
            </div>
        </div>

        <!-- SCREEN 4: GAME OVER -->
        <div id="screen-game-over" class="screen">
            <div class="logo-container" style="margin-top: 20px; margin-bottom: 20px;">
                <div class="logo-icon" style="font-size: 50px;">🏆</div>
                <h1>GAME OVER</h1>
                <div class="subtitle">Final Standings</div>
            </div>

            <div class="leaderboard-list" id="game-over-list">
                <!-- Dynamically filled -->
            </div>

            <div class="waiting-footer" style="margin-top: 30px;">
                <div class="spinner"></div>
                <span>Waiting for Host to restart game...</span>
            </div>
        </div>

    </div>

    <script>
        // WebSocket and Game State management
        let ws;
        let playerId = generateUUID();
        let playerName = "";
        let selfBudget = 100;
        let highestBid = 0;
        let highestBidderId = "";

        // UI references
        const screens = {
            join: document.getElementById('screen-join'),
            lobby: document.getElementById('screen-lobby'),
            game: document.getElementById('screen-game'),
            gameOver: document.getElementById('screen-game-over')
        };

        // DOM elements
        const nameInput = document.getElementById('nickname-input');
        const joinBtn = document.getElementById('join-btn');
        const statusBox = document.getElementById('server-status');
        const playersList = document.getElementById('lobby-players-list');
        
        // Game UI elements
        const budgetVal = document.getElementById('game-budget');
        const leadStatus = document.getElementById('lead-status');
        const footballerCard = document.getElementById('footballer-card');
        const timerBadge = document.getElementById('timer-badge');
        const timerText = document.getElementById('timer-text');
        const footballerNameText = document.getElementById('footballer-name');
        const footballerPositionText = document.getElementById('footballer-position');
        const bidderLabel = document.getElementById('highest-bidder-label');
        const bidValueText = document.getElementById('highest-bid-val');
        const errorBanner = document.getElementById('bid-error-banner');
        
        // Input buttons
        const qb1 = document.getElementById('qb-1');
        const qb5 = document.getElementById('qb-5');
        const qb10 = document.getElementById('qb-10');
        const qb20 = document.getElementById('qb-20');
        const customBidInput = document.getElementById('custom-bid-input');
        const customBidBtn = document.getElementById('custom-bid-btn');
        const bidControls = document.getElementById('active-bid-controls');
        const roundResultPanel = document.getElementById('round-result-panel');
        const roundResultTitle = document.getElementById('round-result-title');
        const roundResultDesc = document.getElementById('round-result-desc');
        const gameOverList = document.getElementById('game-over-list');

        // Automatically set a randomized name on load
        nameInput.value = "Player_" + Math.floor(100 + Math.random() * 900);

        joinBtn.addEventListener('click', () => {
            const name = nameInput.value.trim();
            if(!name) {
                alert("Please enter a nickname");
                return;
            }
            connectServer(name);
        });

        function showScreen(screenKey) {
            Object.keys(screens).forEach(key => {
                screens[key].classList.remove('active');
            });
            screens[screenKey].classList.add('active');
        }

        function connectServer(name) {
            playerName = name;
            joinBtn.disabled = true;
            joinBtn.textContent = "CONNECTING...";
            
            // Connect to server (same IP/Port the browser loaded index.html from)
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}`;
            
            try {
                ws = new WebSocket(wsUrl);
                
                ws.onopen = () => {
                    sendMsg('client_join', { id: playerId, name: playerName });
                };

                ws.onmessage = (event) => {
                    const msg = JSON.parse(event.data);
                    handleMessage(msg);
                };

                ws.onclose = () => {
                    showErrorBanner("Disconnected from server. Refresh to reconnect.");
                    joinBtn.disabled = false;
                    joinBtn.textContent = "JOIN GAME";
                    showScreen('join');
                };

                ws.onerror = (err) => {
                    console.error("Socket error", err);
                };

            } catch (e) {
                alert("Connection failed: " + e);
                joinBtn.disabled = false;
                joinBtn.textContent = "JOIN GAME";
            }
        }

        function sendMsg(type, data) {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: type, data: data }));
            }
        }

        function handleMessage(msg) {
            switch(msg.type) {
                case 'join_success':
                    showScreen('lobby');
                    break;
                case 'lobby_update':
                    updateLobby(msg.data.players);
                    break;
                case 'new_round':
                    setupRound(msg.data);
                    break;
                case 'timer_tick':
                    updateTimer(msg.data.timeLeft);
                    break;
                case 'bid_update':
                    updateBid(msg.data);
                    break;
                case 'bid_rejected':
                    showErrorBanner(msg.data.reason);
                    break;
                case 'round_result':
                    showRoundResult(msg.data);
                    break;
                case 'game_over':
                    showGameOver(msg.data.scoreboard, msg.data.realValues || {}, msg.data.positions || {});
                    break;
                case 'game_reset_to_lobby':
                    showScreen('lobby');
                    break;
            }
        }

        function updateLobby(players) {
            playersList.innerHTML = '';
            players.forEach((player, index) => {
                const isMe = player.id === playerId;
                
                const item = document.createElement('div');
                item.className = 'player-item';
                if(isMe) {
                    item.style.borderColor = 'var(--primary)';
                    item.style.background = 'rgba(16, 185, 129, 0.08)';
                }
                
                const avatar = document.createElement('div');
                avatar.className = 'player-avatar';
                if(isMe) avatar.style.backgroundColor = 'var(--primary)';
                avatar.textContent = player.name[0].toUpperCase();
                
                const name = document.createElement('div');
                name.className = 'player-name';
                name.textContent = player.name + (isMe ? " (You)" : "");
                
                item.appendChild(avatar);
                item.appendChild(name);
                
                if(index === 0) {
                    const badge = document.createElement('span');
                    badge.className = 'badge';
                    badge.textContent = 'HOST';
                    item.appendChild(badge);
                }
                
                playersList.appendChild(item);
            });
        }

        function setupRound(data) {
            showScreen('game');
            bidControls.style.display = 'block';
            roundResultPanel.style.display = 'none';
            
            footballerNameText.textContent = data.footballer;
            footballerPositionText.textContent = data.position || 'Striker';
            highestBid = data.highestBid;
            highestBidderId = data.highestBidderId;
            
            updateBudgetAndLead();
            updateTimer(data.timeLeft);
            
            // Render starting bids
            if(highestBid > 0) {
                bidValueText.textContent = `$${highestBid}M`;
                bidderLabel.textContent = `Highest offer by ${data.highestBidderName}`;
            } else {
                bidValueText.textContent = '$0M';
                bidderLabel.textContent = 'No offers yet';
            }
        }

        function updateTimer(timeLeft) {
            timerText.textContent = `0:${timeLeft.toString().padStart(2, '0')}`;
            if(timeLeft <= 5) {
                timerBadge.classList.add('critical');
                footballerCard.classList.add('critical');
            } else {
                timerBadge.classList.remove('critical');
                footballerCard.classList.remove('critical');
            }
        }

        function updateBid(data) {
            highestBid = data.highestBid;
            highestBidderId = data.highestBidderId;
            
            bidValueText.textContent = `$${highestBid}M`;
            bidderLabel.textContent = `Highest offer by ${data.highestBidderName}`;
            
            updateBudgetAndLead();
        }

        function updateBudgetAndLead() {
            // Find self in players list to resolve budget
            const selfData = gamePlayersCache.find(p => p.id === playerId);
            if(selfData) {
                selfBudget = selfData.budget;
            }
            budgetVal.textContent = `$${selfBudget}M`;
            
            const isLeading = highestBidderId === playerId;
            const hasOffers = highestBid > 0;
            
            leadStatus.className = 'lead-badge';
            if(!hasOffers) {
                leadStatus.textContent = 'NO BIDS';
                leadStatus.style.borderColor = 'var(--text-muted)';
                leadStatus.style.color = 'var(--text-muted)';
            } else if(isLeading) {
                leadStatus.className = 'lead-badge winning';
                leadStatus.textContent = '🏆 YOU LEAD';
            } else {
                leadStatus.className = 'lead-badge outbid';
                leadStatus.textContent = '⚠️ OUTBID';
            }
            
            // Update quick bid buttons viability
            const qbs = [
                { btn: qb1, inc: 1 },
                { btn: qb5, inc: 5 },
                { btn: qb10, inc: 10 },
                { btn: qb20, inc: 20 }
            ];
            
            qbs.forEach(item => {
                const target = highestBid + item.inc;
                item.btn.textContent = `+$${item.inc}M`;
                item.btn.disabled = (target > selfBudget) || (target <= highestBid);
                
                // Clear inline event handlers to prevent duplication
                item.btn.onclick = () => sendBid(target);
            });
        }

        let gamePlayersCache = [];
        let gameRealValues = {};
        let gamePositions = {};

        // Keep players cached internally
        const originalHandleMessage = handleMessage;
        handleMessage = function(msg) {
            if(msg.type === 'lobby_update' || msg.type === 'round_result' || msg.type === 'game_over') {
                gamePlayersCache = msg.data.players || msg.data.scoreboard || [];
            }
            if(msg.type === 'round_result' || msg.type === 'game_over') {
                if(msg.data.realValues) gameRealValues = msg.data.realValues;
                if(msg.data.positions) gamePositions = msg.data.positions;
            }
            if(msg.type === 'game_reset_to_lobby') {
                gamePlayersCache = [];
                gameRealValues = {};
                gamePositions = {};
            }
            originalHandleMessage(msg);
        };

        function sendBid(amount) {
            if(amount <= highestBid) {
                showErrorBanner(`Bid must be higher than $${highestBid}M`);
                return;
            }
            if(amount > selfBudget) {
                showErrorBanner(`Insufficient budget! Only \$${selfBudget}M left`);
                return;
            }
            sendMsg('place_bid', {
                playerId: playerId,
                playerName: playerName,
                amount: amount
            });
            customBidInput.value = '';
        }

        // Custom bid button trigger
        customBidBtn.onclick = () => {
            const val = parseInt(customBidInput.value);
            if(isNaN(val) || val <= 0) {
                showErrorBanner("Enter a valid positive number");
                return;
            }
            sendBid(val);
        };

        customBidInput.addEventListener('keypress', (e) => {
            if(e.key === 'Enter') {
                const val = parseInt(customBidInput.value);
                if(isNaN(val) || val <= 0) return;
                sendBid(val);
            }
        });

        function showErrorBanner(reason) {
            errorBanner.textContent = reason;
            errorBanner.style.display = 'block';
            setTimeout(() => {
                errorBanner.style.display = 'none';
            }, 2500);
        }

        function showRoundResult(data) {
            bidControls.style.display = 'none';
            roundResultPanel.style.display = 'block';
            
            const isWinnerMe = data.winnerId === playerId;
            const hasWinner = data.winnerId !== '';
            
            roundResultPanel.className = 'result-panel';
            if (isWinnerMe) {
                roundResultPanel.classList.add('winner-me');
                roundResultTitle.textContent = '🏆 YOU WON THE PLAYER!';
                roundResultTitle.style.color = 'var(--primary)';
            } else if (hasWinner) {
                roundResultTitle.textContent = 'ROUND OVER';
                roundResultTitle.style.color = 'var(--secondary)';
            } else {
                roundResultTitle.textContent = 'UNSOLD PLAYER';
                roundResultTitle.style.color = 'var(--text-muted)';
            }
            
            roundResultDesc.textContent = hasWinner
                ? `${data.winnerName} bought ${data.footballer} (${data.position || 'Striker'}) for \$${data.winningBid}M`
                : `No bids were placed on ${data.footballer}.`;
        }

        function showGameOver(scoreboard, realValues, positions) {
            showScreen('gameOver');
            gameOverList.innerHTML = '';
            
            // Helper to get real value of footballer
            function getRealValue(name) {
                if (realValues && realValues[name] !== undefined) {
                    return realValues[name];
                }
                return 50; // Fallback
            }

            // Helper to calculate total team value
            function getTeamValue(player) {
                let sum = 0;
                let strikerCount = 0;
                let midfielderCount = 0;
                let defenderCount = 0;
                player.wonFootballers.forEach(f => {
                    const val = getRealValue(f);
                    const pos = positions[f] || 'Striker';
                    if (pos === 'Striker') {
                        strikerCount++;
                        if (strikerCount > 1) {
                            sum += val * 0.5;
                        } else {
                            sum += val;
                        }
                    } else if (pos === 'Center Mid' || pos === 'Winger') {
                        midfielderCount++;
                        if (midfielderCount > 2) {
                            sum += val * 0.5;
                        } else {
                            sum += val;
                        }
                    } else if (pos === 'Center Back' || pos === 'Full Back') {
                        defenderCount++;
                        if (defenderCount > 2) {
                            sum += val * 0.5;
                        } else {
                            sum += val;
                        }
                    } else {
                        sum += val;
                    }
                });
                return sum;
            }

            // Sort by team real value, then budget
            const list = [...scoreboard];
            list.sort((a,b) => {
                const valA = getTeamValue(a);
                const valB = getTeamValue(b);
                const valComp = valB - valA;
                if(valComp !== 0) return valComp;
                return b.budget - a.budget;
            });
            
            list.forEach((player, index) => {
                const isMe = player.id === playerId;
                const rank = index + 1;
                
                const item = document.createElement('div');
                item.className = 'board-item';
                if(isMe) item.classList.add('self');
                
                const row = document.createElement('div');
                row.className = 'board-row';
                
                const rankSpan = document.createElement('span');
                rankSpan.className = 'board-rank';
                if(rank === 1) rankSpan.classList.add('rank-gold');
                else if(rank === 2) rankSpan.classList.add('rank-silver');
                else if(rank === 3) rankSpan.classList.add('rank-bronze');
                
                rankSpan.textContent = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : `#${rank}`;
                
                const nameSpan = document.createElement('span');
                nameSpan.className = 'board-name';
                nameSpan.textContent = player.name + (isMe ? " (You)" : "");
                
                const scoreSpan = document.createElement('div');
                scoreSpan.className = 'board-score';
                
                const countSpan = document.createElement('span');
                countSpan.className = 'board-count';
                countSpan.textContent = `$${getTeamValue(player)}M Valuation`;
                
                const walletSpan = document.createElement('div');
                walletSpan.className = 'board-wallet';
                walletSpan.textContent = `Wallet: $${player.budget}M (${player.wonFootballers.length} Players)`;
                
                scoreSpan.appendChild(countSpan);
                scoreSpan.appendChild(walletSpan);
                
                row.appendChild(rankSpan);
                row.appendChild(nameSpan);
                row.appendChild(scoreSpan);
                item.appendChild(row);
                
                // Add won player tags
                if(player.wonFootballers.length > 0) {
                    const tags = document.createElement('div');
                    tags.className = 'board-tags';
                    player.wonFootballers.forEach(f => {
                        const tag = document.createElement('span');
                        tag.className = 'tag';
                        const pos = positions[f] || 'Striker';
                        tag.textContent = `${f} (${pos} - $${getRealValue(f)}M)`;
                        tags.appendChild(tag);
                    });
                    item.appendChild(tags);
                }
                
                gameOverList.appendChild(item);
            });
        }

        window.toggleHelpModal = function(show) {
            const modal = document.getElementById('help-modal');
            if (modal) modal.style.display = show ? 'flex' : 'none';
        };

        window.closeHelpModal = function(event) {
            const modal = document.getElementById('help-modal');
            if (modal && event.target === modal) {
                window.toggleHelpModal(false);
            }
        };

        window.toggleLeaderboardModal = function(show) {
            const modal = document.getElementById('leaderboard-modal');
            if (!modal) return;
            
            if (show) {
                const listContainer = document.getElementById('leaderboard-modal-list');
                if (listContainer) {
                    listContainer.innerHTML = '';
                    
                    if (gamePlayersCache.length === 0) {
                        listContainer.innerHTML = '<div style="text-align: center; color: var(--text-muted); font-weight: bold; padding: 20px;">No players in lobby yet.</div>';
                    } else {
                        const list = [...gamePlayersCache];
                        
                        function getRealValue(name) {
                            if (gameRealValues && gameRealValues[name] !== undefined) {
                                return gameRealValues[name];
                            }
                            return 50;
                        }
                        
                        function getTeamValue(player) {
                            let sum = 0;
                            let strikerCount = 0;
                            let midfielderCount = 0;
                            let defenderCount = 0;
                            player.wonFootballers.forEach(f => {
                                const val = getRealValue(f);
                                const pos = gamePositions[f] || 'Striker';
                                if (pos === 'Striker') {
                                    strikerCount++;
                                    if (strikerCount > 1) {
                                        sum += val * 0.5;
                                    } else {
                                        sum += val;
                                    }
                                } else if (pos === 'Center Mid' || pos === 'Winger') {
                                    midfielderCount++;
                                    if (midfielderCount > 2) {
                                        sum += val * 0.5;
                                    } else {
                                        sum += val;
                                    }
                                } else if (pos === 'Center Back' || pos === 'Full Back') {
                                    defenderCount++;
                                    if (defenderCount > 2) {
                                        sum += val * 0.5;
                                    } else {
                                        sum += val;
                                    }
                                } else {
                                    sum += val;
                                }
                            });
                            return sum;
                        }
                        
                        list.sort((a, b) => {
                            const valA = getTeamValue(a);
                            const valB = getTeamValue(b);
                            const valComp = valB - valA;
                            if (valComp !== 0) return valComp;
                            return b.budget - a.budget;
                        });
                        
                        list.forEach((player, index) => {
                            const isMe = player.id === playerId;
                            const rank = index + 1;
                            
                            const item = document.createElement('div');
                            item.className = 'board-item';
                            if (isMe) item.classList.add('self');
                            item.style.marginBottom = '10px';
                            
                            const row = document.createElement('div');
                            row.className = 'board-row';
                            
                            const rankSpan = document.createElement('span');
                            rankSpan.className = 'board-rank';
                            if (rank === 1) rankSpan.classList.add('rank-gold');
                            else if (rank === 2) rankSpan.classList.add('rank-silver');
                            else if (rank === 3) rankSpan.classList.add('rank-bronze');
                            rankSpan.textContent = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : `#${rank}`;
                            
                            const nameSpan = document.createElement('span');
                            nameSpan.className = 'board-name';
                            nameSpan.textContent = player.name + (isMe ? " (You)" : "");
                            
                            const scoreSpan = document.createElement('div');
                            scoreSpan.className = 'board-score';
                            
                            const countSpan = document.createElement('span');
                            countSpan.className = 'board-count';
                            countSpan.textContent = `$${getTeamValue(player)}M`;
                            
                            const walletSpan = document.createElement('div');
                            walletSpan.className = 'board-wallet';
                            walletSpan.textContent = `Wallet: $${player.budget}M`;
                            
                            scoreSpan.appendChild(countSpan);
                            scoreSpan.appendChild(walletSpan);
                            
                            row.appendChild(rankSpan);
                            row.appendChild(nameSpan);
                            row.appendChild(scoreSpan);
                            item.appendChild(row);
                            
                            if (player.wonFootballers && player.wonFootballers.length > 0) {
                                const tags = document.createElement('div');
                                tags.className = 'board-tags';
                                player.wonFootballers.forEach(f => {
                                    const tag = document.createElement('span');
                                    tag.className = 'tag';
                                    const pos = gamePositions[f] || 'Striker';
                                    tag.textContent = `${f} (${pos} - $${getRealValue(f)}M)`;
                                    tags.appendChild(tag);
                                });
                                item.appendChild(tags);
                            } else {
                                const noPlayers = document.createElement('div');
                                noPlayers.style.fontSize = '11px';
                                noPlayers.style.color = 'var(--text-muted)';
                                noPlayers.style.marginTop = '6px';
                                noPlayers.style.fontStyle = 'italic';
                                noPlayers.style.fontWeight = 'bold';
                                noPlayers.style.paddingLeft = '32px';
                                noPlayers.textContent = 'No footballers won yet';
                                item.appendChild(noPlayers);
                            }
                            
                            listContainer.appendChild(item);
                        });
                    }
                }
                modal.style.display = 'flex';
            } else {
                modal.style.display = 'none';
            }
        };

        window.closeLeaderboardModal = function(event) {
            const modal = document.getElementById('leaderboard-modal');
            if (modal && event.target === modal) {
                window.toggleLeaderboardModal(false);
            }
        };

        // UUID helper
        function generateUUID() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }
    </script>
</body>
</html>
''';
