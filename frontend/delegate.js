import {  DAOcontract } from "./init.js";
import { showNotification } from "./showNotifications.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { loadMyDelegations } from "./delegations.js";

const delegateBtn = document.querySelector('.delegateBtn');

async function delegateRTK() {
    const toAddr = document.querySelector('.delegateAddr').value;
    const valueRTK = Number(document.querySelector('.delegateValue').value);
    const proposalId = Number(document.querySelector('.delegateId').value);
    const valueWei = ethers.parseUnits(valueRTK.toString(), 12);
    try {
        delegateBtn.textContent = 'Delegating...';
        delegateBtn.disabled = true;
        const tx = await DAOcontract.delegate(toAddr, valueWei, proposalId);
        await tx.wait();
        document.querySelector('.delegateAddr').value = '';
        document.querySelector('.delegateValue').value = '';
        document.querySelector('.delegateId').value = '';
    } catch (err) {
        console.error('DELEGATE ERROR:', err);
        showNotification('Delegate failed!', 'error');
    } finally {
        delegateBtn.textContent = 'Delegate';
        delegateBtn.disabled = false;
    }
}

loadMyDelegations();
delegateBtn.addEventListener('click', (e) => {
    e.preventDefault();
    delegateRTK();
});
