export function showNotification(message) {
    const notice = document.createElement('p');
    notice.innerHTML = message;
    document.body.appendChild(notice);
    setTimeout(() => notice.remove(), 4000);
}