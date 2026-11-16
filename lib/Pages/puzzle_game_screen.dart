/// Easy picture puzzle for the Calm Attack application.
///
/// A calm sunset picture is cut into a 3 x 3 grid and shuffled. The user
/// taps two tiles to swap them until the picture is whole again.
/// Tiles already in the right place get a soft check so progress is easy
/// to see.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../Animations/sunset_bloom.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/exercise_layout.dart';

class PuzzleGameScreen extends StatefulWidget {
  final DateTime startTime;

  const PuzzleGameScreen({super.key, required this.startTime});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  static const _grid = 3;
  static const _count = _grid * _grid;

  final Random _random = Random();

  /// _tiles[position] = which piece of the picture sits there.
  late List<int> _tiles = _shuffled();

  /// Position of the first tapped tile, waiting for a second tap.
  int? _selected;

  bool get _solved {
    for (var i = 0; i < _count; i++) {
      if (_tiles[i] != i) return false;
    }
    return true;
  }

  List<int> _shuffled() {
    final tiles = List.generate(_count, (i) => i);
    do {
      tiles.shuffle(_random);
    } while (_inPlace(tiles) > 2); // Start with most pieces out of place.
    return tiles;
  }

  int _inPlace(List<int> tiles) {
    var n = 0;
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] == i) n++;
    }
    return n;
  }

  void _tap(int position) {
    if (_solved) return;
    setState(() {
      final first = _selected;
      if (first == null) {
        _selected = position;
      } else if (first == position) {
        _selected = null;
      } else {
        final piece = _tiles[first];
        _tiles[first] = _tiles[position];
        _tiles[position] = piece;
        _selected = null;
      }
    });
  }

  void _newPuzzle() {
    setState(() {
      _tiles = _shuffled();
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseLayout(
      title: 'Easy Puzzle',
      instruction:
          'Tap two pieces to swap them. Put the picture back together.',
      startTime: widget.startTime,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              min(constraints.maxWidth * 0.85, constraints.maxHeight - 70);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: size,
                child: _solved ? SunsetBloom(size: size) : _buildGrid(size),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              SizedBox(
                height: 40,
                child: _solved
                    ? TextButton.icon(
                        onPressed: _newPuzzle,
                        icon: const Icon(Icons.extension_outlined),
                        label: const Text('Beautiful. Play again'),
                      )
                    : Text(
                        '${_inPlace(_tiles)} of $_count pieces in place',
                        style: AppTextStyles.bodyMedium,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(double size) {
    const gap = 4.0;
    final tile = (size - gap * (_grid - 1)) / _grid;
    return Stack(
      children: [
        for (var pos = 0; pos < _count; pos++)
          AnimatedPositioned(
            // Keyed by piece so swapped tiles glide to their new spot.
            key: ValueKey(_tiles[pos]),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: (pos % _grid) * (tile + gap),
            top: (pos ~/ _grid) * (tile + gap),
            width: tile,
            height: tile,
            child: GestureDetector(
              onTap: () => _tap(pos),
              child: _Tile(
                piece: _tiles[pos],
                grid: _grid,
                pictureSize: size,
                tileSize: tile,
                gap: gap,
                selected: _selected == pos,
                correct: _tiles[pos] == pos,
              ),
            ),
          ),
      ],
    );
  }
}

/// One square of the picture: the full scene, shifted and clipped so only
/// this piece's part shows.
class _Tile extends StatelessWidget {
  final int piece;
  final int grid;
  final double pictureSize;
  final double tileSize;
  final double gap;
  final bool selected;
  final bool correct;

  const _Tile({
    required this.piece,
    required this.grid,
    required this.pictureSize,
    required this.tileSize,
    required this.gap,
    required this.selected,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final dx = (piece % grid) * (tileSize + gap);
    final dy = (piece ~/ grid) * (tileSize + gap);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primaryDeep : Colors.transparent,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned(
              left: -dx,
              top: -dy,
              width: pictureSize,
              height: pictureSize,
              child: _StillSunset(size: pictureSize),
            ),
            if (correct)
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The puzzle picture. Uses the finish-screen sunset so the user meets a
/// familiar, calm scene.
class _StillSunset extends StatelessWidget {
  final double size;

  const _StillSunset({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: SunsetBloom(size: size));
  }
}
