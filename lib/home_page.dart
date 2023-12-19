import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String data = '';
  @override
  void initState() {
    askPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text(
          "NFC Tag Reader",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: LoaderOverlay(
          useDefaultLoading: true,
          overlayWidgetBuilder: (v) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          {
                            context.loaderOverlay.show();
                            try {
                              bool isAvailable =
                                  await NfcManager.instance.isAvailable();

                              //We first check if NFC is available on the device.
                              if (isAvailable) {
                                //If NFC is available, start an NFC session and listen for NFC tags to be discovered.
                                NfcManager.instance.startSession(
                                  onError: (err) {
                                    throw err.message;
                                  },
                                  pollingOptions: <NfcPollingOption>{},
                                  onDiscovered: (NfcTag tag) async {
                                    // Process NFC tag, When an NFC tag is discovered, print its data to the console.
                                    debugPrint('NFC Tag Detected: ${tag.data}');
                                  },
                                );
                              } else {
                                debugPrint('NFC not available.');
                                if (mounted) {
                                  context.loaderOverlay.hide();
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                context.loaderOverlay.hide();
                              }
                              debugPrint('Error reading NFC: $e');
                            }
                          }
                          if (mounted) {
                            context.loaderOverlay.hide();
                          }
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 20),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/img_read.png',
                                  height: 40,
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                const Text(
                                  "Read Tags",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        child: InkWell(
                      onTap: () async {
                        context.loaderOverlay.show();
                        getContacts().then((value) {
                          context.loaderOverlay.hide();
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Container(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, top: 15),
                                  height:
                                      MediaQuery.of(context).size.height * .8,
                                  child: ListView.builder(
                                      itemCount: value.length,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () async {
                                            context.loaderOverlay.show();
                                            NfcManager.instance.startSession(
                                                onDiscovered:
                                                    (NfcTag tag) async {
                                              var ndef = Ndef.from(tag);
                                              if (ndef == null ||
                                                  !ndef.isWritable) {
                                                data =
                                                    'Tag is not ndef writable';
                                                NfcManager.instance.stopSession(
                                                    errorMessage: data);
                                                return;
                                              }
                                              NdefMessage message =
                                                  NdefMessage([
                                                NdefRecord.createText(
                                                    "${value[index].name.first} ${value[index].name.middle} ${value[index].name.last}"),
                                                NdefRecord.createUri(Uri.parse(
                                                    'tel:${value[index].phones.first.number}')),
                                              ]);

                                              try {
                                                await ndef.write(message);
                                                data =
                                                    'Success to "Ndef Write"';
                                                NfcManager.instance
                                                    .stopSession();
                                              } catch (e) {
                                                if (mounted) {
                                                  context.loaderOverlay.hide();
                                                }
                                                data = e.toString();
                                                NfcManager.instance.stopSession(
                                                    errorMessage:
                                                        data.toString());
                                                return;
                                              }
                                            });
                                            if (mounted) {
                                              context.loaderOverlay.hide();
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Card(
                                                clipBehavior: Clip.hardEdge,
                                                shape: const StadiumBorder(),
                                                child: value[index]
                                                            .photoOrThumbnail !=
                                                        null
                                                    ? Image.memory(
                                                        value[index]
                                                            .photoOrThumbnail!,
                                                        fit: BoxFit.cover,
                                                        height: 50,
                                                        width: 50,
                                                      )
                                                    : SizedBox(
                                                        height: 50,
                                                        width: 50,
                                                        child: Center(
                                                          child: Text(
                                                            value[index]
                                                                .displayName
                                                                .substring(
                                                                    0, 1),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 30,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                value[index].displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18,
                                                ),
                                              )
                                            ],
                                          ),
                                        );
                                      }),
                                );
                              });
                        });
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 20),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/img_write.png',
                                height: 40,
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              const Text(
                                "Write Contacts",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ))
                  ],
                ),
                InkWell(
                  onTap: onRemove,
                  child: Card(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * .5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 20),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/img_clear.png',
                              height: 40,
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            const Text(
                              "Clear data",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  data,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> askPermission() async {
    if (await FlutterContacts.requestPermission()) {
      await Permission.contacts.request();
    }
  }

  Future<List<Contact>> getContacts() async {
    await askPermission();
    List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: true);
    return contacts;
  }

  Future<void> onRemove() async {
    context.loaderOverlay.show();
    NfcManager.instance.startSession(onDiscovered: (tag) async {
      var ndef = Ndef.from(tag);
      NdefMessage message = NdefMessage([NdefRecord.createText('')]);

      var val = await ndef!.write(message);
      NfcManager.instance.stopSession();
    });
    if (mounted) {
      context.loaderOverlay.hide();
    }
  }
}
