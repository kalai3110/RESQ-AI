import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/disaster_provider.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/priority_badge.dart';
import 'disaster_details_screen.dart';

class DisasterMapScreen extends StatefulWidget {
  const DisasterMapScreen({super.key});

  @override
  State<DisasterMapScreen> createState() => _DisasterMapScreenState();
}

class _DisasterMapScreenState extends State<DisasterMapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedMarker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisasterProvider>(context, listen: false).fetchMapData();
    });
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final markers = disasterProvider.mapMarkers;
    final shelters = disasterProvider.mapShelters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Disaster Incident Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center Tamil Nadu / Incident Zone',
            onPressed: () {
              _mapController.move(const LatLng(10.7905, 78.7047), 7.5);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => disasterProvider.fetchMapData(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap Tile Canvas
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.7905, 78.7047), // Center of Region
              initialZoom: 7.5,
              minZoom: 5.0,
              maxZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.disaster.ai.assistant',
              ),
              // Disaster Pins Layer
              MarkerLayer(
                markers: markers.map((m) {
                  final lat = (m['latitude'] as num?)?.toDouble() ?? 9.9252;
                  final lng = (m['longitude'] as num?)?.toDouble() ?? 78.1198;
                  final color = _parseHexColor(m['color'] ?? '#E53935');
                  final isSelected = _selectedMarker != null && _selectedMarker!['id'] == m['id'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 52 : 42,
                    height: isSelected ? 52 : 42,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMarker = m;
                        });
                        _mapController.animateTo(LatLng(lat, lng), zoom: 11);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Map Legend Overlay
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Severity Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  _buildLegendItem('Critical (P1)', AppColors.severityCritical),
                  _buildLegendItem('High (P2)', AppColors.severityHigh),
                  _buildLegendItem('Medium (P3)', AppColors.severityMedium),
                  _buildLegendItem('Low (P4)', AppColors.severityLow),
                ],
              ),
            ),
          ),

          // Selected Marker Callout Bottom Sheet Card
          if (_selectedMarker != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _parseHexColor(_selectedMarker!['color'] ?? '#E53935'), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedMarker!['disaster_type']} – ${_selectedMarker!['location']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedMarker = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SeverityBadge(severity: _selectedMarker!['severity'] ?? 'MEDIUM'),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: _selectedMarker!['priority'] ?? 'P3'),
                        const Spacer(),
                        Text(
                          '${_selectedMarker!['people_affected']} Affected',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      '🚑 Rescue Team: ${_selectedMarker!['rescue_team_status']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🏕️ Shelters: ${_selectedMarker!['shelter_availability']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DisasterDetailsScreen(reportId: _selectedMarker!['id']),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _parseHexColor(_selectedMarker!['color'] ?? '#E53935'),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('View Full Disaster Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

extension MapControllerExtension on MapController {
  void animateTo(LatLng destLocation, {double? zoom}) {
    move(destLocation, zoom ?? camera.zoom);
  }
}
