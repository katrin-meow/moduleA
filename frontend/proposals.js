import { DAOcontract, signer } from "./init.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { showNotification } from "./showNotifications.js";

const proposalsContainer = document.querySelector('.proposalsList') || (() => {
    const div = document.createElement('div');
    div.className = 'proposalsList';
    div.innerHTML = '<h2>Active Proposals</h2>';
    document.body.insertBefore(div, document.querySelector('.connectWalletBtn').nextSibling);
    return div;
})();


export async function loadProposals() {
    const count = await DAOcontract.proposalCount();
    proposalsContainer.innerHTML = '<h2>Active Proposals</h2>';

    for (let i = 0; i < Number(count); i++) {
        const result = await DAOcontract.getProposals(i);

        const [
            status,
            endTime,
            quorumMechanism,
            proposalType,
            proposer,
            target,
            votesFor,
            votesAgainst
        ] = result;


        if (Number(status) === 0) {
            proposalsContainer.innerHTML += `
  <div class="proposal" data-id="${i}">
      <p>ID: ${i} | Type: ${proposalType}</p>
      <p>Proposer: ${proposer}</p>
      <p>Target: ${target}</p>
      <p>Quorum mechanism ${quorumMechanism} </p>
     <p>FOR: ${(Number(ethers.formatUnits(votesFor, 12))).toFixed(2)} | AGAINST: ${(Number(ethers.formatUnits(votesAgainst, 12))).toFixed(2)}</p>
      <p>Ends in: <span class="timer" data-end="${Number(endTime)}"></span></p>
      <button class="voteFromCardBtn">Vote</button>
  </div>`;
        }
    }

    const cards = proposalsContainer.querySelectorAll('.proposal');

    cards.forEach(card => {
        const id = Number(card.dataset.id);
        const btn = card.querySelector('.voteFromCardBtn');
        const timerSpan = card.querySelector('.timer');
        const endSec = Number(timerSpan.dataset.end);


        btn.addEventListener('click', () => {
            document.querySelector('.voteProposalId').value = id;
            showNotification(`Voting for proposal #${id}`);
        });

        function updateTimer() {
            const now = Date.now();
            const diff = endSec * 1000 - now;
            if (diff <= 0) {
                timerSpan.textContent = 'finished';
                return;
            }
            const minutes = Math.floor(diff / 60000);
            const seconds = Math.floor((diff % 60000) / 1000);
            timerSpan.textContent = `${minutes}m ${seconds}s`;
        }
        updateTimer();
        setInterval(updateTimer, 1000);
    });
    DAOcontract.on('CastVote', () => loadProposals());
}


