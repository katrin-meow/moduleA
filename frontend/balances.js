import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAOcontract, PROFIcontract, RTKcontract, signer } from "./init.js";

const balanceValue = document.querySelector('.balanceValue');

export async function updateBalance() {
    const userAddress = await signer.getAddress();
    const isDAO = await DAOcontract.isDAO(userAddress);
    const tokenContract = isDAO ? PROFIcontract : RTKcontract;
    const raw = await tokenContract.balanceOf(userAddress);
    const balance = Number(ethers.formatUnits(raw.toString(), 12)).toFixed(1);
    if (balanceValue) {
        balanceValue.textContent = `${isDAO ? "PROFI" : "RTK"}: ${balance}`;
    }
}