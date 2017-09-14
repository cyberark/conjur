---
---
//

function extractShellCommand(shellBlock) {
  var blockLines = shellBlock.innerText.split("\n");
  var command = "";

  var includeNextLine = true;

  for(var j = 0; j < blockLines.length; j++) {
    var line = blockLines[j].trim();

    var cmdStart = line.startsWith("$ ");
    var lineBegin = (cmdStart ? 2 : 0);

    var lineBroken = (line.slice(-1) == "\\");
    var lineEnd = (lineBroken ? line.length - 1 : line.length);

    if(cmdStart && command != "") {
      command += " && ";
    }

    if(cmdStart || includeNextLine) {
      command += line.substring(lineBegin, lineEnd);
    }

    includeNextLine = lineBroken;
  }

  return command;
}

function extractIrbCommands(irbBlock) {
  var blockLines = irbBlock.innerText.split("\n");
  var command = "";

  for(var j = 0; j < blockLines.length; j++) {
    var line = blockLines[j];

    if(line.startsWith("irb")) {
      if(command != "") {
        command += "; ";
      }
      command += line.split(" # ")[0].substring(11, line.length);
    }
  }

  return command;
}

function createClipboardButton(block, clipboardText) {
  var btn = document.createElement("button");
  btn.setAttribute("class", "clipboard-button hover-button");
  btn.setAttribute("data-clipboard-text", clipboardText);
  block.parentNode.insertBefore(btn, block);

  var tooltip = document.createElement("span");
  tooltip.setAttribute("class", "tooltip-text arrow_box");
  tooltip.innerHTML = "Copy to clipboard";
  btn.appendChild(tooltip);

  new Clipboard(btn);
}

function getClipboardText(block) {
  var codeType = block.getAttribute("data-lang");

  if(codeType == "shell") {
    return extractShellCommand(block);
  } else if(codeType == "ruby") {
    if(block.innerText.startsWith("irb")) {
      return extractIrbCommands(block);
    } else {
      return block.innerText;
    }
  } else {
    return block.innerText;
  }

  return null;
}

function createClipboardButtons() {
  var codeBlocks = document.querySelectorAll("pre code");

  for(var i = 0; i < codeBlocks.length; i++) {
    var block = codeBlocks[i];
    createClipboardButton(block, getClipboardText(block));
  }
}

function updateClipboardButtons() {
  var buttons = document.getElementsByClassName("clipboard-button");

  [].forEach.call(buttons, function(btn) {
    var clipboardText = getClipboardText(btn.nextSibling);
    btn.setAttribute("data-clipboard-text", clipboardText);
  });
}

createClipboardButtons();
