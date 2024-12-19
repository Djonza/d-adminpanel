
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.type === 'showAdminMenu') {
       document.body.style.display = 'flex';
        showSection('players');
    } else if (data.type === 'hideAdminMenu') {
        document.body.style.display = 'none';
    } else if (data.type === 'showPlayerList') {
        displayPlayerList(data.players);
    } else if (data.action === 'addLog') {
        addLog(data.type, data.message);
    } else if (data.type === 'receiveAllWarns') {
        displayWarns(data.warns); 
    } else if (data.type === 'openBanModal') {
        document.body.style.display = 'flex';
        document.getElementById('modal-container').style.display = 'flex';
    }
});


function showSection(sectionId) {
    const sections = document.querySelectorAll('.section');
    sections.forEach(section => section.classList.remove('active'));
    document.getElementById(sectionId).classList.add('active');
}


function displayPlayerList(players) {
    const playerList = document.getElementById('playerList');
    playerList.innerHTML = '';

    players.forEach(player => {
        const playerItem = document.createElement('div');
        playerItem.className = 'player-item';
        playerItem.dataset.name = player.name.toLowerCase();
        playerItem.dataset.id = player.id.toString();
        playerItem.innerHTML = `
            <span>ID: ${player.id} - ${player.name}</span>
        `;
        playerList.appendChild(playerItem);
        playerItem.addEventListener('click', () => openPlayerModal(player.name, player.id));
       playerList.appendChild(playerItem);
    });
}

document.addEventListener('DOMContentLoaded', () => {
    const navButtons = document.querySelectorAll('.nav-btn');
    const indicator = document.querySelector('.nav-indicator');
    const banoviSection = document.getElementById('bans');
    const warnoviSection = document.getElementById('warnovi');

    function moveIndicator(button) {
        const buttonRect = button.getBoundingClientRect();
        const parentRect = button.parentElement.getBoundingClientRect();
        indicator.style.left = `${buttonRect.left - parentRect.left}px`;
        indicator.style.width = `${buttonRect.width}px`;
    }
    navButtons.forEach(button => {
        button.addEventListener('click', () => {
            navButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');

            if (button.getAttribute('data-target') === 'bans') {
                banoviSection.style.display = 'block';
                warnoviSection.style.display = 'none';
            } else {
                banoviSection.style.display = 'none';
                warnoviSection.style.display = 'block';
                fetchAllWarnings();
            }

            moveIndicator(button);
        });
    });
    const defaultButton = document.querySelector('.nav-btn[data-target="bans"]');
    defaultButton.classList.add('active');
    banoviSection.style.display = 'block';
    warnoviSection.style.display = 'none';
    moveIndicator(defaultButton);
});

function fetchAllWarnings() {
    fetch(`https://${GetParentResourceName()}/getAllWarns`, {
        method: 'POST'
    });
}

window.addEventListener('message', function(event) {
    if (event.data.type === 'receiveAllWarns') {
        const warns = event.data.warns;
        displayWarns(warns);
    }
});

function displayWarns(warns) {
    const warnTableBody = document.getElementById('warnTableBody');
    warnTableBody.innerHTML = ''; 
    warns.forEach(warn => {
        const row = document.createElement('tr');
        row.dataset.warnId = warn.warnId; 

        row.innerHTML = `
            <td>${warn.warnId}</td>
            <td>${warn.playerName}</td>
            <td>${warn.warnedBy}</td>
            <td>${warn.reason}</td>
            <td>${formatDate(warn.timestamp)}</td>
            <td><button class="btn-remove-warn" onclick="removeWarn(${warn.warnId})">Remove warn</button></td>
        `;

        warnTableBody.appendChild(row);
    });
}

function removeWarn(warnId) {
    fetch(`https://${GetParentResourceName()}/removeWarn`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ warnId: warnId })
    }).then(response => {
        if (response.ok) {
            const warnRow = document.querySelector(`tr[data-warn-id="${warnId}"]`);
            if (warnRow) {
                warnRow.remove();
            }
        } else {
            console.log('Error while removing warn.');
        }
    }).catch(error => {
        console.error('Error:', error);
    });
}


function closeBanModal() {
    document.getElementById('modal-container').style.display = 'none';
    document.getElementById('banPlayerId').value = '';
    document.getElementById('banReason').value = '';
    document.getElementById('banDuration').value = '';
}

function submitBan() {
    const playerId = document.getElementById('banPlayerId').value;
    const reason = document.getElementById('banReason').value;
    const duration = document.getElementById('banDuration').value;

    if (playerId && reason && duration) {
        fetch(`https://${GetParentResourceName()}/submitBan`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId, reason, duration })
        });
        closeBanModal();
    } else {
        console.log('Not filled')
    }
}

function submitWarn() {
    const playerId = document.getElementById('warnPlayerId').value;
    const reason = document.getElementById('warnReason').value;

    if (playerId && reason && duration) {
        fetch(`https://${GetParentResourceName()}/submitBan`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId, reason})
        });
        closeBanModal();
    } else {
        console.log('Not filled')
    }
}

function filterPlayers() {
    const input = document.getElementById('searchInput').value.toLowerCase();
    const playerItems = document.querySelectorAll('.player-item');

    playerItems.forEach(item => {
        const name = item.dataset.name;
        const id = item.dataset.id;

        if (name.includes(input) || id.includes(input)) {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    });
}


let currentPlayerId = null;
let currentPlayerName = null;

function openPlayerModal(name, id) {
    currentPlayerId = id;
    currentPlayerName = name;
    const modalTitle = document.getElementById('playerModalTitle');
    modalTitle.textContent = `Opcije za: ${name} (ID: ${id})`;
    document.getElementById('playerModal').style.display = 'flex';
}


function performAction(action) {
    console.log(`Performing action: ${action}`);
    fetch(`https://${GetParentResourceName()}/performAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: action })
    });
    document.getElementById('playerModal').style.display = 'none';
}


function displayMessage(message) {
    const output = document.getElementById('output');
    output.innerHTML = `<p>${message}</p>`;
}

const logContainer = document.getElementById('log-container');
const logFilters = document.querySelectorAll('.log-filter');

function addLog(type, message) {
    const time = new Date().toLocaleTimeString('en-GB');
    const logEntry = document.createElement('div');
    logEntry.classList.add('log-entry');
    logEntry.dataset.type = type; 
    logEntry.innerHTML = `<time>${time}</time> <span>[${type}] ${message}</span>`;
    logContainer.prepend(logEntry);
}
function filterLogs() {
    const activeFilters = Array.from(logFilters)
        .filter(checkbox => checkbox.checked)
        .map(checkbox => checkbox.dataset.type);

    const logEntries = document.querySelectorAll('.log-entry');
    logEntries.forEach(entry => {
        if (activeFilters.includes(entry.dataset.type)) {
            entry.style.display = 'flex';
        } else {
            entry.style.display = 'none';
        }
    });
}

logFilters.forEach(checkbox => {
    checkbox.addEventListener('change', filterLogs);
});
document.addEventListener('DOMContentLoaded', filterLogs);
function gotoPlayer(id, name) {
    fetch(`https://${GetParentResourceName()}/gotoPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
    closeAdminMenu()
}

function bringPlayer(id, name) {
    fetch(`https://${GetParentResourceName()}/bringPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
    closeAdminMenu()
}

function revivePlayer(id) {
    fetch(`https://${GetParentResourceName()}/revivePlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
    closeAdminMenu();
}

function healPlayer(id, name) {
    fetch(`https://${GetParentResourceName()}/healPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
}
function slayPlayer(id, name) {
    fetch(`https://${GetParentResourceName()}/slayPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
}

function spectatePlayer(id, name) {
    fetch(`https://${GetParentResourceName()}/spectatePlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId: id })
    });
    closePlayerModal();
}

function sendMessageToPlayer(id, name) {
    const message = document.getElementById('chatMessage').value.trim();
    if (message) {
        fetch(`https://d-adminpanel/sendMessageToPlayer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId: id, message: message })
        });
        document.getElementById('chatMessage').value = '';
        closePlayerModal();
    } else {
        console.log('No message')
    }
}



document.addEventListener('DOMContentLoaded', () => {
    showSection('history');
});


function closePlayerModal() {
    document.getElementById('playerModal').style.display = 'none';
}

function closeAdminMenu() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

document.getElementById('closeButton').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
});
