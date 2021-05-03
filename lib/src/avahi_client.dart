import 'dart:async';

import 'package:dbus/dbus.dart';

/// Address protocols.
enum AvahiProtocol { inet, inet6 }

/// Flags used when making lookups.
enum AvahiLookupFlag { useWideArea, useMulticast, noTxt, noAddress }

/// Flags returned in lookup results.
enum AvahiLookupResultFlag {
  cached,
  wideArea,
  multicast,
  local,
  ourOwn,
  static
}

int _encodeAvahiProtocol(AvahiProtocol? protocol) {
  return {AvahiProtocol.inet: 0, AvahiProtocol.inet6: 1}[protocol] ?? -1;
}

AvahiProtocol? _decodeAvahiProtocol(int protocol) {
  return {0: AvahiProtocol.inet, 1: AvahiProtocol.inet6}[protocol];
}

int _encodeAvahiLookupFlags(Set<AvahiLookupFlag> flags) {
  var value = 0;
  for (var flag in flags) {
    value |= {
          AvahiLookupFlag.useWideArea: 0x1,
          AvahiLookupFlag.useMulticast: 0x2,
          AvahiLookupFlag.noTxt: 0x4,
          AvahiLookupFlag.noAddress: 0x8
        }[flag] ??
        0;
  }
  return value;
}

Set<AvahiLookupResultFlag> _decodeAvahiLookupResultFlags(int value) {
  var flags = <AvahiLookupResultFlag>{};
  if (value & 0x01 != 0) {
    flags.add(AvahiLookupResultFlag.cached);
  }
  if (value & 0x02 != 0) {
    flags.add(AvahiLookupResultFlag.wideArea);
  }
  if (value & 0x04 != 0) {
    flags.add(AvahiLookupResultFlag.multicast);
  }
  if (value & 0x08 != 0) {
    flags.add(AvahiLookupResultFlag.local);
  }
  if (value & 0x10 != 0) {
    flags.add(AvahiLookupResultFlag.ourOwn);
  }
  if (value & 0x20 != 0) {
    flags.add(AvahiLookupResultFlag.static);
  }
  return flags;
}

class AvahiAddress {
  /// The protocol [address] uses.
  final AvahiProtocol? protocol;

  /// The address in string form.
  final String address;

  const AvahiAddress(this.address, {this.protocol});

  @override
  String toString() {
    return 'AvahiAddress($address, protocol: $protocol)';
  }
}

class AvahiHostName {
  /// The protocol [name] uses.
  final AvahiProtocol? protocol;

  /// The host name.
  final String name;

  const AvahiHostName(this.name, {this.protocol});

  @override
  String toString() {
    return 'AvahiHostName($name, protocol: $protocol)';
  }
}

/// A result to a resolve host name request.
class AvahiResolveHostNameResult {
  /// The host name that was resolved.
  final AvahiHostName name;

  /// The address that matches [name];
  final AvahiAddress address;

  /// Index of the interface this address is on.
  final int interface;

  /// Flags describing the result.
  final Set<AvahiLookupResultFlag> flags;

  const AvahiResolveHostNameResult(
      {required this.name,
      required this.address,
      required this.interface,
      required this.flags});

  @override
  String toString() {
    return 'AvahiResolveHostNameResult(name: $name, address: $address, interface: $interface, flags: $flags)';
  }
}

/// A result to a resolve address request.
class AvahiResolveAddressResult {
  /// The address that was resolved.
  final AvahiAddress address;

  /// The name that matches [address];
  final AvahiHostName name;

  /// Index of the interface this address is on.
  final int interface;

  /// Flags describing the result.
  final Set<AvahiLookupResultFlag> flags;

  const AvahiResolveAddressResult(
      {required this.address,
      required this.name,
      required this.interface,
      required this.flags});

  @override
  String toString() {
    return 'AvahiResolveAddressResult(address: $address, name: $name, interface: $interface, flags: $flags)';
  }
}

/// A client that connects to Avahi.
class AvahiClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus Avahi object.
  late final DBusRemoteObject _root;

  /// Creates a new Avahi client connected to the system D-Bus.
  AvahiClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root =
        DBusRemoteObject(_bus, 'org.freedesktop.Avahi', DBusObjectPath('/'));
  }

  /// Connects to the Avahi daemon.
  Future<void> connect() async {}

  /// Gets the server version.
  Future<String> getVersionString() async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'GetVersionString', []);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetVersionString returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Gets the API version.
  Future<int> getAPIVersion() async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'GetAPIVersion', []);
    if (result.signature != DBusSignature('u')) {
      throw 'org.freedesktop.Avahi.Server2.GetAPIVersion returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusUint32).value;
  }

  /// Gets the hostname.
  Future<String> getHostName() async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'GetHostName', []);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetHostName returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Sets the hostname.
  Future<void> setHostName(String hostName) async {
    var result = await _root.callMethod(
        'org.freedesktop.Avahi.Server2', 'SetHostName', [DBusString(hostName)]);
    if (result.signature != DBusSignature('')) {
      throw 'org.freedesktop.Avahi.Server2.SetHostName returned invalid result: ${result.returnValues}';
    }
  }

  /// Gets the domain name.
  Future<String> getDomainName() async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'GetDomainName', []);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetDomainName returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Gets the hostname in fully qualified domain name form.
  Future<String> getHostNameFqdn() async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'GetHostNameFqdn', []);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetHostNameFqdn returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Gets an alternative hostname for [name].
  Future<String> getAlternativeHostName(String name) async {
    var result = await _root.callMethod('org.freedesktop.Avahi.Server2',
        'GetAlternativeHostName', [DBusString(name)]);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetAlternativeHostName returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Gets an alternative service name for [name].
  Future<String> getAlternativeServiceName(String name) async {
    var result = await _root.callMethod('org.freedesktop.Avahi.Server2',
        'GetAlternativeServiceName', [DBusString(name)]);
    if (result.signature != DBusSignature('s')) {
      throw 'org.freedesktop.Avahi.Server2.GetAlternativeServiceName returned invalid result: ${result.returnValues}';
    }
    return (result.returnValues[0] as DBusString).value;
  }

  /// Gets the address that matches [name].
  Future<AvahiResolveHostNameResult> resolveHostName(String name,
      {int interface = -1,
      AvahiProtocol? protocol,
      AvahiProtocol? addressProtocol,
      Set<AvahiLookupFlag> flags = const {}}) async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'ResolveHostName', [
      DBusInt32(interface),
      DBusInt32(_encodeAvahiProtocol(protocol)),
      DBusString(name),
      DBusInt32(_encodeAvahiProtocol(addressProtocol)),
      DBusUint32(_encodeAvahiLookupFlags(flags))
    ]);
    if (result.signature != DBusSignature('iisisu')) {
      throw 'org.freedesktop.Avahi.Server2.ResolveHostName returned invalid result: ${result.returnValues}';
    }
    var returnedInterface = (result.returnValues[0] as DBusInt32).value;
    var returnedProtocol =
        _decodeAvahiProtocol((result.returnValues[1] as DBusInt32).value);
    var returnedName = (result.returnValues[2] as DBusString).value;
    var returnedAddressProtocol =
        _decodeAvahiProtocol((result.returnValues[3] as DBusInt32).value);
    var address = (result.returnValues[4] as DBusString).value;
    var resultFlags = _decodeAvahiLookupResultFlags(
        (result.returnValues[5] as DBusUint32).value);
    return AvahiResolveHostNameResult(
        name: AvahiHostName(returnedName, protocol: returnedProtocol),
        address: AvahiAddress(address, protocol: returnedAddressProtocol),
        interface: returnedInterface,
        flags: resultFlags);
  }

  /// Gets the host name that matches [address].
  Future<AvahiResolveAddressResult> resolveAddress(String address,
      {int interface = -1,
      AvahiProtocol? protocol,
      Set<AvahiLookupFlag> flags = const {}}) async {
    var result = await _root
        .callMethod('org.freedesktop.Avahi.Server2', 'ResolveAddress', [
      DBusInt32(interface),
      DBusInt32(_encodeAvahiProtocol(protocol)),
      DBusString(address),
      DBusUint32(_encodeAvahiLookupFlags(flags))
    ]);
    if (result.signature != DBusSignature('iiissu')) {
      throw 'org.freedesktop.Avahi.Server2.ResolveAddress returned invalid result: ${result.returnValues}';
    }
    var returnedInterface = (result.returnValues[0] as DBusInt32).value;
    var returnedProtocol =
        _decodeAvahiProtocol((result.returnValues[1] as DBusInt32).value);
    var returnedAddressProtocol =
        _decodeAvahiProtocol((result.returnValues[2] as DBusInt32).value);
    var returnedAddress = (result.returnValues[3] as DBusString).value;
    var name = (result.returnValues[4] as DBusString).value;
    var resultFlags = _decodeAvahiLookupResultFlags(
        (result.returnValues[5] as DBusUint32).value);
    return AvahiResolveAddressResult(
        address:
            AvahiAddress(returnedAddress, protocol: returnedAddressProtocol),
        name: AvahiHostName(name, protocol: returnedProtocol),
        interface: returnedInterface,
        flags: resultFlags);
  }

  /// Terminates the connection to the Avahi daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
