import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract } from "./init.js";


const proposalTypeNames = [
    "A - Инвестирование в новый Старт ап",
    "B - Инвестирование в существующий Старт ап",
    "C - Добавление участника в систему",
    "D - Удаление участника из системы",
    "E - Изменение курса ситемного токена",
    "F - Изменение курса Wrap-токена"
]

const quorumNames = [
    "Простой - 50% + 1 голос",
    "Супер - 2/3 голосов (ЗА)",
    "Взвешенный - зависит от веса голоса"
]


const proposalContainer = document.querySelector('.proposalList') || (() => {
    const div = document.createElement('div');
    div.className = 'proposalList';
    div.innerHTML = '<h2>Активные предложения</h2>';
    document.body.insertBefore(div, document.querySelector('.balanceValue').nextSibling);
    return div;
})();

export async function loadProposals() {
    proposalContainer.innerHTML = '<h2>Активных предложений нет</h2>';

    const count = await DAOcontract.proposalCount();
    for (let i = 0; i < Number(count); i++) {
        const result = await DAOcontract.getProposal(i);
        const [
            status,
            quorum,
            propType,
            endTime,
            votesFor,
            votesAgainst,
            target,
            proposer,
            needVotes,
            valueForChange
        ] = result;

        if (Number(status) === 0) {
            proposalContainer.innerHTML = '<h2>Активные предложения</h2>';
            const propName = proposalTypeNames[Number(propType)];
            const quorumName = quorumNames[Number(quorum)];

            proposalContainer.innerHTML += `
            <div class="proposal" data-id="${i}">
            <p>Предложение №${i} </p>
            <p>Тип предложения: ${propName} | Кворум: ${quorumName}</p>
            <p>Необходимо голосов: ${needVotes} | Новый курс токенов: ${valueForChange}</p>
            <p>Цель: ${target} </p>
            <p>Инициатор голосования: ${proposer} </p>
            <p>Голоса ЗА: ${(Number(ethers.formatUnits(votesFor.toString(), 12))).toFixed(1)} | Против: ${(Number(ethers.formatUnits(votesAgainst.toString(), 12))).toFixed(1)} </p>
            <p>Голосование закончится через: <span class="timer" data-end="${Number(endTime)}"> </span></p>
            </div>`
        }
    }
    const cards = document.querySelectorAll('.proposal');
    cards.forEach(card => {
        const timerSpan = card.querySelector('.timer');
        const endSec = timerSpan.dataset.end;

        function updateTimer() {
            const now = Math.floor(Date.now() / 1000);
            const diff = endSec - now;
            if (diff <= 0) {
                proposalContainer.innerHTML = '<h2>Активных предложений нет</h2>';
                return;
            }
            const minutes = Math.floor(diff / 60);
            const seconds = diff % 60;
            timerSpan.textContent = `${minutes}м ${seconds}с`;
        }
        updateTimer();
        setInterval(updateTimer, 1000);
    }); DAOcontract.on('CastVote', () => loadProposals());
}