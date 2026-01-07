import { abiDAO, abiPROFI, abiRTK } from "./abi.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { showNotification } from "./showNotifications.js";
import { loadProposals } from "./proposals.js";
import { updateBalance } from "./balances.js";

const DAOaddress = "0x";
const PROFIaddress = "0x";
const RTKaddress = "0x";
let provider;
let signer;
let DAOcontract;
let PROFIcontract;
let RTKcontract;
const connectWalletBtn = document.querySelector(".connectWalletBtn");
async function connectWallet(event) {
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    DAOcontract = new ethers.Contract(DAOaddress, abiDAO, signer);
    PROFIcontract = new ethers.Contract(PROFIaddress, abiPROFI, signer);
    RTKcontract = new ethers.Contract(RTKaddress, abiRTK, signer);
    const userAddr = await signer.getAddress();
    showNotification(`Wallet connected: ${userAddr}`);
    connectWalletBtn.textContent = 'Connected';
    connectWalletBtn.disabled = true;
    const isMember = await DAOcontract.isDAOmember(userAddr);
    document.body.className = isMember ? 'dao-member' : 'non-dao-member';

    updateBalance();
    loadProposals();

    setInterval(updateBalance, 10000);
}
connectWalletBtn.addEventListener('click', connectWallet);
connectWallet();
export {
    provider,
    signer,
    DAOcontract,
    PROFIcontract,
    RTKcontract,
    DAOaddress
}




