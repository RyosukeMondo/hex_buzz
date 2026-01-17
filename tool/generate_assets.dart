/// Asset generation script for HexBuzz
///
/// Connects to Automatic1111's Stable Diffusion WebUI API to generate
/// game assets from text prompts.
///
/// Usage:
///   dart run tool/generate_assets.dart [options]
///
/// Options:
///   --api-url    Base URL for Automatic1111 API (default: http://localhost:7860)
///   --output-dir Output directory for generated assets (default: assets/images)
///   --overwrite  Overwrite existing assets (default: false)
///   --asset      Generate specific asset only (app_icon, level_button, lock_icon, star_filled, star_empty)
///   --help       Show this help message
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Configuration for Stable Diffusion image generation
class SDConfig {
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  final String samplerName;

  const SDConfig({
    this.width = 512,
    this.height = 512,
    this.steps = 20,
    this.cfgScale = 7.0,
    this.samplerName = 'Euler a',
  });

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'steps': steps,
    'cfg_scale': cfgScale,
    'sampler_name': samplerName,
  };
}

/// Asset definition with prompt and negative prompt
class AssetDefinition {
  final String name;
  final String filename;
  final String prompt;
  final String negativePrompt;

  const AssetDefinition({
    required this.name,
    required this.filename,
    required this.prompt,
    required this.negativePrompt,
  });
}

/// Predefined assets from design specification
const List<AssetDefinition> assetDefinitions = [
  AssetDefinition(
    name: 'app_icon',
    filename: 'app_icon.png',
    prompt:
        'hexagonal honeycomb pattern with a cute bee, game app icon, golden amber colors, clean vector style, centered composition, no text, professional mobile game icon',
    negativePrompt: 'blurry, text, words, letters, realistic, photograph',
  ),
  AssetDefinition(
    name: 'level_button',
    filename: 'level_button.png',
    prompt:
        'single hexagonal cell, honeycomb texture, golden honey color, subtle 3D effect, game UI element, clean edges, centered',
    negativePrompt: 'multiple hexagons, bee, text, busy, cluttered',
  ),
  AssetDefinition(
    name: 'lock_icon',
    filename: 'lock_icon.png',
    prompt:
        'padlock icon made of honeycomb pattern, golden amber color, game UI icon, simple clean design, transparent background style',
    negativePrompt: 'realistic, photograph, complex, detailed',
  ),
  AssetDefinition(
    name: 'star_filled',
    filename: 'star_filled.png',
    prompt:
        'five-pointed star icon, golden honey color, game achievement star, clean vector style, slight glow effect, centered',
    negativePrompt: 'realistic, 3D, complex shading',
  ),
  AssetDefinition(
    name: 'star_empty',
    filename: 'star_empty.png',
    prompt:
        'five-pointed star icon outline, gray silver color, empty achievement star, clean vector style, centered, hollow',
    negativePrompt: 'realistic, 3D, complex shading, filled, solid',
  ),
];

/// Client for Automatic1111 Stable Diffusion WebUI API
class SDApiClient {
  final String baseUrl;
  final http.Client _client;

  SDApiClient({required this.baseUrl}) : _client = http.Client();

  /// Check if the API is available
  Future<bool> isAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/sdapi/v1/options'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Generate an image from a text prompt
  Future<List<int>> generateImage({
    required String prompt,
    required String negativePrompt,
    required SDConfig config,
  }) async {
    final uri = Uri.parse('$baseUrl/sdapi/v1/txt2img');

    final body = {
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      ...config.toJson(),
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final images = json['images'] as List<dynamic>;

    if (images.isEmpty) {
      throw Exception('No images returned from API');
    }

    // First image is the generated image (base64 encoded)
    final base64Image = images[0] as String;
    return base64Decode(base64Image);
  }

  void dispose() {
    _client.close();
  }
}

/// Main asset generator
class AssetGenerator {
  final SDApiClient _client;
  final SDConfig _config;
  final String _outputDir;
  final bool _overwrite;

  AssetGenerator({
    required SDApiClient client,
    required String outputDir,
    bool overwrite = false,
    SDConfig? config,
  }) : _client = client,
       _outputDir = outputDir,
       _overwrite = overwrite,
       _config = config ?? const SDConfig();

  /// Generate all assets or a specific asset
  Future<void> generate({String? assetName}) async {
    // Ensure output directory exists
    final outputDir = Directory(_outputDir);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
      print('Created output directory: $_outputDir');
    }

    // Check API availability
    print('Checking Automatic1111 API availability...');
    if (!await _client.isAvailable()) {
      throw Exception(
        'Automatic1111 API is not available at ${_client.baseUrl}\n'
        'Please ensure Stable Diffusion WebUI is running with --api flag.',
      );
    }
    print('API is available.\n');

    // Filter assets if specific asset requested
    final assetsToGenerate = assetName != null
        ? assetDefinitions.where((a) => a.name == assetName).toList()
        : assetDefinitions;

    if (assetsToGenerate.isEmpty) {
      throw Exception(
        'Unknown asset: $assetName\n'
        'Available assets: ${assetDefinitions.map((a) => a.name).join(', ')}',
      );
    }

    // Generate each asset
    for (final asset in assetsToGenerate) {
      await _generateAsset(asset);
    }

    print('\nAsset generation complete!');
  }

  Future<void> _generateAsset(AssetDefinition asset) async {
    final outputPath = '$_outputDir/${asset.filename}';
    final outputFile = File(outputPath);

    // Check if file exists
    if (outputFile.existsSync() && !_overwrite) {
      print('Skipping ${asset.name}: file already exists (use --overwrite)');
      return;
    }

    print('Generating ${asset.name}...');
    print('  Prompt: ${asset.prompt.substring(0, 50)}...');

    try {
      final imageBytes = await _client.generateImage(
        prompt: asset.prompt,
        negativePrompt: asset.negativePrompt,
        config: _config,
      );

      await outputFile.writeAsBytes(imageBytes);
      print('  Saved to: $outputPath (${imageBytes.length} bytes)');
    } catch (e) {
      print('  Error generating ${asset.name}: $e');
      rethrow;
    }
  }
}

void printUsage(ArgParser parser) {
  print('HexBuzz Asset Generator');
  print('');
  print('Generates game assets using Stable Diffusion via Automatic1111 API.');
  print('');
  print('Usage: dart run tool/generate_assets.dart [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Available assets:');
  for (final asset in assetDefinitions) {
    print('  ${asset.name}: ${asset.filename}');
  }
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'api-url',
      abbr: 'u',
      defaultsTo: 'http://localhost:7860',
      help: 'Base URL for Automatic1111 API',
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      defaultsTo: 'assets/images',
      help: 'Output directory for generated assets',
    )
    ..addFlag(
      'overwrite',
      abbr: 'f',
      defaultsTo: false,
      help: 'Overwrite existing assets',
    )
    ..addOption('asset', abbr: 'a', help: 'Generate specific asset only')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      printUsage(parser);
      exit(0);
    }

    final apiUrl = results['api-url'] as String;
    final outputDir = results['output-dir'] as String;
    final overwrite = results['overwrite'] as bool;
    final assetName = results['asset'] as String?;

    print('HexBuzz Asset Generator');
    print('=======================');
    print('API URL: $apiUrl');
    print('Output directory: $outputDir');
    print('Overwrite: $overwrite');
    if (assetName != null) {
      print('Generating asset: $assetName');
    }
    print('');

    final client = SDApiClient(baseUrl: apiUrl);

    try {
      final generator = AssetGenerator(
        client: client,
        outputDir: outputDir,
        overwrite: overwrite,
      );

      await generator.generate(assetName: assetName);
    } finally {
      client.dispose();
    }
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('');
    printUsage(parser);
    exit(1);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
