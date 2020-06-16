// Get the WebGL rendering context
const gl = canvas.getContext('webgl');
gl._setAttribute = (program, type, vname, ...value) => {
  const attribute = gl.getAttribLocation(program, vname)
  gl['vertexAttrib'+type](attribute, ...value);
  return attribute;
}
gl._setUniform = (program, type, vname, ...value) => {
  const uniform = gl.getUniformLocation(program, vname)
  gl['uniform'+type](uniform, ...value);
  return uniform;
}

init(gl);

async function getFetchText(url) {
  const response = await fetch(url);
  return await response.text();
}

async function init() {
  //Load shaders
  const vshader = await getFetchText("vshader.glsl");
  const fshader = await getFetchText("fshader.glsl");
  
  //Initialize Web GL
  const program = compile(gl, vshader, fshader);

  render(program);
}

function render(program) {
  const position = gl.getAttribLocation(program, "aPos");

  gl._setUniform(program, '1f', 'MIN_DIST', 0.0);
  gl._setUniform(program, '1f', 'MAX_DIST', 2000.0);
  gl._setUniform(program, '2f', 'iResolution', canvas.width, canvas.height);
  let eye = [0, 0, -50];
  let phi = Math.PI/2;
  let theta = Math.PI/2;
  let power = 2.0
  const powerRef = gl._setUniform(program, '1f', 'power', 2.0);
  const eyeRef = gl._setUniform(program, '3f', 'eye', ...eye);
  const lookDirRef = gl._setUniform(program, '3f', 'lookDir', 0, 0, 1);
  const inputs = setupInputs();

  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
   -1.0,  1.0, 0, // point 1
    1.0,  1.0, 0, // point 2
   -1.0, -1.0, 0,
    1.0,  1.0, 0, // point 1
    1.0, -1.0, 0, // point 2
   -1.0, -1.0, 0
  ]), gl.STATIC_DRAW);

  gl.enableVertexAttribArray(position);
  
  gl.vertexAttribPointer(
    position,
    3,          // 3 components per iteration
    gl.FLOAT,   // the data is 32bit floats
    false,      // don't normalize the data
    0,          // 0 = move forward size * sizeof(type) each iteration to get the next position
    0,          // start at the beginning of the buffer
  );

  // Set the clear color
  gl.clearColor(0.0, 0.0, 0.0, 1.0);

  // Clear canvas
  gl.clear(gl.COLOR_BUFFER_BIT);

  let oldTime = Date.now();
  let frameCount = 0;
  let totalFrameCount = 0;
  function draw() {
    frameCount++;
    totalFrameCount++;
    if(frameCount > 99) {
      const fps = Math.round(100000/(Date.now() - oldTime));
      document.getElementById("fps").innerText = "FPS: " + fps;
      frameCount = 0;
      oldTime = Date.now();
    }
    

    phi+=inputs.mouseEnabled*(inputs.mouseX/50000);
    theta+=inputs.mouseEnabled*(inputs.mouseY/50000);

    const lookDir = [Math.sin(theta)*Math.cos(phi), Math.cos(theta), Math.sin(theta)*Math.sin(phi)];
    const orthogonalDir = [Math.sin(phi), 0, -Math.cos(phi)]

    for(let i = 0; i < 3; i++){
      eye[i] += (inputs.w - inputs.s) * lookDir[i];
      eye[i] += (inputs.a - inputs.d) * orthogonalDir[i];
    }
    
    eye[1] += inputs[' '] - inputs.Shift;


    //Mandelbulb Animation
    power = (Math.sin(totalFrameCount/2000)*4) + 6;
    gl.uniform1f(powerRef, power);
    document.getElementById("power").innerText = "Power: " + Math.round(100*power)/100;
    

    gl.uniform3f(eyeRef, ...eye);
    gl.uniform3f(lookDirRef, ...lookDir);
    
    gl.drawArrays(
      gl.TRIANGLES,
      0,     // offset
      6,     // num vertices to process
    );
    requestAnimationFrame(draw);
  }
    

  requestAnimationFrame(draw);
}
