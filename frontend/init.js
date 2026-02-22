import { updateBalance } from "./balances.js";
import { loadMyDeleg } from "./delegations.js";
import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { loadProposals } from "./proposals.js";

const connectWalletBtn = document.querySelector('.connectWalletBtn');

export let provider;
export let signer;
export let DAOcontract;
export let PROFIcontract;
export let RTKcontract;

async function loadContractData(name) {
    const responce = await fetch(`./dataContracts/${name}.json`);
    return await responce.json();
}

async function connectWallet(event) {
    try {
        provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        const userAddress = await signer.getAddress();

        const DAOdata = await loadContractData("DAO");
        const PROFIdata = await loadContractData("SystemToken");
        const RTKdata = await loadContractData("WrapToken");

        DAOcontract = new ethers.Contract(DAOdata.address, DAOdata.abi, signer);
        PROFIcontract = new ethers.Contract(PROFIdata.address, PROFIdata.abi, signer);
        RTKcontract = new ethers.Contract(RTKdata.address, RTKdata.abi, signer);

        const isDAO = await DAOcontract.isDAO(userAddress);
        document.body.className = isDAO ? "daoMember" : 'nonDaoMember';
        connectWalletBtn.textContent = `Подключен: ${userAddress}`;
        connectWalletBtn.disabled = true;
        await updateBalance();
        await loadProposals();
        await loadMyDeleg();
    } catch (error) {
        console.error(error);
    }

}
connectWalletBtn.addEventListener('click', connectWallet);
connectWallet();