import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:avahi/avahi.dart';

class MockAvahiHost {
  final String address;
  final String name;

  const MockAvahiHost({required this.address, required this.name});
}

class MockAvahiRoot extends DBusObject {
  final MockAvahiServer server;

  MockAvahiRoot(this.server) : super(DBusObjectPath('/'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.Avahi.Server2') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'GetAlternativeHostName':
        var name = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse([DBusString('$name-2')]);
      case 'GetAlternativeServiceName':
        var name = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse([DBusString('$name #2')]);
      case 'GetAPIVersion':
        return DBusMethodSuccessResponse([DBusUint32(server.apiVersion)]);
      case 'GetDomainName':
        return DBusMethodSuccessResponse([DBusString(server.domainName)]);
      case 'GetHostName':
        return DBusMethodSuccessResponse([DBusString(server.hostName)]);
      case 'GetHostNameFqdn':
        return DBusMethodSuccessResponse([DBusString(server.hostNameFqdn)]);
      case 'GetVersionString':
        return DBusMethodSuccessResponse([DBusString(server.versionString)]);
      case 'ResolveAddress':
        var address = (methodCall.values[2] as DBusString).value;
        var host = server.findHostByAddress(address);
        if (host == null) {
          return DBusMethodErrorResponse.failed();
        }
        return DBusMethodSuccessResponse([
          DBusInt32(0),
          DBusInt32(0),
          DBusInt32(0),
          DBusString(host.address),
          DBusString(host.name),
          DBusUint32(0)
        ]);
      case 'ResolveHostName':
        var name = (methodCall.values[2] as DBusString).value;
        var host = server.findHostByName(name);
        if (host == null) {
          return DBusMethodErrorResponse.failed();
        }
        return DBusMethodSuccessResponse([
          DBusInt32(0),
          DBusInt32(0),
          DBusString(host.name),
          DBusInt32(0),
          DBusString(host.address),
          DBusUint32(0)
        ]);
      case 'SetHostName':
        server.hostName = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockAvahiServer extends DBusClient {
  late final MockAvahiRoot _root;

  int apiVersion;
  String domainName;
  String hostName;
  String hostNameFqdn;
  List<MockAvahiHost> hosts;
  final String versionString;

  MockAvahiServer(DBusAddress clientAddress,
      {this.apiVersion = 0,
      this.domainName = '',
      this.hostName = '',
      this.hostNameFqdn = '',
      this.hosts = const [],
      this.versionString = ''})
      : super(clientAddress);

  MockAvahiHost? findHostByName(String name) {
    for (var host in hosts) {
      if (host.name == name) {
        return host;
      }
    }
  }

  MockAvahiHost? findHostByAddress(String address) {
    for (var host in hosts) {
      if (host.address == address) {
        return host;
      }
    }
  }

  Future<void> start() async {
    await requestName('org.freedesktop.Avahi');
    _root = MockAvahiRoot(this);
    await registerObject(_root);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, versionString: '1.2.3');
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getVersionString(), equals('1.2.3'));

    await client.close();
  });

  test('api version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, apiVersion: 512);
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getAPIVersion(), equals(512));

    await client.close();
  });

  test('get hostname', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, hostName: 'foo');
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getHostName(), equals('foo'));

    await client.close();
  });

  test('set hostname', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, hostName: 'foo');
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    await client.setHostName('bar');
    expect(avahi.hostName, equals('bar'));

    await client.close();
  });

  test('get domain name', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, domainName: 'local');
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getDomainName(), equals('local'));

    await client.close();
  });

  test('get hostname fqdn', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress, hostNameFqdn: 'foo.local');
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getHostNameFqdn(), equals('foo.local'));

    await client.close();
  });

  test('get alternative hostname', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress);
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getAlternativeHostName('foo'), equals('foo-2'));

    await client.close();
  });

  test('get alternative service name', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress);
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getAlternativeServiceName('foo'), equals('foo #2'));

    await client.close();
  });

  test('resolve host name', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress,
        hosts: [MockAvahiHost(address: '192.168.1.1', name: 'foo.local')]);
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    var result = await client.resolveHostName('foo.local');
    expect(result.address.address, equals('192.168.1.1'));

    await client.close();
  });

  test('resolve address', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var avahi = MockAvahiServer(clientAddress,
        hosts: [MockAvahiHost(address: '192.168.1.1', name: 'foo.local')]);
    await avahi.start();

    var client = AvahiClient(bus: DBusClient(clientAddress));
    await client.connect();

    var result = await client.resolveAddress('192.168.1.1');
    expect(result.name.name, equals('foo.local'));

    await client.close();
  });
}
