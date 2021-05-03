import 'package:avahi/avahi.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Missing address to lookup');
    return;
  }
  var address = args[0];

  var client = AvahiClient();
  await client.connect();

  var result = await client.resolveAddress(address);
  print('${result.address.address}\t${result.name.name}');

  await client.close();
}
