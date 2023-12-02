import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:ndef/ndef.dart' as ndef;
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
                            var tag = await FlutterNfcKit.poll(
                                timeout: const Duration(seconds: 10),
                                iosMultipleTagMessage: "Multiple tags found!",
                                iosAlertMessage: "Scan your tag");
                            if (tag.ndefAvailable ?? false) {
                              for (var record
                                  in await FlutterNfcKit.readNDEFRecords(
                                      cached: false)) {
                                print(record.toString());
                                var d = data + record.basicInfoString;
                                setState(() {
                                  data = d;
                                });
                              }
                              final recordList =
                                  await FlutterNfcKit.readNDEFRawRecords(
                                      cached: false);

                              for (var record in recordList) {
                                var d = data + record.identifier;
                                setState(() {
                                  data = d;
                                });
                              }
                            }
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
                                            try {
                                              var tag = await FlutterNfcKit.poll(
                                                  timeout: const Duration(
                                                      seconds: 10),
                                                  iosMultipleTagMessage:
                                                      "Multiple tags found!",
                                                  iosAlertMessage:
                                                      "Scan your tag");
                                              if (tag.ndefWritable ?? false) {
                                                String contactData =
                                                    "BEGIN:VCARD\nVERSION:3.0\n${value[index].name}\nTEL:${value[index].phones.first.number}\nEMAIL:${value[index].emails.isNotEmpty ? value[index].emails.first : ''}\nEND:VCARD";
                                                await FlutterNfcKit
                                                    .writeNDEFRawRecords([
                                                  NDEFRawRecord(
                                                      '0',
                                                      contactData,
                                                      'String',
                                                      ndef.TypeNameFormat
                                                          .unknown)
                                                ]);
                                              } else {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        'Card is not writable');
                                              }
                                              // await FlutterNfcKit.writeBlock(
                                              //     index, contactData);
                                            } catch (e) {
                                              Fluttertoast.showToast(
                                                  msg: e.toString());
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
    try {
      var tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosMultipleTagMessage: "Multiple tags found!",
          iosAlertMessage: "Scan your tag");
      if (tag.ndefAvailable ?? false) {
        for (var record in await FlutterNfcKit.readNDEFRecords(cached: false)) {
          print(record.toString());
          var d = data + record.basicInfoString;
          setState(() {
            data = d;
          });
        }
        final recordList =
            await FlutterNfcKit.readNDEFRawRecords(cached: false);

        for (int i = 0; i < (recordList.length); i++) {
          recordList.removeAt(i);
        }
        await FlutterNfcKit.writeNDEFRawRecords(recordList);
      } else {
        Fluttertoast.showToast(msg: 'No tags found');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
    if (mounted) {
      context.loaderOverlay.hide();
    }
  }
}
