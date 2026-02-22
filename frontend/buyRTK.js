import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract } from "./init.js";
import { updateBalance } from "./balances.js";

const buyRTKbtn = document.querySelector('.buyRTKbtn');
const buyRTKinput = document.querySelector('.buyRTKinput');

async function buyRTK(valueETHstr) {
    const valueRTK = Number(valueETHstr);
    try {
        buyRTKbtn.textContent = 'Покупка...';
        buyRTKbtn.disabled = true;

        const valueWei = await ethers.parseEther(valueRTK.toString(), 12);
        const tx = await DAOcontract.buyRTK({ value: valueWei });

        await tx.wait();
        await updateBalance();

        alert(`Вы купили ${valueRTK} RTK`);
        document.querySelector('.buyRTKinput').value = '';
    } catch (error) {
        console.error(error);
    } finally {
        buyRTKbtn.textContent = 'Купить';
        buyRTKbtn.disabled = false;
    }
}
buyRTKbtn.addEventListener('click', () => {
    const valueRTK = buyRTKinput.value;
    buyRTK(valueRTK);
})