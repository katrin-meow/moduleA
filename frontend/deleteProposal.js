import { DAOcontract } from "./init.js";
import { updateBalance } from "./balances.js";
import { loadProposals } from "./proposals.js";

const deleteBtn = document.querySelector('.deleteBtn');

async function deleteProposal() {
    const id = Number(document.querySelector('.deleteId').value);
    try {
        deleteBtn.textContent = 'Удаление...';
        deleteBtn.disabled = true;

        const tx = await DAOcontract.deleteProposal(id);

        await tx.wait();
        await updateBalance();
        await loadProposals();
        alert (`Вы удалили предложение №${id}`);
        document.querySelector('.deleteId').value = '';
    } catch (error) {
        console.error(error);
    } finally {
        deleteBtn.textContent = 'Удалить';
        deleteBtn.disabled = false;
    }
}
deleteBtn.addEventListener('click', (e) => {
    e.preventDefault();
    deleteProposal();
})