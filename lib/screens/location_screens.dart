import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../providers.dart';
import '../services.dart';

import '../widgets.dart';

/// Pick the exact delivery location on a map, then save it as an address.
class LocationPickerScreen extends ConsumerStatefulWidget {
  final AddressModel? existing;
  const LocationPickerScreen({super.key, this.existing});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _map;
  LatLng _initial = const LatLng(30.9689, 73.3343);
  LatLng? _center;
  bool _ready = false;
  bool _moving = false;
  bool _permitted = false;
  bool _locating = false;
  bool _geocoding = false;
  bool _saving = false;
  String _detected = '';
  String _area = '';
  String _label = 'Home';
  Timer? _debounce;

  final _house = TextEditingController();
  final _landmark = TextEditingController();
  final _phone = TextEditingController();

  SettingsModel get _settings =>
      ref.read(settingsProvider).valueOrNull ?? SettingsModel();

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    if (a != null) {
      _house.text = a.houseNumber;
      _landmark.text = a.landmark ?? '';
      _phone.text = a.phone;
      _label = a.label;
      _detected = a.street;
      _area = a.area;
      if (a.lat != 0) {
        _initial = LatLng(a.lat, a.lng);
        _center = _initial;
        _ready = true;
        return;
      }
    } else {
      _phone.text = ref.read(userProfileProvider).valueOrNull?.phone ?? '';
    }
    _resolveInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _map?.dispose();
    _house.dispose();
    _landmark.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _resolveInitial() async {
    final s = _settings;
    LatLng start = LatLng(s.restaurantLat, s.restaurantLng);
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      start = LatLng(pos.latitude, pos.longitude);
      _permitted = true;
    }
    if (!mounted) return;
    setState(() {
      _initial = start;
      _center = start;
      _ready = true;
    });
    _reverse(start);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos == null) {
      Helpers.error(
        context,
        'Could not get your location. Turn on GPS and allow location permission.',
      );
      return;
    }
    setState(() => _permitted = true);
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 17),
    );
  }

  Future<void> _reverse(LatLng p) async {
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final list = await placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );
      if (list.isNotEmpty) {
        final m = list.first;
        final parts = [m.street, m.subLocality, m.locality]
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList();
        _detected = parts.join(', ');
        _area = (m.subLocality != null && m.subLocality!.trim().isNotEmpty)
            ? m.subLocality!
            : (m.locality ?? '');
      }
    } catch (_) {
      // Address text is optional; the pin itself is what matters.
    }
    if (mounted) setState(() => _geocoding = false);
  }

  double _distanceKm(LatLng p) {
    final s = _settings;
    return Geolocator.distanceBetween(
          s.restaurantLat,
          s.restaurantLng,
          p.latitude,
          p.longitude,
        ) /
        1000;
  }

  Future<void> _save() async {
    final uid = AuthService.uid;
    final c = _center ?? _initial;
    if (uid == null) {
      context.push('/login');
      return;
    }
    if (_house.text.trim().isEmpty) {
      Helpers.error(context, 'Please enter your house / flat number');
      return;
    }
    if (Validators.phone(_phone.text.trim()) != null) {
      Helpers.error(context, 'Please enter a valid phone number');
      return;
    }
    setState(() => _saving = true);
    try {
      final list = ref.read(addressesProvider).valueOrNull ?? [];
      final a = AddressModel(
        id: widget.existing?.id ?? '',
        label: _label,
        houseNumber: _house.text.trim(),
        street: _detected,
        area: _area.isEmpty ? 'Pinned location' : _area,
        landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
        phone: _phone.text.trim(),
        lat: c.latitude,
        lng: c.longitude,
        isDefault: widget.existing?.isDefault ?? list.isEmpty,
      );
      if (widget.existing == null) {
        await FirestoreService.addAddress(uid, a);
      } else {
        await FirestoreService.updateAddress(uid, a.id, a);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    final point = _center ?? _initial;
    final km = _distanceKm(point);
    final outside = km > s.deliveryRadiusKm;
    final maxPanel = MediaQuery.of(context).size.height * 0.55;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Choose delivery location'
              : 'Edit location',
        ),
      ),
      body: !_ready
          ? const AppLoading()
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initial,
                          zoom: 16.5,
                        ),
                        onMapCreated: (c) => _map = c,
                        onCameraMove: (pos) {
                          _center = pos.target;
                          if (!_moving) setState(() => _moving = true);
                        },
                        onCameraIdle: () {
                          if (_moving) setState(() => _moving = false);
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () => _reverse(_center ?? _initial),
                          );
                        },
                        myLocationEnabled: _permitted,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        circles: {
                          Circle(
                            circleId: const CircleId('area'),
                            center: LatLng(s.restaurantLat, s.restaurantLng),
                            radius: s.deliveryRadiusKm * 1000,
                            strokeColor: AppColors.primary,
                            strokeWidth: 2,
                            fillColor: AppColors.primary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('restaurant'),
                            position: LatLng(s.restaurantLat, s.restaurantLng),
                            infoWindow: const InfoWindow(
                              title: AppStrings.appName,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                          ),
                        },
                      ),
                      // Center pin
                      IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 200),
                              offset: Offset(0, _moving ? -0.25 : 0),
                              child: const Icon(
                                Icons.location_pin,
                                size: 54,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'myloc',
                          backgroundColor: Colors.white,
                          onPressed: _locating ? null : _goToMyLocation,
                          child: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: AppColors.primary,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    boxShadow: softShadow(0.14),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxPanel),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _geocoding
                                        ? 'Finding address...'
                                        : _detected.isEmpty
                                        ? 'Move the map to place the pin on your door'
                                        : _detected,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelBold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (outside)
                              InfoBanner(
                                'Sorry, this spot is ${km.toStringAsFixed(1)} km away. We deliver within ${s.deliveryRadiusKm.toStringAsFixed(0)} km of the restaurant.',
                                color: AppColors.error,
                                icon: Icons.wrong_location_outlined,
                              ).animate().fadeIn().shake(
                                hz: 3,
                                duration: 400.ms,
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Within delivery area (${km.toStringAsFixed(1)} km)',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final l in ['Home', 'Work', 'Other'])
                                  ChoiceChip(
                                    label: Text(l),
                                    selected: _label == l,
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _label = l),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'House / flat / street no.',
                              controller: _house,
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Landmark (optional)',
                              controller: _landmark,
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Phone number',
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Confirm location',
                              icon: Icons.check,
                              isLoading: _saving,
                              onPressed: outside ? null : _save,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}