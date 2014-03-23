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

class Connection {
  WebSocket ws;
  String url;
  String username;
  Connection(this.url) {
    _init();
  }
  
  void _init() {
    ws = new WebSocket(this.url);
    ws.onOpen.listen((e) {
      print("Connection OK");
    });
    
    ws.onClose.listen((e) {
      print("Connection CLOSED");
    });
    
    ws.onMessage.listen((e) {
      Map data = JSON.decode(e.data);
      switch(data["cmd"]) {
        case "setUsername":
          this.username = data["arg"];
          inputUsername.value = this.username;
          break;
          
        case "msg":
          ParagraphElement newP = new ParagraphElement();
          newP.text = data["arg"];
          newP.classes.add("msg");
          chatBox.append(newP);
          chatBox.scrollTop = chatBox.scrollHeight;
          break;
          
        case "info":
          ParagraphElement newP = new ParagraphElement();
          newP.text = data["arg"];
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
  Connection conn = new Connection('ws://' + window.location.host +  ':4040/ws');
  
  btnUsername.onClick.listen((e) {
    if (inputUsername.value.isNotEmpty) {
      conn.send({"cmd":"setUsername", "arg":inputUsername.value});
    }
  });
  
  btnMsg.onClick.listen((e) {
    conn.sendMsg(msg.value);
    msg
      ..value = ''
      ..focus();
  });
  
  msg.onKeyUp.listen((e) {
    if (e.keyCode == 13 && !e.ctrlKey) {
      btnMsg.click();
    }
  });
}
