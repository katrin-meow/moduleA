import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract } from "./init.js";
import { loadProposals } from "./proposals.js";

const createBtn = document.querySelector('.createBtn');

async function createProposal() {
    const propType = Number(document.querySelector('.propType').value);
    const quorum = Number(document.querySelector('.quorum').value);
    const target = document.querySelector('.createTarget').value;
    const need = Number(document.querySelector('.createNeed').value);
    const value = Number(document.querySelector('.createValue').value);
    const duration = Number(document.querySelector('.createDuration').value);
    try {
        createBtn.textContent = 'Создание...';
        createBtn.disabled = true;
        const tx = await DAOcontract.createProposal(
            target,
            duration,
            propType,
            quorum,
            need,
            value
        );
        await tx.wait();
        await loadProposals();
        alert('Вы создали предложение');
        document.querySelector('.createTarget').value = '';
        document.querySelector('.createNeed').value = '';
        document.querySelector('.createValue').value = '';
        document.querySelector('.createDuration').value = '';
    } catch (error) {
        console.error(error);
    } finally {
        createBtn.textContent = 'Создать';
        createBtn.disabled = false;
    }
}
createBtn.addEventListener('click', (e) => {
    e.preventDefault();
    createProposal();
})
