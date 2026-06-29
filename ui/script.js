let currentNumber = 0;
let timer = null;
const duration = 2000; // Each number stays on screen for 2 seconds (2000ms)
let startTime = 0;

window.addEventListener('message', function(event) {
    let item = event.data;
    if (item.action === "start_minigame") {
        document.getElementById('minigame-container').style.display = 'block';
        document.getElementById('current-score').innerText = item.score;
        nextNumber();
    } else if (item.action === "update_score") {
        document.getElementById('current-score').innerText = item.score;
        nextNumber();
    } else if (item.action === "stop_minigame") {
        document.getElementById('minigame-container').style.display = 'none';
        clearInterval(timer);
    }
});

function nextNumber() {
    clearInterval(timer);
    
    // 1. Generate a random number between 1 and 7
    currentNumber = Math.floor(Math.random() * 7) + 1;
    document.getElementById('number-box').innerText = currentNumber;
    
    // 2. Relocate the widget to a completely random position on the screen (between 15% and 75%)
    let widget = document.getElementById('game-widget');
    let randomTop = Math.floor(Math.random() * 60) + 15;
    let randomLeft = Math.floor(Math.random() * 60) + 15;
    
    widget.style.top = randomTop + "%";
    widget.style.left = randomLeft + "%";

    // 3. Reset the countdown progress bar
    let fill = document.getElementById('progress-fill');
    fill.style.width = '100%';
    
    startTime = Date.now();
    
    timer = setInterval(() => {
        let elapsed = Date.now() - startTime;
        let percentage = 100 - (elapsed / duration * 100);
        if (percentage <= 0) {
            clearInterval(timer);
            // Time ran out before pressing the key -> trigger fail
            fetch(`https://${GetParentResourceName()}/failed`, {method: 'POST'});
        } else {
            fill.style.width = percentage + '%';
        }
    }, 50);
}

// Listen for top horizontal number row only via event.code
window.addEventListener('keydown', function(event) {
    // Top row horizontal numbers are mapped as 'Digit1' through 'Digit7'.
    // Numpad inputs will be completely ignored since they register as 'Numpad1', etc.
    const validCodes = ['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7'];
    
    if (validCodes.includes(event.code)) {
        // Extract the actual numerical value (e.g., 'Digit5' becomes 5)
        let pressedNumber = parseInt(event.code.replace('Digit', ''));
        
        if (pressedNumber === currentNumber) {
            fetch(`https://${GetParentResourceName()}/success`, {method: 'POST'});
        } else {
            fetch(`https://${GetParentResourceName()}/failed`, {method: 'POST'});
        }
    }
});