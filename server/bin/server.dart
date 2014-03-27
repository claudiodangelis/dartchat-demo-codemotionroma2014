import 'dart:io';
import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:math' show Random;
import 'package:intl/intl.dart';

class User {
  WebSocket ws;
  String username;
  User(this.ws, this.username);
}

class ChatHandler {
  Set<User> users = new Set<User>();
  ChatHandler();
  
  void addUser(socket) {
    var rnd = new Random().nextInt(999).toString();
    users.add(new User(socket, 'User'+rnd));
    sendInfo("User${rnd} e' entrato in chat.");
  }
  
  void onData(_data, socket) {
    Map data = JSON.decode(_data);
    switch (data["cmd"]) {
      case "setUsername":
        if (usernameNotExists(data["arg"])) {
          socket.add(JSON.encode({"cmd":"setUsername", "arg":data["arg"]}));
          var user = users.singleWhere((c) => c.ws == socket);
          var _tmp_username = user.username;
          user.username = data["arg"];
          sendInfo(_tmp_username + " e' ora conosciuto come " + data["arg"]);
        } else {
          sendInfo("Oops, lo username esiste gia'", socket);
        }
        break;
        
      case "sendMsg":
        sendMsg(data["arg"]["username"], data["arg"]["msg"]);
        break;
    }
  }
  
  bool usernameNotExists(String username) {
    try {
      users.singleWhere((c) => c.username == username);
      return false;
    } catch (e) {
      return true;
    }
  }
  
  void sendMsg(username, msg) {
    var formatter = new DateFormat('HH:mm:ss');
    users.forEach((user) {
      user.ws.add(JSON.encode({"cmd": "msg", "arg":{"username" : username,
        "msg": msg, "timestamp": formatter.format(new DateTime.now())}}));
    });
  }
  
  void sendInfo(info, [WebSocket socket]) {
    var formatter = new DateFormat('HH:mm:ss');

    var timestamp = formatter.format(new DateTime.now());
    if (socket == null) {
      users.forEach((user) {
        user.ws.add(JSON.encode({"cmd":"info", "arg":{"info":info,
          "timestamp": timestamp}}));
      });
    } else {
      socket.add(JSON.encode({"cmd": "info", "arg":{"info": info,
        "timestamp": timestamp}}));
    }
  }
  
  void onDone(socket) {
    var user = users.singleWhere((c) => c.ws == socket);
    sendInfo("${user.username} ha lasciato la chat.");
    users.remove(user);
  }
}

main() {
  ChatHandler ch = new ChatHandler();
  runZoned(() {
    HttpServer.bind('0.0.0.0', 4040).then((server) {
      server.listen((HttpRequest req) {
        WebSocketTransformer.upgrade(req)
          ..then((socket) {
            ch.addUser(socket);
            socket.listen((data) {
                ch.onData(data, socket);
              },
              onDone: (){
              ch.onDone(socket);
            });
          })
        ..catchError((e) {
          print("Oops, error.");
        });
      });
    });
  });
}
