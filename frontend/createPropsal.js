import { DAOcontract } from "./init.js";
import { showNotification } from "./showNotifications.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { loadProposals } from "./proposals.js";

const form = document.querySelector(".createProposalForm");
const createBtn = document.querySelector('.createPropsalBtn');
async function createProposal() {
    const proposalType = Number(document.querySelector('.proposalType').value);
    const durationMin = Number(document.querySelector('.durationMin').value);
    const valueForChange = Number(document.querySelector('.valueForChange').value);
    const needVotes = Number(document.querySelector('.needVotes').value);
    const target = document.querySelector('.target').value;
    const quorum = Number(document.querySelector('.quorumMechanism').value);

    try {
        ethers.getAddress(target);
    } catch {
        showNotification('Invalid target address', 'error');
        return;
    }
    try {
        const tx = await DAOcontract.createProposal(
            proposalType,
            durationMin,
            valueForChange,
            target,
            needVotes,
            quorum
        );

        const receipt = await tx.wait();
        const proposalId = receipt.logs[0]?.args?.proposalId || 'unknown';
        showNotification(`Proposal  id${proposalId} created! Tx: ${tx.hash.slice(0, 20)}...`, 'success');
        loadProposals();
    } catch (error) {
        showNotification(error.message || 'Failed create proposal', 'error');
        return;
    }

}
createBtn.addEventListener('click', (e) => {
    e.preventDefault();
    createProposal();
})
