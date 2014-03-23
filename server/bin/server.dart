import 'dart:io';
import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:math' show Random;

class User {
  WebSocket ws;
  String username;
  User(this.ws, this.username) {
    this.ws.add(JSON.encode({"cmd":"setUsername", "arg":this.username}));
  }
}

class ChatHandler {
  Set<User> users = new Set<User>();
  ChatHandler();
  
  void addUser(socket) {
    var rnd = new Random().nextInt(999).toString();
    users.add(new User(socket, 'User'+rnd));
    sendInfo("User${rnd} e' entrato in chat.");
    print(users.length);
  }
  
  void onData(_data, socket) {
    Map data = JSON.decode(_data);
    switch (data["cmd"]) {
      case "setUsername":
        socket.add(JSON.encode({"cmd":"setUsername", "arg":data["arg"]}));
        var user = users.singleWhere((c) => c.ws == socket);
        var _tmp_username = user.username;
        user.username = data["arg"];
        sendInfo(_tmp_username + " e' ora conosciuto come " + data["arg"]);
        break;
        
      case "sendMsg":
        sendMsg(data["arg"]["username"] + ": " + data["arg"]["msg"]);
        break;
    }
  }
  
  void sendMsg(data) {
    print(data);
    users.forEach((user) {
      user.ws.add(JSON.encode({"cmd":"msg","arg":data}));
    });
  }
  
  void sendInfo(info) {
    print(info);
    users.forEach((user) {
      user.ws.add(JSON.encode({"cmd":"info","arg":info}));
    });
  }
  
  void onDone(socket) {
    var user = users.singleWhere((c) => c.ws == socket);
    sendInfo("${user.username} ha lasciato la chat");
    users.remove(user);
  }
  
}

main() {
  ChatHandler ch = new ChatHandler();
  runZoned(() {
    HttpServer.bind('0.0.0.0', 4040).then((server) {
      server.listen((HttpRequest req) {
        print("Nuova richiesta HTTP");
        if (req.uri.path == '/ws') {
          print("Nuova richiesta WS");
          WebSocketTransformer.upgrade(req).then((socket) {
            ch.addUser(socket);
            socket.listen((data) {
                ch.onData(data, socket);
              },
              onDone: (){
              ch.onDone(socket);
            });
          });
        }
      });
    });
  });
}
