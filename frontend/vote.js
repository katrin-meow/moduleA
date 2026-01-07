import { DAOcontract } from "./init.js";
import { showNotification } from "./showNotifications.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";

const voteBtn = document.querySelector('.voteBtn');

async function vote() {
    const voteValue = Number(document.querySelector('.voteValue').value);
    const proposalId = Number(document.querySelector('.voteProposalId').value);
    const voteSupport = document.querySelector('.voteSupport').value === 'true';

    if (Number.isNaN(proposalId) || proposalId < 0) {
        showNotification('Enter valid Proposal ID', 'error');
        return;
    }
    if (voteValue < 0 || Number.isNaN(voteValue)) {
        showNotification('Enter the correct token amount', 'error');
        return;
    }
    try {
        const valueWei = ethers.parseUnits(voteValue.toString(), 12);
        const tx = await DAOcontract.vote(
            proposalId,
            voteSupport,
            valueWei          
        );
        await tx.wait();
    } catch (err) {
        console.error(err);
        console.log("test")
        showNotification(err.message || 'Vote failed', 'error');
    }
}


voteBtn.addEventListener('click', (e) => {
    e.preventDefault();
    vote();
})
