// TODO: support multi-command blocks by &&-ing them together?
function extractShellCommand(shellBlock) {
  var blockLines = block.innerText.split("\n");
  var command = "";

  for(var j = 0; j < blockLines.length; j++) {
    var line = blockLines[j].trim();
      
    if(line.slice(-1) == "\\") {
      command += line.substring((j == 0 ? 2 : 0), line.length - 1);
    } else {
      command += line.substring((j == 0 ? 2 : 0), line.length);
      break;
    }
  }

  return command;
}

function createClipboardHoverButton(block, text) {
  var btn = document.createElement("button")
  btn.setAttribute("class", "hover-button");
  btn.setAttribute("data-clipboard-text", text);
  block.parentNode.insertBefore(btn, block);
    
  var clipboard = new Clipboard(btn);
}

var shellBlocks = document.getElementsByClassName("language-shell");

for(var i = 0; i < shellBlocks.length; i++) {
  var block = shellBlocks[i];
  var command = extractShellCommand(block.innerText);

  createClipboardHoverButton(block, command);
}
