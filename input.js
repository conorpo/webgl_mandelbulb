function setupInputs() {
    const inputs = {Shift: 0, s: 0, a: 0, ' ': 0, w: 0, d: 0, mouseY: 0, mouseX: 0, mouseEnabled: 0}

    const canvas = document.getElementById("canvas");
    const rect = canvas.getBoundingClientRect();
    canvas.addEventListener("mousedown", evt => {
        inputs.mouseEnabled = 1;
    });
    canvas.addEventListener("mouseup", evt => {
        inputs.mouseEnabled = 0;
    });
    canvas.addEventListener("mousemove", evt => {
        inputs.mouseX = (evt.clientX - rect.left) - rect.width/2;
        inputs.mouseY = (evt.clientY - rect.top) - rect.height/2;
    })

    document.addEventListener("keydown", evt => {
        if(inputs[evt.key] != undefined) {
            inputs[evt.key] = 0.1; //move speed
        }

    }, false);
    document.addEventListener("keyup", evt => {
        if(inputs[evt.key] != undefined) {
            inputs[evt.key] = 0;
        }

    }, false);
    return inputs;
    
}
