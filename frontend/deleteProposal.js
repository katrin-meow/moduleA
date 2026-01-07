import { DAOcontract } from "./init.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { showNotification } from "./showNotifications.js";


const deleteBtn = document.querySelector('.deleteBtn');
const deleteInput = document.querySelector('.deleteInput');

deleteBtn.addEventListener('click', async () => {
    const proposald = Number(deleteInput.value);

    if (Number.isNaN(proposald) || proposald < 0) {
        showNotification('Enter valid Proposal ID', 'error');
        return;
    }

    try {
        deleteBtn.textContent = 'Pending...';
        deleteBtn.disabled = true;

        const tx = await DAOcontract.deleteProposal(proposald);
        await tx.wait();

        showNotification(`Proposal: №${proposald} deleted!`, 'success');
        deleteInput.value = '';
    } catch (err) {
        showNotification(err.reason || 'Delete failed');
    } finally {
        deleteBtn.textContent = 'Delete proposal';
        deleteBtn.disabled = false;
    }
});