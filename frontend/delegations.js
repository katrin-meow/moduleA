const delegationsContainer = document.querySelector('.myDelegations') || (() => {
    const div = document.createElement('div');
    div.className = 'myDelegations';
    div.innerHTML = '<h2>My Delegations</h2>';
    document.body.appendChild(div);
    return div;
})();

export async function loadMyDelegations() {
    const userAddr = await signer.getAddress();
    
    delegationsContainer.innerHTML += '<p>Delegations loading...</p>';
}
