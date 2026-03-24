import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _controller = TextEditingController();

  String _selectedFullAddress = '';
  double? _latitude;
  double? _longitude;
  Map<String, String> _addressParts = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Address Autocomplete (India)"),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Start typing your address...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              // ── Main Autocomplete Widget ──
              GooglePlaceAutoCompleteTextField(
                textEditingController: _controller,
                googleAPIKey: "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM",
                inputDecoration: InputDecoration(
                  hintText: "House no., Street, Area, City, Pincode",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                debounceTime: 600,
                countries: const ["in"],
                isLatLngRequired:
                    true, // ← this must be true to populate .lat & .lng
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  setState(() {
                    _latitude = double.tryParse(prediction.lat ?? '');
                    _longitude = double.tryParse(prediction.lng ?? '');
                    _selectedFullAddress = prediction.description ?? '';
                  });

                  _parseAddress(prediction);
                },
                itemClick: (Prediction prediction) {
                  _controller.text = prediction.description ?? '';
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                },
                seperatedBuilder: const Divider(),
                isCrossBtnShown: true,
              ),

              const SizedBox(height: 32),

              // ── Results ──
              if (_selectedFullAddress.isNotEmpty) ...[
                const Text(
                  "Selected Address:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFullAddress,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Divider(height: 24),
                        if (_latitude != null && _longitude != null)
                          Text(
                            "Coordinates: $_latitude, $_longitude",
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        const SizedBox(height: 12),
                        ..._addressParts.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    "${e.key}:",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                    child:
                                        Text(e.value.isEmpty ? '—' : e.value)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _parseAddress(Prediction p) {
    _addressParts.clear();

    final desc = p.description ?? '';
    final parts = desc.split(', ');

    if (parts.length >= 3) {
      _addressParts["Full"] = desc;
      _addressParts["City"] = parts[parts.length - 3].trim();
      _addressParts["State"] = parts[parts.length - 2].trim();

      final last = parts.last.trim();
      if (RegExp(r'^\d{6}$').hasMatch(last)) {
        _addressParts["Pincode"] = last;
        // Remove pincode from state if it was wrongly parsed there
        if (_addressParts["State"]?.contains(last) == true) {
          _addressParts["State"] = parts[parts.length - 3].trim(); // fallback
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
