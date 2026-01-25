import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;

import 'package:steamworks/steamworks.dart' as windows;
import 'package:steamworks_linux/steamworks.dart' as linux;
import 'package:steamworks_macos/steamworks.dart' as macos;

Future<String> getAuthSessionTicket() async {
  var client = http.Client();
  var response = await client.get(
      Uri.parse('http://host.docker.internal:3001/token/1016950'));
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse['token'];
}

String getAuthCode() {
  var ticket =  '';
  using((arena) {
    Pointer<UnsignedInt> ticketLength = calloc<UnsignedInt>();
    Pointer<Void> pTicket = calloc.allocate(1024);

    if (Platform.isLinux) {
      linux.SteamClient.init();
      linux.SteamClient steamClient = linux.SteamClient.instance;
      steamClient.steamUser.getAuthSessionTicket(pTicket, 1024, ticketLength);
    } else if (Platform.isWindows) {
      windows.SteamClient.init();
      windows.SteamClient steamClient = windows.SteamClient.instance;
      steamClient.steamUser.getAuthSessionTicket(pTicket, 1024, ticketLength);
    } else {
      macos.SteamClient.init();
      macos.SteamClient steamClient = macos.SteamClient.instance;
      steamClient.steamUser.getAuthSessionTicket(pTicket, 1024, ticketLength);
    }

    var length = ticketLength.value;

    for (var i = 0; i < length; i++) {
      var value = pTicket.cast<Uint8>().elementAt(i).value;
      var hexString = value.toRadixString(16);
      if (hexString.length == 1) {
        hexString = '0$hexString' ;
      }
      ticket = ticket + hexString;
    }
  });
  return ticket.toUpperCase();
}