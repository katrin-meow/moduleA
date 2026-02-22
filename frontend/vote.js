import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract } from "./init.js";
import { updateBalance } from "./balances.js";
import { loadProposals } from "./proposals.js";

const voteBtn = document.querySelector('.voteBtn');

async function vote() {
    const id = Number(document.querySelector('.voteId').value);
    const support = document.querySelector('.support').value === 'true';
    const value = Number(document.querySelector('.voteValue').value);
    try {
        voteBtn.textContent = 'Голосование...';
        voteBtn.disabled = true;

        const valueWei = await ethers.parseUnits(value.toString(), 12);
        const tx = await DAOcontract.vote(
            id,
            support,
            valueWei
        );
        await tx.wait();
        await updateBalance();
        await loadProposals();
        alert(`Выпроголосовали ${value} PROFI`);

        document.querySelector('.voteId').value = '';
        document.querySelector('.voteValue').value = '';
    } catch (error) {
        console.error(error);
    }finally {
           voteBtn.textContent = 'Отдать голос';
        voteBtn.disabled = false;
    }
}
voteBtn.addEventListener('click', (e) => {
    e.preventDefault();
    vote();
})