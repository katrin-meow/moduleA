import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract } from "./init.js";
import { updateBalance } from "./balances.js";
import { loadMyDeleg } from "./delegations.js";

const delegateBtn = document.querySelector('.delegateBtn');

async function delegate() {
    const id = Number(document.querySelector('.delegateId').value);
    const to = document.querySelector('.delegateTarget').value;
    const value = Number(document.querySelector('.delegateValue').value);

    try {
        delegateBtn.textContent = 'Делегирование...';
        delegateBtn.disabled = true;

        const valueWei = await ethers.parseUnits(value.toString(), 12);
        const tx = await DAOcontract.delegate(
            id,
            to,
            valueWei
        );

        await tx.wait();
        await updateBalance();
        await loadMyDeleg();

        alert(`Вы делегировали ${value} RTK`);

        document.querySelector('.delegateId').value = '';
        document.querySelector('.delegateTarget').value = '';
        document.querySelector('.delegateValue').value = '';
    } catch (error) {
        console.error(error);
    } finally {
        delegateBtn.textContent = 'Делегировать';
        delegateBtn.disabled = false;
    }
}
delegateBtn.addEventListener('click', (e) => {
    e.preventDefault();
    delegate();
})