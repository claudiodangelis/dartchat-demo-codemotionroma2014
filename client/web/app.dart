import 'dart:html';
import 'dart:convert' show JSON;
// Debug:
import 'dart:async';
import 'dart:math' show Random;

DivElement chatBox = querySelector('#chatBox');
InputElement inputUsername = querySelector('#username');
ButtonElement btnUsername = querySelector('#btnUsername');
TextAreaElement msg = querySelector('#msg');
ButtonElement btnMsg = querySelector('#btnMsg');
DivElement usernameArea = querySelector('#usernameArea');
DivElement msgArea = querySelector('#msgArea');

class ClientChat {
  WebSocket ws;
  String url;
  String username;
  ClientChat(this.url) {
    _init();
  }
  
  void _init() {
    ws = new WebSocket(this.url);
    ws.onOpen.listen((e) {
      print("Connection OK");
    });
    
    ws.onClose.listen((e) {
      print("Connection CLOSED");
      ParagraphElement wsNotAvail = new ParagraphElement();
      wsNotAvail.text = 'Impossibile accedere alla chat. Il tuo browser non supporta WebSocket oppure il server è offline';
      wsNotAvail.classes.add("info");
      chatBox.append(wsNotAvail);
    });
    
    ws.onMessage.listen((e) {
      Map data = JSON.decode(e.data);
      switch(data["cmd"]) {
        case "setUsername":
          this.username = data["arg"];
          usernameArea.style
            ..visibility = 'hidden'
            ..display = 'none';
          
          msgArea.style
            ..visibility = 'visible'
            ..display = 'inline';
          
          msg.focus();
          break;
          
        case "msg":
          ParagraphElement newP = new ParagraphElement();
          ParagraphElement header = new ParagraphElement();
          header.text = "[" + data["arg"]["timestamp"] + "] " + data["arg"]["username"] + " dice: ";
          header.classes.add("msgHeader");
          newP.text = data["arg"]["msg"];
          print(data["arg"]["timestamp"]);
          newP.classes.add("msg");
          chatBox.append(header);
          chatBox.append(newP);
          chatBox.scrollTop = chatBox.scrollHeight;
          break;
          
        case "info":
          ParagraphElement newP = new ParagraphElement();
          newP.text = "[" + data["arg"]["timestamp"] + "] " + data["arg"]["info"];
          newP.classes.add("info");
          chatBox.append(newP);
          chatBox.scrollTop = chatBox.scrollHeight;
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
    send({"cmd":"sendMsg","arg":{"username":this.username,"msg":msg}});
  }
}

main() {
  ClientChat client = new ClientChat('ws://' + window.location.hostname +  ':4040/ws');
  inputUsername
    ..focus()
    ..onKeyUp.listen((e) {
      if (e.keyCode == 13 && !e.ctrlKey) {
        btnUsername.click();
      }
    });
  
  btnUsername.onClick.listen((e) {
    if (inputUsername.value.trim().isNotEmpty) {
      client.send({"cmd":"setUsername", "arg":inputUsername.value});
    }
  });
  
  btnMsg.onClick.listen((e) {
    if (msg.value.trim().isNotEmpty) {
      client.sendMsg(msg.value);
      msg
        ..value = ''
        ..focus();
    }
  });
  
  msg.onKeyUp.listen((e) {
    if (e.keyCode == 13 && !e.ctrlKey) {
      btnMsg.click();
    }
  });
}
