import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iapetus/iapetus.dart';
import 'package:iapetus/iapetus_data.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DecrypterScreen(),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}

class DecrypterScreen extends StatefulWidget {
  const DecrypterScreen({super.key});

  @override
  State<DecrypterScreen> createState() => _DecrypterScreenState();
}

class _DecrypterScreenState extends State<DecrypterScreen> {
  static const _partners = [
    androidPartner,
    androidLegacyPartner, // ignore: deprecated_member_use
    iosPartner,
    palmPartner,
    windowsMobilePartner,
    desktopAirClientPartner,
    vistaWidgetPartner,
  ];

  var _selectedPartner = _partners[0];
  var _request = true;
  var _removeBoilerplate = true;
  late Converter<String, Uint8List> _decrypter;
  String? _encryptedData;
  String? _output;

  late final TextEditingController _textFieldController;

  @override
  void initState() {
    super.initState();
    _updateDecrypter();
    _textFieldController = TextEditingController();
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  void _updateDecrypter() {
    _decrypter = buildPandoraDecrypter(
      _request
          ? _selectedPartner.requestEncryptKey
          : _selectedPartner.responseEncryptKey,
    );
  }

  void _decrypt() {
    if (_encryptedData?.isNotEmpty != true) {
      _output = null;
      return;
    }

    final String decryptedData;
    try {
      decryptedData = pandoraDecrypt(_encryptedData!, _decrypter);
    } on FormatException catch (e) {
      _output = 'Could not decrypt! Check your settings.\nDetails: $e';
      return;
    }

    final Object? decryptedJson;
    try {
      decryptedJson = jsonDecode(decryptedData);
    } on FormatException {
      _output = decryptedData;
      return;
    }

    if (_removeBoilerplate && decryptedJson is Map<String, dynamic>) {
      decryptedJson
        ..remove('syncTime')
        ..remove('userAuthToken')
        ..remove('deviceProperties');
    }

    _output = const JsonEncoder.withIndent('  ').convert(decryptedJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pandora JSON API Decrypter by hacker1024'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _ModeSelector(
            partners: _partners,
            selectedPartner: _selectedPartner,
            request: _request,
            removeBoilerplate: _removeBoilerplate,
            onPartnerSelection: (partner) => setState(() {
              _selectedPartner = partner;
              _updateDecrypter();
              _decrypt();
            }),
            onRequestToggle: (request) => setState(() {
              _request = request;
              _updateDecrypter();
              _decrypt();
            }),
            onRemoveBoilerplateToggle: (removeBoilerplate) => setState(() {
              _removeBoilerplate = removeBoilerplate;
              _decrypt();
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Encrypted data',
            ),
            keyboardType: TextInputType.multiline,
            maxLines: null,
            onChanged: (value) {
              setState(() {
                _encryptedData = value;
                _decrypt();
              });
            },
          ),
          const SizedBox(height: 8),
          if (_output?.isNotEmpty == true)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  _output!,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontFamily: 'monospace',
                    fontFamilyFallback: [
                      'Monaco',
                      'Courier New',
                      'Noto Mono',
                      'Roboto Mono',
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final List<Partner> partners;
  final Partner selectedPartner;
  final bool request;
  final bool removeBoilerplate;
  final ValueChanged<Partner> onPartnerSelection;
  final ValueChanged<bool> onRequestToggle;
  final ValueChanged<bool> onRemoveBoilerplateToggle;

  const _ModeSelector({
    required this.partners,
    required this.selectedPartner,
    required this.request,
    required this.removeBoilerplate,
    required this.onPartnerSelection,
    required this.onRequestToggle,
    required this.onRemoveBoilerplateToggle,
  });

  Widget _buildPartnerSelector(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Partner',
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Partner>(
          isDense: true,
          value: selectedPartner,
          items: partners
              .map(
                (partner) => DropdownMenuItem(
                  value: partner,
                  child: Text(partner.username),
                ),
              )
              .toList(growable: false),
          onChanged: (partner) {
            if (partner != null) onPartnerSelection(partner);
          },
        ),
      ),
    );
  }

  Widget _buildRequestToggle(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Direction',
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          isDense: true,
          value: request,
          items: const [
            DropdownMenuItem(value: true, child: Text('Request')),
            DropdownMenuItem(value: false, child: Text('Response')),
          ],
          onChanged: (request) {
            if (request != null) onRequestToggle(request);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(
                children: [
                  _buildPartnerSelector(context),
                  const SizedBox(height: 8),
                  _buildRequestToggle(context),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildPartnerSelector(context)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildRequestToggle(context)),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Settings',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: CheckboxListTile(
            title: const Text('Remove common fields'),
            subtitle: const Text(
                'Removes JSON fields like syncTime, userAuthToken and deviceProperties'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: removeBoilerplate,
            onChanged: (value) {
              if (value != null) onRemoveBoilerplateToggle(value);
            },
          ),
        )
      ],
    );
  }
}
