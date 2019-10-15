import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class BitmapDescriptor {
  const BitmapDescriptor._(this._json);

  static const double hueRed = 0.0;
  static const double hueOrange = 30.0;
  static const double hueYellow = 60.0;
  static const double hueGreen = 120.0;
  static const double hueCyan = 180.0;
  static const double hueAzure = 210.0;
  static const double hueBlue = 240.0;
  static const double hueViolet = 270.0;
  static const double hueMagenta = 300.0;
  static const double hueRose = 330.0;

  /// Creates a BitmapDescriptor that refers to the default marker image.
  static const BitmapDescriptor defaultMarker =
      BitmapDescriptor._(<dynamic>['defaultMarker']);

  /// Creates a BitmapDescriptor that refers to a colorization of the default
  /// marker image. For convenience, there is a predefined set of hue values.
  /// See e.g. [hueYellow].
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    assert(0.0 <= hue && hue < 360.0);
    return BitmapDescriptor._(<dynamic>['defaultMarker', hue]);
  }

  /// Creates a BitmapDescriptor using the name of a bitmap image in the assets
  /// directory.
  ///
  /// Use [fromAssetImage]. This method does not respect the screen dpi when
  /// picking an asset image.
  @Deprecated("Use fromAssetImage instead")
  static BitmapDescriptor fromAsset(String assetName, {String package}) {
    if (package == null) {
      return BitmapDescriptor._(<dynamic>['fromAsset', assetName]);
    } else {
      return BitmapDescriptor._(<dynamic>['fromAsset', assetName, package]);
    }
  }

  /// Creates a [BitmapDescriptor] from an asset image.
  ///
  /// Asset images in flutter are stored per:
  /// https://flutter.dev/docs/development/ui/assets-and-images#declaring-resolution-aware-image-assets
  /// This method takes into consideration various asset resolutions
  /// and scales the images to the right resolution depending on the dpi.
  static Future<BitmapDescriptor> fromAssetImage(
    ImageConfiguration configuration,
    String assetName, {
    AssetBundle bundle,
    String package,
  }) async {
    if (configuration.devicePixelRatio != null) {
      return BitmapDescriptor._(<dynamic>[
        'fromAssetImage',
        assetName,
        configuration.devicePixelRatio,
      ]);
    }
    final AssetImage assetImage =
        AssetImage(assetName, package: package, bundle: bundle);
    final AssetBundleImageKey assetBundleImageKey =
        await assetImage.obtainKey(configuration);

    if (configuration.size != null) {
      return BitmapDescriptor._(<dynamic>[
        'fromAssetImage',
        assetBundleImageKey.name,
        configuration.size.width.toString(),
        configuration.size.height.toString(),
      ]);
    }

    return BitmapDescriptor._(<dynamic>[
      'fromAssetImage',
      assetBundleImageKey.name,
      assetBundleImageKey.scale.toString(),
    ]);
  }

  /// Creates a BitmapDescriptor using an array of bytes that must be encoded
  /// as PNG.
  static BitmapDescriptor fromBytes(Uint8List byteData) {
    return BitmapDescriptor._(<dynamic>['fromBytes', byteData]);
  }

  final dynamic _json;

  dynamic toMap() => _json;
}
