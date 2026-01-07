import { signer, DAOcontract, RTKcontract } from "./init.js";  
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { showNotification } from "./showNotifications.js";
import { updateBalance } from "./balances.js";  

const buyRTKinput = document.querySelector('.buyRTKinput');
const buyRTKbtn = document.querySelector('.buyRTKbtn');

async function buyRTK(amountEthStr) {
    if (!DAOcontract || !signer || !RTKcontract) {  
        showNotification('Contracts not ready!', 'error');
        return;
    }
    const amountEth = Number(amountEthStr);
    if (!amountEth || amountEth <= 0 || Number.isNaN(amountEth)) {
        showNotification('Enter valid ETH amount!', 'error');
        return;
    }
    try {
        buyRTKbtn.textContent = 'Buying...';
        buyRTKbtn.disabled = true;
        const ethWei = ethers.parseEther(amountEth.toString());
        const tx = await DAOcontract.buyRTK({ value: ethWei });
        await tx.wait();

        await updateBalance();
        
        buyRTKinput.value = '';
        
    } catch (err) {
        console.error(err);
        showNotification(err.reason || err.message || 'Buy failed', 'error');
    } finally {
        buyRTKbtn.textContent = 'Buy';
        buyRTKbtn.disabled = false;
    }
}

buyRTKbtn.addEventListener('click', () => {
    const amountEth = buyRTKinput.value;
    buyRTK(amountEth);
});
