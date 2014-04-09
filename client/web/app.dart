import 'dart:html';
import 'dart:convert' show JSON;

DivElement chatBox = querySelector('#chatBox');
InputElement usernameInput = querySelector('#usernameInput');
ButtonElement usernameBtn = querySelector('#usernameBtn');
TextAreaElement msgTextarea = querySelector('#msgTextarea');
ButtonElement msgBtn = querySelector('#msgBtn');
DivElement usernameArea = querySelector('#usernameArea');
DivElement msgArea = querySelector('#msgArea');

class ClientChat {
  WebSocket ws;
  String url;
  String username;
  int messageCounter;
  final int MAX_MESSAGES_TRESHOLD = 100;
  bool max_messages;
  ClientChat(this.url) {
    _init();
  }

  void _init() {
    messageCounter = 0;
    max_messages = false;
    ws = new WebSocket(this.url);
    ws.onOpen.listen((e) {
      print("Connection OK");
    });

    ws.onClose.listen((e) {
      print("Connection CLOSED");
      ParagraphElement wsNotAvail = new ParagraphElement();
      wsNotAvail
          ..text = 'Server offline, impossibile accedere alla chat.'
          ..classes.add("info");

      chatBox
          ..append(wsNotAvail)
          ..scrollTop = chatBox.scrollHeight;
    });

    ws.onMessage.listen((e) {
      Map data = JSON.decode(e.data);
      switch (data["cmd"]) {
        case "setUsername":
          username = data["arg"];
          usernameArea.style
              ..visibility = 'hidden'
              ..display = 'none';

          msgArea.style
              ..visibility = 'visible'
              ..display = 'inline';

          msgTextarea.focus();
          break;

        case "msg":
          DivElement messageWrapper = new DivElement();
          ParagraphElement messageP = new ParagraphElement();
          ParagraphElement userHeader = new ParagraphElement();
          userHeader
              ..text = "[" + data["arg"]["timestamp"] + "] " + data["arg"]["username"] + " dice: "
              ..classes.add("msgHeader");

          messageP
              ..text = data["arg"]["msg"]
              ..classes.add("msg");

          messageWrapper
              ..append(userHeader)
              ..append(messageP);

          chatBox
              ..append(messageWrapper)
              ..scrollTop = chatBox.scrollHeight;

          clean();
          break;

        case "info":
          ParagraphElement messageP = new ParagraphElement();
          messageP
              ..text = "[" + data["arg"]["timestamp"] + "] " + data["arg"]["info"]

              ..classes.add("info");
          chatBox
              ..append(messageP)
              ..scrollTop = chatBox.scrollHeight;
          clean();
          break;
      }
    });
  }

  void send(Map message) {
    ws.send(JSON.encode(message));
  }

  void close() {
    ws.close();
  }

  sendMsg(String msg) {
    send({
      "cmd": "sendMsg",
      "arg": {
        "username": username,
        "msg": msg
      }
    });
  }

  void clean() {
    if (max_messages) {
      chatBox.children.removeAt(0);
      print("Rimuovo");
    } else {
      messageCounter++;
      if (messageCounter == MAX_MESSAGES_TRESHOLD) {
        max_messages = true;
      }
    }
  }
}

main() {
  ClientChat client = new ClientChat('ws://' + window.location.hostname + ':4040/ws');

  usernameInput
      ..focus()
      ..onKeyUp.listen((e) {
        if (e.keyCode == 13 && !e.ctrlKey) {
          usernameBtn.click();
        }
      });

  usernameBtn.onClick.listen((e) {
    if (usernameInput.value.trim().isNotEmpty) {
      client.send({
        "cmd": "setUsername",
        "arg": usernameInput.value
      });
    }
  });

  msgBtn.onClick.listen((e) {
    if (msgTextarea.value.trim().isNotEmpty) {
      client.sendMsg(msgTextarea.value);
      msgTextarea
          ..value = ''
          ..focus();
    }
  });

  msgTextarea.onKeyUp.listen((e) {
    if (e.keyCode == 13 && !e.ctrlKey) {
      msgBtn.click();
    }
  });
}
