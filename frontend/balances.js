import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { signer, DAOcontract, PROFIcontract, RTKcontract } from "./init.js";
let currentUserRole = 'unknown';

export async function updateBalance() {
    if (!DAOcontract || !signer) {
        console.log('Contracts not ready');
        return;
    }

    try {
        const userAddr = await signer.getAddress();
        const isMember = await DAOcontract.isDAOmember(userAddr);
        currentUserRole = isMember ? 'daoMember' : 'nonMember';

        const tokenContract = isMember ? PROFIcontract : RTKcontract;
        const raw = await tokenContract.balanceOf(userAddr);
        const balance = ethers.formatUnits(raw, 12);

        const elem = document.querySelector('.balanceValue');
        if (elem) {
            elem.textContent = `${isMember ? 'PROFI' : 'RTK'}: ${balance}`;
        }
    } catch (e) {
        console.error('updateBalance error:', e);
    }
};