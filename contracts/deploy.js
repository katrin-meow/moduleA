(async () => {
    try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contractNames = ["SystemToken", "WrapToken", "DAO"];
        const deployedAddr = {};
        const DAOmems = [
            "0x71562b71999873DB5b286dF957af199Ec94617F7",
            "0x164d9004a913C67d927aeC0f9029A3C82e1fF19c",
            "0x1994BdbC0418A7E50B25765f106c3E285b186e9D"
        ];
        //0x2ab34792973568f6C3F1ad04501A2460AE40450F
        for (const name of contractNames) {

            const artifactPath = `artifacts/${name}.json`;
            const content = await remix.call('fileManager', 'getFile', artifactPath);
            const artifact = await JSON.parse(content);
            let args = [];
            if (name === "SystemToken") {
                args = [DAOmems];
            } else if (name === "DAO") {
                if (!deployedAddr["SystemToken"] || !deployedAddr["WrapToken"]) {
                    console.log('токены не задеплоены');
                    return;
                } args = [DAOmems, deployedAddr["SystemToken"], deployedAddr["WrapToken"]];
            } else if (name === "WrapToken") {
                args = [];
            }

            const contractABI = artifact.abi;
            const contractBytecode = artifact.data.bytecode.object;

            const factory = new ethers.ContractFactory(contractABI, contractBytecode, signer);
            const contract = await factory.deploy(...args);
            await contract.waitForDeployment();

            const address = await contract.getAddress();
            deployedAddr[name] = address;

            const dataToSave = {
                address: address,
                abi: contractABI
            };
            const savePath = `../frontend/dataContracts/${name}.json`;
            await remix.call('fileManager', 'writeFile', savePath, JSON.stringify(dataToSave, null, 2));
            console.log('contracts are ready');
        }
    } catch (error) {
        console.error(error);
    }
})();