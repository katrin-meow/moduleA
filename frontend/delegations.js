import { DAOcontract } from "./init.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";

const delegationsContainer = document.querySelector('.delegationsList') || (() => {
    const div = document.createElement('div');
    div.className = 'delegationsList';
    div.innerHTML = '<h2>Мои делегации</h2>';
    document.body.appendChild;
    return div;
})();

export async function loadMyDeleg() {
    delegationsContainer.innerHTML = '<h2>Мои делегации</h2><p>Делегации не найдены</p>';
    const count = await DAOcontract.proposalCount();

    for (let c = 0; c < Number(count); c++) {
     
        const delegations = await DAOcontract.getMyDelegations();

        for (let d = 0; d < delegations.length; d++) {
               delegationsContainer.innerHTML = '<h2>Мои делегации</h2>';
            const delegation = delegations[d];
            const id = delegation[0];
            const to = delegation[1];
            const value = delegation[2];
            const valueStr = Number(ethers.formatUnits(value, 12)).toFixed(0);
            delegationsContainer.innerHTML += `
            <div class="delegation" data-proposal="${c}">
            <h3>Делегация №${d}</h3>
            <p>Предложение №${id}</p>
            <p>Цель: ${to}</p>
            <p>Количество токенов: ${valueStr} </p>
            </div>
            `
        }
    }DAOcontract.on('Delegated', () => loadMyDeleg());
}