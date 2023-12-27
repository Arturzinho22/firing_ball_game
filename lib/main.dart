import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Animation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BallAnimationScreen(),
    );
  }
}

class BallAnimationScreen extends StatefulWidget {
  const BallAnimationScreen({super.key});

  @override
  BallAnimationScreenState createState() => BallAnimationScreenState();
}

class BallAnimationScreenState extends State<BallAnimationScreen> with TickerProviderStateMixin {
  double posX = 100.0;
  double posY = 100.0;
  final double ballSize = 50.0;
  Offset cursorPosition = const Offset(0, 0);
  List<FiringBall> firingBalls = [];
  Duration animationDuration = const Duration(milliseconds: 500); // Default duration
  AnimationController? animationController;
  Animation<Offset>? animation;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyPress);
    _multiTapGestureRecognizer.onTapDown = _handleMultiTapDown;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyPress);
    for (var ball in firingBalls) {
      ball.controller.dispose();
    }
    _multiTapGestureRecognizer.dispose();
    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyA) {
      final startPosition = Offset(posX + ballSize / 2, posY + ballSize / 2);
      final endPosition = cursorPosition;

      // Create new firing ball
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      final animation = Tween<Offset>(
        begin: startPosition,
        end: endPosition,
      ).animate(controller)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              firingBalls.removeWhere((ball) => ball.controller == controller);
            });
            controller.dispose();
          }
        });

      controller.forward();

      setState(() {
        firingBalls.add(FiringBall(controller: controller, animation: animation));
      });
    }
  }

  final MultiTapGestureRecognizer _multiTapGestureRecognizer = MultiTapGestureRecognizer();

  void _handleMultiTapDown(int pointer, TapDownDetails details) {
    _moveBall(details);
  }

  void _moveBall(TapDownDetails details) {
    // Getting the screen size
    final screenSize = MediaQuery.of(context).size;

    // Adjusting the position so the ball doesn't go off screen
    double newX = details.globalPosition.dx - ballSize / 2;
    double newY = details.globalPosition.dy - ballSize / 2;

    // Ensuring the ball stays within the screen bounds
    newX = newX.clamp(0, screenSize.width - ballSize);
    newY = newY.clamp(0, screenSize.height - ballSize);

    // Setting a consistent speed for the animation
    double speed = 1000.0; // You can adjust this value for different speeds
    int duration = speed.round();

    setState(() {
      posX = newX;
      posY = newY;
      animationDuration = Duration(milliseconds: duration); // Clamp duration to a reasonable range
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) => cursorPosition = event.position,
        child: RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            MultiTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
              () => _multiTapGestureRecognizer,
              (MultiTapGestureRecognizer instance) {
                instance.onTapDown = _handleMultiTapDown;
              },
            ),
          },
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  left: posX,
                  top: posY,
                  child: const Ball(),
                ),
                ...firingBalls.map((ball) => ball.build(context)).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FiringBall {
  final AnimationController controller;
  final Animation<Offset> animation;

  FiringBall({required this.controller, required this.animation});

  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          left: animation.value.dx - 10,
          top: animation.value.dy - 10,
          child: child!,
        );
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class Ball extends StatelessWidget {
  const Ball({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
